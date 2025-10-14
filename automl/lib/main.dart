import 'package:flutter/material.dart';
import 'package:automl/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        DashboardScreen.routeName: (context) => const DashboardScreen(),
      },
      initialRoute: DashboardScreen.routeName,
    );
  }
}
