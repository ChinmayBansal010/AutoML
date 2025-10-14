import 'package:flutter/material.dart';
import 'package:automl/core/api_service.dart';
import 'package:automl/data/models/job_models.dart';
import 'package:automl/screens/job/dashboard_screen.dart';
import 'dart:async';

class JobMonitorScreen extends StatefulWidget {
  static const String routeName = '/job_monitor';
  final String taskId;

  const JobMonitorScreen({super.key, required this.taskId});

  @override
  State<JobMonitorScreen> createState() => _JobMonitorScreenState();
}

class _JobMonitorScreenState extends State<JobMonitorScreen> {
  final ApiService _apiService = ApiService();
  StatusResponse? _currentStatus;
  Timer? _timer;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Poll immediately
    _fetchStatus();

    // Set up timer for polling every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isFinished) {
        _fetchStatus();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _fetchStatus() async {
    try {
      final status = await _apiService.getJobStatus(widget.taskId);
      if (mounted) {
        setState(() {
          _currentStatus = status;
          if (status.status == 'complete' || status.status == 'failed') {
            _isFinished = true;
            _timer?.cancel();
            showSnackbar(context, 'Job ${status.status.toUpperCase()}!', isError: status.status == 'failed');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        showSnackbar(context, 'Error fetching status: ${e.toString()}', isError: true);
        setState(() {
          _isFinished = true;
          _timer?.cancel();
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'complete':
        return Colors.green;
      case 'running':
        return Colors.blueAccent;
      case 'failed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildResultView() {
    if (_currentStatus == null || _currentStatus!.status == 'starting' || _currentStatus!.status == 'running') {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)));
    }

    if (_currentStatus!.status == 'failed') {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Training Failed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            Text(_currentStatus!.progress, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: const Text('Back to Dashboard'),
            )
          ],
        ),
      );
    }

    // --- Complete Status: Show Metrics Summary ---
    final result = _currentStatus!.result?['final_metrics'];
    final plots = _currentStatus!.result?['plots'];

    if (result == null) {
      return const Center(child: Text('Job complete, but no result data found.', style: TextStyle(color: Colors.red)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Training Complete!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
          const Divider(),
          _MetricCard(
            title: 'Model: ${result['model_name']}',
            metrics: {
              'Accuracy': result['accuracy']?.toStringAsFixed(4) ?? 'N/A',
              'F1 Score (Weighted)': result['f1_score']?.toStringAsFixed(4) ?? 'N/A',
              'Precision (Weighted)': result['precision']?.toStringAsFixed(4) ?? 'N/A',
              'Recall (Weighted)': result['recall']?.toStringAsFixed(4) ?? 'N/A',
            },
            color: Colors.green.shade50,
          ),
          const SizedBox(height: 16),
          // TODO: Implement Detailed Report View (Confusion Matrix, SHAP)
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Detailed Report Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Confusion Matrix Data Loaded: ${plots?['confusion_matrix'] != null}', style: const TextStyle(color: Colors.black54)),
                  Text('SHAP Summary Data Loaded: ${plots?['shap_summary'] != null}', style: const TextStyle(color: Colors.black54)),
                  const Text('Full visualization will be added here.', style: TextStyle(color: Colors.orange)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _currentStatus;

    return PopScope(
      canPop: _isFinished,
      onPopInvoked: (didPop) {
        if (!didPop && !_isFinished) {
          showSnackbar(context, 'Please wait for the job to finish.', isError: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Job Monitoring'),
          backgroundColor: Colors.blueAccent,
          automaticallyImplyLeading: _isFinished, // Allow back only when finished
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text('Task ID: ${widget.taskId}', style: const TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  CircleAvatar(
                    radius: 6,
                    backgroundColor: _getStatusColor(status?.status ?? 'pending'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status?.status.toUpperCase() ?? 'PENDING',
                    style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(status?.status ?? 'pending')),
                  ),
                ],
              ),
            ),
            if (status != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  status.progress,
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
            const Divider(),
            Expanded(
              child: _buildResultView(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final Map<String, String> metrics;
  final Color color;

  const _MetricCard({required this.title, required this.metrics, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            ...metrics.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: const TextStyle(color: Colors.black87)),
                  Text(entry.value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
