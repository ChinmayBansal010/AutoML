import 'dart:async';
import 'package:automl/core/api_service.dart';
import 'package:automl/screens/job/results_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class TrainingProgressScreen extends StatefulWidget {
  static const routeName = '/training-progress';
  final String taskId;

  const TrainingProgressScreen({super.key, required this.taskId});

  @override
  State<TrainingProgressScreen> createState() => _TrainingProgressScreenState();
}

class _TrainingProgressScreenState extends State<TrainingProgressScreen> {
  final ApiService _apiService = ApiService();
  Timer? _pollingTimer;
  String _statusMessage = "Initializing training job...";
  Map<String, dynamic>? _finalResult;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final status = await _apiService.getTrainingStatus(widget.taskId, context);
      if (status != null && mounted) {
        setState(() {
          _statusMessage = status['progress'] ?? 'Processing...';
        });

        if (status['status'] == 'completed') {
          timer.cancel();
          setState(() => _finalResult = status);
          Navigator.of(context).pushReplacementNamed(
            ResultsScreen.routeName,
            arguments: _finalResult,
          );
        } else if (status['status'] == 'failed') {
          timer.cancel();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Training Failed: ${status['error']}'),
            backgroundColor: Colors.red,
          ));
          Navigator.of(context).pop(); // Go back to the previous screen
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
                'assets/animations/training.json', // Correct asset path
                width: 300,
                height: 300
            ),
            const SizedBox(height: 24),
            Text(
              'Training Models...',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

