import 'package:automl/core/firebase_setup.dart';
import 'package:flutter/material.dart';
import 'package:automl/screens/auth/auth_wrapper.dart';
import 'package:automl/screens/auth/login_screen.dart';
import 'package:automl/screens/auth/signup_screen.dart';
import 'package:automl/screens/dashboard_screen.dart';
import 'package:automl/screens/job/job_creation/job_creation_screen.dart';
import 'package:automl/screens/job/results_screen.dart';
import 'package:automl/screens/job/training_progress_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoML App',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: AuthWrapper.routeName,
      routes: {
        AuthWrapper.routeName: (context) => const AuthWrapper(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        SignupScreen.routeName: (context) => const SignupScreen(),
        DashboardScreen.routeName: (context) => const DashboardScreen(),
        JobCreationScreen.routeName: (context) => const JobCreationScreen(),

        // --- THIS IS THE FIX: ADDED SAFE ARGUMENT HANDLING ---
        TrainingProgressScreen.routeName: (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is String) {
            return TrainingProgressScreen(taskId: args);
          }
          // Return a fallback error screen if arguments are missing/wrong
          return const Scaffold(body: Center(child: Text('Error: Task ID missing')));
        },
        ResultsScreen.routeName: (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is Map<String, dynamic>) {
            return ResultsScreen(resultsData: args);
          }
          // Return a fallback error screen
          return const Scaffold(body: Center(child: Text('Error: Results data missing')));
        },
      },
    );
  }
}

