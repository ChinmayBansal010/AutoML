import 'package:automl/screens/job/job_creation/step1_upload_data.dart';
import 'package:automl/screens/job/job_creation/step2_data_preview.dart';
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
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  String? _uploadedFileId;

  final List<StepData> _steps = const [
    StepData(icon: Icons.cloud_upload_outlined, activeGradientStart: Color(0xFF8730FB), activeGradientEnd: Color(0xFF3859FC)),
    StepData(icon: Icons.table_chart, activeGradientStart: Color(0xFF3859FC), activeGradientEnd: Color(0xFF25D3FC)),
  ];

  void _onUploadComplete(String fileId) {
    setState(() {
      _uploadedFileId = fileId;
      _currentPageIndex++;
    });
    _pageController.animateToPage(_currentPageIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _submitJob() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode ? [const Color(0xFF0D1B2A), const Color(0xFF3A0655)] : [const Color(0xFFFFF1F4), const Color(0xFFFFF9F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
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
                      if (_uploadedFileId != null)
                        DataPreviewStep(fileId: _uploadedFileId!, onContinue: _submitJob)
                      else
                        const Center(child: Text("Waiting for file upload...")),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}