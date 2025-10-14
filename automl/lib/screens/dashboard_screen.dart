import 'package:flutter/material.dart';
import 'package:automl/core/firebase_setup.dart';

void showSnackbar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : Colors.blue.shade700,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

class DashboardScreen extends StatefulWidget {
  static const String routeName = '/dashboard';
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<String> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = initializeFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoML Project'),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: FutureBuilder<String>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final message = snapshot.data ?? "Initialization check complete.";
            final isError = snapshot.hasError || message.contains("error");

            WidgetsBinding.instance.addPostFrameCallback((_) {
              showSnackbar(context, message, isError: isError);
            });

            return _buildDashboardContent(context, message.contains("successfully"));
          } else {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 20),
                  Text("Connecting to Firebase...", style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, bool isConnected) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              isConnected ? Icons.check_circle_outline : Icons.error_outline,
              size: 80,
              color: isConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              isConnected ? 'Firebase Connected' : 'Connection Error',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'User ID: $currentUserId',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: isConnected ? () {
                // TODO: Implement file upload navigation
                showSnackbar(context, 'Navigating to File Upload...');
              } : null,
              icon: const Icon(Icons.cloud_upload),
              label: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text('Start New Job', style: TextStyle(fontSize: 16)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
