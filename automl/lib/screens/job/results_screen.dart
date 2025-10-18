import 'package:automl/core/api_service.dart';
import 'package:automl/core/firebase_setup.dart';
import 'package:automl/utils/snackbar_helper.dart';
import 'package:automl/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResultsScreen extends StatefulWidget {
  static const routeName = '/results';
  final Map<String, dynamic> resultsData;

  const ResultsScreen({super.key, required this.resultsData});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late final Map<String, dynamic> _results;
  late final List<MapEntry<String, dynamic>> _rankedModels;
  MapEntry<String, dynamic>? _bestModel;

  // Define a consistent color palette for metrics
  final Map<String, Color> _metricColors = {
    'accuracy': Colors.blue.shade400,
    'precision': Colors.green.shade400,
    'recall': Colors.orange.shade400,
    'f1_score': Colors.purple.shade400,
  };

  @override
  void initState() {
    super.initState();
    _results = widget.resultsData['results'] as Map<String, dynamic>? ?? {};

    if (_results.isNotEmpty) {
      _rankedModels = _results.entries.toList()
        ..sort((a, b) {
          final accuracyA = (a.value['metrics']?['overall_metrics']?['accuracy'] as num?)?.toDouble() ?? 0.0;
          final accuracyB = (b.value['metrics']?['overall_metrics']?['accuracy'] as num?)?.toDouble() ?? 0.0;
          return accuracyB.compareTo(accuracyA);
        });
      _bestModel = _rankedModels.first;
      _saveResultsToFirebase();
    } else {
      _rankedModels = [];
      _bestModel = null;
    }
  }

  Map<String, dynamic> _sanitizeDataForFirestore(Map<String, dynamic> data) {
    final sanitizedMap = <String, dynamic>{};

    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        // If the value is a map, sanitize it recursively.
        sanitizedMap[key] = _sanitizeDataForFirestore(value);
      } else if (value is List && value.isNotEmpty && value.first is List) {
        // This is the nested list we need to fix.
        final Map<String, dynamic> listAsMap = {};
        for (int i = 0; i < value.length; i++) {
          listAsMap['row_$i'] = value[i];
        }
        sanitizedMap[key] = listAsMap;
      } else {
        // The value is fine, so we keep it as is.
        sanitizedMap[key] = value;
      }
    });

    return sanitizedMap;
  }

  Future<void> _saveResultsToFirebase() async {
    final taskId = widget.resultsData['task_id'] as String?;
    final user = auth.currentUser;

    if (taskId == null || user == null) {
      showCustomSnackbar(context,"Error: Task ID or User is null. Cannot save to Firebase.");
      return;
    }

    // Sanitize the entire data map before saving.
    final Map<String, dynamic> dataToSave = _sanitizeDataForFirestore(widget.resultsData);

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    final summaryRef = firestore
        .collection('users')
        .doc(user.uid)
        .collection('dashboard')
        .doc('summary');

    batch.set(
      summaryRef,
      {
        'totalJobs': FieldValue.increment(1),
        'totalModelsTrained': FieldValue.increment(_rankedModels.length),
      },
      SetOptions(merge: true),
    );

    final jobRef = firestore
        .collection('users')
        .doc(user.uid)
        .collection('jobs')
        .doc(taskId);

    // Save the clean, sanitized data.
    batch.set(jobRef, {
      'taskId': taskId,
      'status': 'Completed',
      'timestamp': FieldValue.serverTimestamp(),
      'resultsData': dataToSave,
    });

    try {
      await batch.commit();
      showCustomSnackbar(context,"Successfully saved results for task $taskId for user ${user.uid}.");
    } catch (e) {
      showCustomSnackbar(context,"Error saving results to Firebase: $e");
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
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: const [SizedBox(width: 48)],
        ),
        body: _results.isEmpty
            ? const Center(child: Text('No models were trained successfully.'))
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_bestModel != null)
                _buildBestModelCard(_bestModel!.key, _bestModel!.value, isDarkMode),
              const SizedBox(height: 32),
              _buildSectionHeader('Model Comparison', Icons.bar_chart_rounded), // New section header
              const SizedBox(height: 16),
              _buildModelComparisonCard(_rankedModels), // New comparison card
              const SizedBox(height: 32),
              _buildSectionHeader('Model Leaderboard', Icons.leaderboard_rounded),
              const SizedBox(height: 16),
              _buildLeaderboard(_rankedModels),
              const SizedBox(height: 32),
              _buildSectionHeader('Confusion Matrices', Icons.grid_view_rounded),
              const SizedBox(height: 16),
              _buildConfusionMatrices(_rankedModels),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBestModelCard(String modelName, dynamic modelData, bool isDarkMode) {
    final metrics = modelData['metrics']?['overall_metrics'] ?? {};
    final accuracy = (metrics['accuracy'] as num?)?.toDouble() ?? 0.0;
    final precision = (metrics['precision'] as num?)?.toDouble() ?? 0.0;
    final recall = (metrics['recall'] as num?)?.toDouble() ?? 0.0;

    return Card(
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)]
                : [const Color(0xFF56CCF2), const Color(0xFF2F80ED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.military_tech_outlined, color: Colors.amberAccent, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Best Performing Model', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        Text(modelName.toUpperCase().replaceAll('_', ' '), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricPill('Accuracy', '${(accuracy * 100).toStringAsFixed(1)}%'),
                  _buildMetricPill('Precision', precision.toStringAsFixed(2)),
                  _buildMetricPill('Recall', recall.toStringAsFixed(2)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricPill(String name, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildModelComparisonCard(List<MapEntry<String, dynamic>> rankedModels) {
    if (rankedModels.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text("No models available for comparison.")),
        ),
      );
    }

    // final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    double maxY = 0;
    for (var modelEntry in rankedModels) {
      final metrics = modelEntry.value['metrics']?['overall_metrics'] ?? {};
      maxY = max(maxY, (metrics['accuracy'] as num?)?.toDouble() ?? 0.0);
      maxY = max(maxY, (metrics['precision'] as num?)?.toDouble() ?? 0.0);
      maxY = max(maxY, (metrics['recall'] as num?)?.toDouble() ?? 0.0);
      maxY = max(maxY, (metrics['f1_score'] as num?)?.toDouble() ?? 0.0);
    }
    maxY = min(1.0, maxY * 1.15);
    if (maxY == 0) maxY = 1.0;
    final double barWidth = 14;
    final double barSpace = 4;
    final double groupSpace = 16;
    final int metricsCount = _metricColors.length;

    final double totalWidthPerModel = (metricsCount * barWidth) + ((metricsCount - 1) * barSpace);
    final double chartContentWidth = rankedModels.length * totalWidthPerModel + (rankedModels.length - 1) * groupSpace;

    final double minChartWidth = MediaQuery.of(context).size.width - 40;
    final double actualChartWidth = max(minChartWidth, chartContentWidth);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: actualChartWidth,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          tooltipMargin: 10,
                          tooltipBorder: BorderSide(color: Colors.grey.shade700, width: 1),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final modelName = rankedModels[group.x].key;
                            String metricName = _metricColors.keys.elementAt(rodIndex);
                            return BarTooltipItem(
                              '$modelName\n',
                              TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              children: <TextSpan>[
                                TextSpan(
                                  text: '${metricName.capitalizeFirst}: ${(rod.toY * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: _metricColors[metricName] ?? Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < rankedModels.length) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 8,
                                  child: Text(
                                    rankedModels[index].key.replaceAll('Classifier', '').trim(),
                                    style: const TextStyle(fontSize: 10),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                            reservedSize: 30,
                            interval: 1,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1)),
                            interval: (maxY / 4).clamp(0.1, 1.0),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 0.2,
                        checkToShowHorizontalLine: (value) => value % 0.2 == 0,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                          strokeWidth: 0.8,
                        ),
                      ),
                      barGroups: rankedModels.asMap().entries.map((entry) {
                        int modelIndex = entry.key;
                        final metrics = entry.value.value['metrics']?['overall_metrics'] ?? {};

                        return BarChartGroupData(
                          x: modelIndex,
                          barRods: _metricColors.entries.map((metricEntry) {
                            return BarChartRodData(
                              toY: (metrics[metricEntry.key] as num?)?.toDouble() ?? 0.0,
                              color: metricEntry.value,
                              width: barWidth,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(3),
                                topRight: Radius.circular(3),
                              ),
                            );
                          }).toList(),
                          barsSpace: barSpace,
                        );
                      }).toList(),
                      groupsSpace: groupSpace,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricLegend() {
    return Wrap(
      spacing: 16.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: _metricColors.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 16, height: 16, color: entry.value),
            const SizedBox(width: 8),
            Text(entry.key.replaceAll('_', ' ').capitalizeFirst), // "f1_score" -> "F1 score"
          ],
        );
      }).toList(),
    );
  }


  Widget _buildLeaderboard(List<MapEntry<String, dynamic>> rankedModels) {
    final ApiService apiService = ApiService();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rankedModels.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = rankedModels[index];
        final modelData = entry.value;
        final metrics = modelData['metrics']?['overall_metrics'] ?? {};
        final accuracy = (metrics['accuracy'] as num?)?.toDouble() ?? 0.0;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: _buildRankBadge(index + 1),
            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Accuracy: ${(accuracy * 100).toStringAsFixed(2)}%'),
            trailing: OutlinedButton.icon(
              icon: const Icon(Icons.download_for_offline_outlined, size: 18),
              label: const Text('Model'),
              onPressed: () => apiService.downloadModel(modelData['model_id']),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color;
    Color textColor = Colors.white;
    switch (rank) {
      case 1: color = Colors.amber.shade600; break;
      case 2: color = Colors.grey.shade500; break;
      case 3: color = Colors.brown.shade400; break;
      default: color = Colors.blueGrey.shade300;
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: color,
      child: Text(rank.toString(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildConfusionMatrices(List<MapEntry<String, dynamic>> rankedModels) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rankedModels.length,
      itemBuilder: (context, index) {
        final model = rankedModels[index];
        final plots = model.value['plots'];
        if (plots == null || plots['confusion_matrix'] == null) {
          return const SizedBox.shrink();
        }
        final matrixData = plots['confusion_matrix'];
        final labels = List<dynamic>.from(matrixData['labels']);

        List<List<int>> matrix;
        final dynamic rawMatrix = matrixData['matrix'];

        if (rawMatrix is Map) {
          final sortedEntries = rawMatrix.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));
          matrix = sortedEntries
              .map((entry) => List<int>.from(entry.value))
              .toList();
        } else if (rawMatrix is List) {
          matrix = List<List<int>>.from(
              rawMatrix.map((row) => List<int>.from(row)));
        } else {
          matrix = [];
        }

        if (matrix.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20,horizontal: 50.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(model.key.toUpperCase().replaceAll('_', ' '), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Center(child: _ConfusionMatrixWidget(matrix: matrix, labels: labels)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String get capitalizeFirst {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class _ConfusionMatrixWidget extends StatelessWidget {
  final List<List<int>> matrix;
  final List<dynamic> labels;
  const _ConfusionMatrixWidget({required this.matrix, required this.labels});

  Color _getTextColorForBackground(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final int maxVal = matrix.expand((row) => row).isNotEmpty ? matrix.expand((row) => row).reduce(max) : 1;

    // --- Style constants for easy tweaking ---
    const double cellSize = 80.0;
    const double sideLabelWidth = 20.0;
    const double headerLabelHeight = 50.0;

    final correctColor = isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600;
    final incorrectColor = isDarkMode ? Colors.red.shade300 : Colors.red.shade500;
    final correctColorStart = isDarkMode ? Colors.blue.shade900 : Colors.blue.shade100;
    final incorrectColorStart = isDarkMode ? Colors.red.shade900 : Colors.red.shade100;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: sideLabelWidth,
          child: const Center(
            child: RotatedBox(
              quarterTurns: -1,
              child: Text(
                'Actual Class',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              const Text(
                'Predicted Class',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    // Top Header Row (Predicted Labels)
                    Row(
                      children: [
                        SizedBox(width: cellSize), // Spacer for side labels
                        ...labels.map((l) => SizedBox(
                          width: cellSize,
                          height: headerLabelHeight,
                          child: Center(
                            child: Text(
                              l.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )),
                      ],
                    ),
                    // Matrix Rows
                    ...matrix.asMap().entries.map((entry) {
                      int rowIndex = entry.key;
                      List<int> row = entry.value;
                      return Row(
                        children: [
                          // Side Header (Actual Labels)
                          SizedBox(
                            width: cellSize,
                            height: cellSize,
                            child: Center(
                              child: Text(
                                labels[rowIndex].toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          // Heatmap Cells
                          ...row.asMap().entries.map((cellEntry) {
                            int cellValue = cellEntry.value;
                            bool isDiagonal = rowIndex == cellEntry.key;

                            double t = maxVal > 0 ? (cellValue / maxVal).clamp(0.0, 1.0) : 0.0;
                            final Color cellColor = Color.lerp(
                              isDiagonal ? correctColorStart : incorrectColorStart,
                              isDiagonal ? correctColor : incorrectColor,
                              t,
                            )!;

                            return SizedBox(
                              width: cellSize,
                              height: cellSize,
                              child: Container(
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: cellColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    cellValue.toString(),
                                    style: TextStyle(
                                      color: _getTextColorForBackground(cellColor),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}