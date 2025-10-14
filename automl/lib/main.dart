import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:automl/core/firebase_setup.dart';
import 'package:automl/screens/auth/auth_wrapper.dart';
import 'package:automl/screens/auth/login_screen.dart';
import 'package:automl/screens/auth/signup_screen.dart';
import 'package:automl/screens/job/dashboard_screen.dart';
import 'package:automl/screens/job/upload_screen.dart';
import 'package:automl/screens/job/jobs_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeFirebase();
  } on FirebaseException {
  }
  runApp(const AutoMLApp());
}

class AutoMLApp extends StatelessWidget {
  const AutoMLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoML Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        SignupScreen.routeName: (context) => const SignupScreen(),
        DashboardScreen.routeName: (context) => const DashboardScreen(),
        UploadScreen.routeName: (context) => const UploadScreen(),
        JobsListScreen.routeName: (context) => const JobsListScreen(),
      },
      home: const AuthWrapper(),
    );
  }
}
