import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:automl/core/api_service.dart';
import 'package:automl/data/models/upload_summary.dart';
import 'package:automl/screens/job/dashboard_screen.dart';
import 'package:automl/data/models/job_models.dart';
import 'package:automl/screens/job/job_monitor_screen.dart'; // New Import
import 'dart:async';

class UploadScreen extends StatefulWidget {
  static const String routeName = '/upload';
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ApiService _apiService = ApiService();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1 State
  String? _filePath;
  String? _fileName;
  UploadSummary? _uploadSummary;

  // Step 2 State
  String? _selectedTargetColumn;
  final List<String> _availableModels = ['lightgbm', 'xgboost', 'random_forest', 'logistic_regression', 'catboost'];
  final List<String> _selectedModels = [];
  bool _hyperparameterTuning = true;

  @override
  void initState() {
    super.initState();
  }

  // --- Step 1 Handlers ---

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _filePath = result.files.single.path;
        _fileName = result.files.single.name;
        _uploadSummary = null;
      });
      await _uploadData();
    } else {
      showSnackbar(context, 'No file selected.', isError: true);
    }
  }

  Future<void> _uploadData() async {
    if (_filePath == null || _fileName == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final summary = await _apiService.uploadFile(_filePath!, _fileName!);
      setState(() {
        _uploadSummary = summary;
        // Auto-select a valid target if available, or reset selection
        if (summary.columns.isNotEmpty && summary.columns.contains(_selectedTargetColumn)) {
          // keep existing selection if valid
        } else if (summary.columns.isNotEmpty) {
          _selectedTargetColumn = summary.columns.last;
        } else {
          _selectedTargetColumn = null;
        }
      });
      showSnackbar(context, 'File uploaded successfully! Preview available.');
    } catch (e) {
      setState(() {
        _uploadSummary = null;
        _filePath = null;
        _fileName = null;
      });
      showSnackbar(context, 'Upload failed: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Step 3 Handler ---

  Future<void> _startTrainingJob() async {
    if (_uploadSummary == null || _selectedTargetColumn == null || _selectedModels.isEmpty) {
      showSnackbar(context, 'Please complete all configuration steps.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = TrainingRequest(
        fileId: _uploadSummary!.fileId,
        targetColumn: _selectedTargetColumn!,
        modelsToTrain: _selectedModels,
        hyperparameterTuning: _hyperparameterTuning,
      );

      final initialResponse = await _apiService.startTrainingJob(request);

      showSnackbar(context, 'Job ${initialResponse.taskId} started! Monitoring...', isError: false);

      // Navigate to the job monitor screen
      Navigator.of(context).pushReplacementNamed(
        JobMonitorScreen.routeName,
        arguments: initialResponse.taskId,
      );

    } catch (e) {
      showSnackbar(context, 'Training failed to start: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- UI Components for Steps ---

  Widget _buildStep1Upload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _pickFile,
          icon: const Icon(Icons.file_upload),
          label: Text(_fileName ?? 'Select CSV or Excel File'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: const Color(0xFF1E88E5), // Blue background
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Rounded corners
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: LinearProgressIndicator(color: Color(0xFF1E88E5)))
        else if (_uploadSummary != null)
          _DataPreviewCard(summary: _uploadSummary!),
        if (_uploadSummary == null && _fileName != null)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('File selected, but awaiting API upload/processing.', style: TextStyle(color: Colors.black54)),
          ),
      ],
    );
  }

  Widget _buildStep2Config() {
    final bool dataLoaded = _uploadSummary != null;
    final List<String> columns = dataLoaded ? _uploadSummary!.columns : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Target Column Selection
        const Text('Target Variable Selection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Target Column',
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            filled: true,
            fillColor: Colors.white,
          ),
          value: _selectedTargetColumn,
          hint: const Text('Select the column to predict'),
          items: columns.map((col) => DropdownMenuItem(value: col, child: Text(col))).toList(),
          onChanged: dataLoaded ? (newValue) {
            setState(() {
              _selectedTargetColumn = newValue;
            });
          } : null,
          validator: (value) => value == null ? 'Target column is required' : null,
        ),
        const SizedBox(height: 24),

        // Model Selection
        const Text('Model Selection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _availableModels.map((model) {
            final isSelected = _selectedModels.contains(model);
            return FilterChip(
              label: Text(model),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedModels.add(model);
                  } else {
                    _selectedModels.remove(model);
                  }
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: const Color(0xFF1E88E5),
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w500),
              showCheckmark: false,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            );
          }).toList(),
        ),
        if (_selectedModels.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Please select at least one model.', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
          ),
        const SizedBox(height: 24),

        // Hyperparameter Tuning Toggle
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: SwitchListTile(
            title: const Text('Hyperparameter Tuning', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            subtitle: const Text('Automatically optimize model parameters.'),
            value: _hyperparameterTuning,
            onChanged: (value) {
              setState(() {
                _hyperparameterTuning = value;
              });
            },
            activeColor: const Color(0xFF1E88E5),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Review() {
    final bool allValid = _uploadSummary != null && _selectedTargetColumn != null && _selectedModels.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Final Configuration Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _ReviewItem(title: 'File:', value: _fileName ?? 'Not uploaded'),
                _ReviewItem(title: 'Target:', value: _selectedTargetColumn ?? 'Not selected'),
                _ReviewItem(title: 'Models:', value: _selectedModels.isEmpty ? 'None selected' : _selectedModels.join(', ')),
                _ReviewItem(title: 'Tuning:', value: _hyperparameterTuning ? 'Enabled' : 'Disabled', isBold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),

        ElevatedButton(
          onPressed: allValid && !_isLoading ? _startTrainingJob : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Start Training', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  // --- Main Stepper UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Training Job'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: const Color(0xFF1E88E5), // Active step color
            onSurface: Colors.black54, // Inactive step text color
          ),
          canvasColor: Colors.transparent,
          shadowColor: Colors.transparent, // Remove default stepper background shadow
        ),
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          elevation: 0,
          onStepContinue: () {
            final isLastStep = _currentStep == 2;
            if (isLastStep) {
              _startTrainingJob();
            } else if (_currentStep == 0 && _uploadSummary == null) {
              showSnackbar(context, 'Please upload and process a file first.', isError: true);
            } else if (_currentStep == 1 && (_selectedTargetColumn == null || _selectedModels.isEmpty)) {
              showSnackbar(context, 'Please select a Target Column and at least one Model.', isError: true);
            } else {
              setState(() {
                _currentStep += 1;
              });
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            }
          },
          controlsBuilder: (context, details) {
            final isLastStep = _currentStep == 2;
            final bool canProceed = (_currentStep == 0 && _uploadSummary != null) ||
                (_currentStep == 1 && _selectedTargetColumn != null && _selectedModels.isNotEmpty) ||
                (_currentStep == 2);

            return Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: canProceed && !_isLoading ? details.onStepContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(isLastStep ? 'FINISH & START' : 'NEXT'),
                  ),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('BACK', style: TextStyle(color: Colors.black54)),
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('1. Upload Data'),
              content: _buildStep1Upload(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('2. Configure Training'),
              content: _buildStep2Config(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('3. Review and Run'),
              content: _buildStep3Review(),
              isActive: _currentStep >= 2,
              state: _currentStep >= 2 ? StepState.complete : StepState.indexed,
            ),
          ],
        ),
      ),
    );
  }
}

class _DataPreviewCard extends StatelessWidget {
  final UploadSummary summary;

  const _DataPreviewCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final columns = summary.columns;
    final sampleData = summary.sampleData;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Preview (${summary.filename})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5)),
            ),
            const Divider(),
            Text('Rows: ${summary.rowCount} | Columns: ${summary.columns.length}', style: const TextStyle(color: Colors.black54)),
            Text('File ID: ${summary.fileId}', style: TextStyle(fontSize: 12, color: Colors.black45)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 18,
                  horizontalMargin: 4,
                  headingRowColor: MaterialStateProperty.resolveWith((states) => Colors.blueGrey.shade50),
                  columns: columns
                      .map((col) => DataColumn(
                    label: SizedBox(
                      width: 80,
                      child: Text(
                        col,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ))
                      .toList(),
                  rows: sampleData
                      .map((row) => DataRow(
                    cells: columns
                        .map((col) => DataCell(
                      Text(
                        row[col]?.toString() ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ))
                        .toList(),
                  ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String title;
  final String value;
  final bool isBold;

  const _ReviewItem({required this.title, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF1E88E5)),
            ),
          ),
        ],
      ),
    );
  }
}
