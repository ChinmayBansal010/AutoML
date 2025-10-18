import 'package:automl/core/api_service.dart';
import 'package:automl/screens/job/job_creation/step1_upload_data.dart';
import 'package:automl/screens/job/job_creation/step2_data_preview.dart';
import 'package:automl/screens/job/job_creation/step3_data_visualization.dart';
import 'package:automl/screens/job/job_creation/step4_model_selection.dart';
import 'package:automl/screens/job/training_progress_screen.dart';
import 'package:automl/widgets/common_app_bar.dart';
import 'package:automl/widgets/job_stepper.dart';
import 'package:flutter/material.dart';

class JobCreationScreen extends StatefulWidget {
  static const routeName = '/create-job';
  const JobCreationScreen({super.key});

  @override
  State<JobCreationScreen> createState() => _JobCreationScreenState();
}

class _JobCreationScreenState extends State<JobCreationScreen> {
  final ApiService _apiService = ApiService();
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  String? _uploadedFileId;
  String? _targetColumn;
  Set<String> _selectedModels = {};

  final List<StepData> _steps = const [
    StepData(icon: Icons.cloud_upload_outlined, activeGradientStart: Color(0xFF8730FB), activeGradientEnd: Color(0xFF3859FC)),
    StepData(icon: Icons.table_chart_outlined, activeGradientStart: Color(0xFF3859FC), activeGradientEnd: Color(0xFF25D3FC)),
    StepData(icon: Icons.bar_chart_rounded, activeGradientStart: Color(0xFF25D3FC), activeGradientEnd: Color(0xFF25FC7D)),
    StepData(icon: Icons.model_training_outlined, activeGradientStart: Color(0xFF25FC7D), activeGradientEnd: Color(0xFFFCEC25)),
  ];

  void _onUploadComplete(String fileId) {
    setState(() {
      _uploadedFileId = fileId;
      _currentPageIndex = 1;
    });
    _pageController.animateToPage(_currentPageIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _onPreviewComplete() {
    setState(() => _currentPageIndex = 2);
    _pageController.animateToPage(_currentPageIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _onVisualizationComplete(String targetColumn) {
    setState(() {
      _targetColumn = targetColumn;
      _currentPageIndex = 3;
    });
    _pageController.animateToPage(_currentPageIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _startTraining() async {
    if (_uploadedFileId == null || _targetColumn == null || _selectedModels.isEmpty) return;

    final result = await _apiService.startTrainingJob(
      _uploadedFileId!,
      _targetColumn!,
      _selectedModels,
      context,
    );

    if (result != null && result.containsKey('task_id') && mounted) {
      Navigator.of(context).pushReplacementNamed(
        TrainingProgressScreen.routeName,
        arguments: result['task_id'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
            icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: const [SizedBox(width: 48)],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  child: JobStepper(steps: _steps, currentIndex: _currentPageIndex, lineColor: isDarkMode ? Colors.white24 : Colors.grey.shade400),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      UploadDataStep(onContinue: _onUploadComplete),
                      if (_uploadedFileId != null) DataPreviewStep(fileId: _uploadedFileId!, onContinue: _onPreviewComplete),
                      if (_uploadedFileId != null) DataVisualizationStep(fileId: _uploadedFileId!, onContinue: _onVisualizationComplete),
                      if (_uploadedFileId != null && _targetColumn != null)
                        ModelSelectionStep(onSelectionChanged: (models) => setState(() => _selectedModels = models)),
                    ],
                  ),
                ),
                if (_currentPageIndex == 3)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedModels.isNotEmpty ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: _selectedModels.isNotEmpty ? _startTraining : null,
                      child: const Text('Start Training', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

