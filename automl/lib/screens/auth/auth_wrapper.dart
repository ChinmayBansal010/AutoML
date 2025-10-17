import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:automl/core/firebase_setup.dart';
import 'package:automl/screens/auth/login_screen.dart';
import 'package:automl/screens/dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  static const String routeName = '/auth-wrapper';
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const DashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}