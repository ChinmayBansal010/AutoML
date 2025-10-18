import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:automl/core/api_service.dart'; // Make sure this import is correct

class UploadDataStep extends StatefulWidget {
  final Function(String) onContinue;

  const UploadDataStep({super.key, required this.onContinue});

  @override
  State<UploadDataStep> createState() => _UploadDataStepState();
}

class _UploadDataStepState extends State<UploadDataStep> {
  final ApiService _apiService = ApiService();
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  // This function now handles the API call and triggers the page change
  Future<void> _uploadAndContinue() async {
    if (_selectedFile == null) return;

    setState(() { _isUploading = true; });

    final result = await _apiService.uploadFile(_selectedFile!, context);

    if (mounted) {
      setState(() { _isUploading = false; });
      if (result != null && result['file_id'] != null) {
        widget.onContinue(result['file_id']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        children: [
          Text(
            'Upload Your Dataset',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a CSV file to get started with AutoML',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade900.withValues(alpha: 0.5) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isDarkMode ? Colors.white38 : Colors.grey.shade400,
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6A11CB).withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Drag and drop your CSV file here',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'or',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _pickFile,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                      shadowColor: Colors.black.withValues(alpha: 0.4),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2645E5), Color(0xFF7D0BDB)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                        alignment: Alignment.center,
                        child: const Text(
                          'Browse Files',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Selected: ${_selectedFile!.name}',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Maximum file size: 10MB',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Logic for showing loading indicator or button
          if (_isUploading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
              ),
              // The onPressed now correctly calls the upload function
              onPressed: _selectedFile != null ? _uploadAndContinue : null,
              child: const Text('Continue', style: TextStyle(fontSize: 18)),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}