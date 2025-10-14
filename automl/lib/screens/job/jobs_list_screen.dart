import 'package:flutter/material.dart';

class JobsListScreen extends StatelessWidget {
  static const String routeName = '/jobs_list';
  const JobsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previous Training Jobs'),
        backgroundColor: Colors.blueAccent,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.blueGrey),
            SizedBox(height: 20),
            Text(
              'Job history will be displayed here.',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
