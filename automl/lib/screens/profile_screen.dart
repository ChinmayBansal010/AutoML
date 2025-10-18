import 'package:automl/core/firebase_setup.dart';
import 'package:automl/utils/snackbar_helper.dart';
import 'package:automl/widgets/common_app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:automl/core/api_service.dart'; // Import ApiService

// Assuming UserProfile model exists in lib/data/models/user_profile.dart
class UserProfile {
  final String email;
  final String displayName;
  final DateTime? dob;
  final String? apiKey;
  final bool isVerified; // Verification field

  UserProfile({
    required this.email,
    required this.displayName,
    this.dob,
    this.apiKey,
    this.isVerified = false,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    // FIX: Safely retrieve the apiKey using both possible casings for backward compatibility
    final key = data['apiKey'] ?? data['apikey'] ?? '';

    return UserProfile(
      email: data['email'] ?? 'N/A',
      displayName: data['displayName'] ?? '',
      dob: (data['dob'] as Timestamp?)?.toDate(),
      apiKey: key,
      isVerified: data['isVerified'] ?? false, // Load verification status
    );
  }
}

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _apiKeyController = TextEditingController(); // Controller for API Key
  DateTime? _selectedDate;
  String? _userId;
  bool _isSaving = false; // State for saving/verification indicator
  bool _isPasswordVisible = false; // State for toggling API key visibility

  // The actual verification status of the key loaded from Firestore
  bool _currentKeyIsVerified = false;
  final ApiService _apiService = ApiService();

  // NEW: Flag to track if initial data has been loaded into the controllers
  bool _isInitialDataLoaded = false;

  // Storage for the profile object retrieved from Firestore stream
  UserProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _userId = auth.currentUser?.uid;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.white,
              surface: const Color(0xFF1E2939),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).primaryColor),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _loadUserData(UserProfile profile) {
    // Store the latest profile data
    _currentProfile = profile;

    // Only load data into controllers and date fields if it hasn't been done before
    if (!_isInitialDataLoaded) {
      _nameController.text = profile.displayName;
      _selectedDate = profile.dob;
      _isInitialDataLoaded = true;
    }

    // Always update verification status to reflect current state from Firestore.
    _currentKeyIsVerified = profile.isVerified;

    // The _apiKeyController is intentionally NOT set here for security.
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    final userId = _userId;
    final currentProfile = _currentProfile;
    if (userId == null || currentProfile == null) {
      showCustomSnackbar(context, 'Authentication error or profile data missing.', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final newName = _nameController.text.trim();
    final newApiKey = _apiKeyController.text.trim();
    bool keyVerificationStatus = currentProfile.isVerified; // Start with the existing verification status

    // 1. Save Name and DOB
    final profileError = await updateUserProfile(
      userId,
      displayName: newName,
      dob: _selectedDate,
    );

    // 2. Handle API Key saving and verification
    String? apiKeyError;

    if (newApiKey.isNotEmpty) {
      // CASE 1: User entered a NEW key. We MUST verify and save/update.

      final isVerified = await _apiService.verifyApiKey(newApiKey, context);

      // Update verification status in Firestore based on the verification result
      await updateApiKeyVerification(userId, isVerified);
      keyVerificationStatus = isVerified; // Update local state for feedback/badge

      if (isVerified) {
        // Only save the key itself if verification succeeds
        apiKeyError = await updateApiKey(userId, newApiKey);
      }
      // If verification fails, the old key remains in Firestore.

    } else if (newApiKey.isEmpty && currentProfile.apiKey != null && currentProfile.apiKey!.isNotEmpty) {
      // CASE 2: Key field is empty, but the profile HAD a key.

      // CRITICAL FIX: If the key was already verified, we do nothing with the key fields.
      // This prevents the key from being unintentionally cleared when updating DOB/Name.
      if (currentProfile.isVerified) {
        // Do nothing. Preserve the existing key and verified status.
        keyVerificationStatus = currentProfile.isVerified;
      } else {
        // The key existed but was unverified. The user left the field empty,
        // implying they want to clear it (or don't have a correct one).
        apiKeyError = await updateApiKey(userId, '');
        await updateApiKeyVerification(userId, false);
        keyVerificationStatus = false;
      }
    }
    // CASE 3: Key field is empty and no key ever existed (or was already cleared). Do nothing.

    // 3. Final feedback
    setState(() {
      _isSaving = false;
      _currentKeyIsVerified = keyVerificationStatus;
      // Clear the text controller completely for security
      _apiKeyController.clear();
    });

    if (profileError == null && apiKeyError == null) {
      showCustomSnackbar(context, 'Profile updated successfully!');
    } else {
      showCustomSnackbar(context, 'Failed to update profile: ${profileError ?? apiKeyError}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF0D1B2A), const Color(0xFF3A0665)]
              : [const Color(0xFFFFF1F4), const Color(0xFFFFF9F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CommonAppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: _isSaving
                  ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded, size: 28),
              onPressed: _isSaving ? null : _saveProfile,
              tooltip: 'Save Profile',
            ),
          ],
        ),
        body: _userId == null
            ? const Center(child: Text('User not logged in.'))
            : StreamBuilder<DocumentSnapshot>(
          stream: fetchUserProfileStream(_userId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.data() == null) {
              return const Center(child: Text('Could not load profile data.'));
            }

            final profile = UserProfile.fromFirestore(snapshot.data!.data() as Map<String, dynamic>);
            // CRITICAL: Call _loadUserData here to set controllers only once
            _loadUserData(profile);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Icon/Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: primaryColor.withOpacity(0.2),
                    child: Text(
                      profile.email.isNotEmpty ? profile.email[0].toUpperCase() : 'A',
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.email,
                    style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(height: 40),

                  // Profile Edit Card
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E2939) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                        const SizedBox(height: 24),

                        // Display Name Field
                        _buildLabel('Display Name'),
                        _buildTextField(_nameController, 'Enter your display name', Icons.person),
                        const SizedBox(height: 20),

                        // Date of Birth Field
                        _buildLabel('Date of Birth'),
                        _buildDatePicker(context, isDarkMode, primaryColor),
                        const SizedBox(height: 30),

                        // API Key Field
                        _buildLabel('API Key (for AutoML Server)'),
                        _buildApiKeyField(_apiKeyController, 'Enter X-API-KEY', Icons.vpn_key_rounded, profile.isVerified),
                        const SizedBox(height: 10),
                        Text(
                          profile.isVerified ? 'Key verified. You are ready to run jobs.' : 'Key is unverified or missing. Please enter and save to verify.',
                          style: TextStyle(fontSize: 12, color: profile.isVerified ? Colors.green.shade400 : Colors.red.shade400),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.blueAccent,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54),
        border: InputBorder.none,
        filled: true,
        fillColor: const Color(0xFF111828),
        prefixIcon: Icon(icon, color: Colors.white54),
        contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildApiKeyField(TextEditingController controller, String hintText, IconData icon, bool isVerified) {
    return TextField(
      controller: controller,
      obscureText: !_isPasswordVisible, // Dynamic obscurity
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.blueAccent,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54),
        border: InputBorder.none,
        filled: true,
        fillColor: const Color(0xFF111828),
        prefixIcon: Icon(icon, color: Colors.white54),
        suffixIcon: Row( // Combined suffix icons
          mainAxisSize: MainAxisSize.min,
          children: [
            // Verification Badge
            Tooltip(
              message: isVerified ? 'Key Verified' : 'Key Unverified',
              child: Icon(
                isVerified ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: isVerified ? Colors.green.shade400 : Colors.red.shade400,
                size: 24,
              ),
            ),
            // Show/Hide Password Toggle
            IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.white54,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, bool isDarkMode, Color primaryColor) {
    return InkWell(
      onTap: _isSaving ? null : () => _selectDate(context),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          color: const Color(0xFF111828),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: Colors.white54),
            const SizedBox(width: 12),
            Text(
              _selectedDate == null
                  ? 'Select Date of Birth (Optional)'
                  : DateFormat('MMMM d, yyyy').format(_selectedDate!),
              style: TextStyle(
                color: _selectedDate == null ? Colors.white54 : Colors.white,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Icon(Icons.edit, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }
}
