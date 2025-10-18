import 'package:flutter/material.dart';
import 'package:automl/core/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class DataVisualizationStep extends StatefulWidget {
  final String fileId;
  final Function(String) onContinue;

  const DataVisualizationStep({
    super.key,
    required this.fileId,
    required this.onContinue,
  });

  @override
  State<DataVisualizationStep> createState() => _DataVisualizationStepState();
}

class _DataVisualizationStepState extends State<DataVisualizationStep> {
  final ApiService _apiService = ApiService();
  bool _isPageLoading = true;
  bool _isAnalysisLoading = false;
  bool _isScatterLoading = false;

  List<String> _columns = [];
  Map<String, String> _columnTypes = {};
  List<String> _numericColumns = [];

  String? _selectedColumn1;
  String? _selectedScatterX;
  String? _selectedScatterY;
  String? _selectedTargetColumn;

  Map<String, dynamic>? _analysisData;
  Map<String, dynamic>? _scatterData;

  @override
  void initState() {
    super.initState();
    _fetchInitialColumns();
  }

  Future<void> _fetchInitialColumns() async {
    final result = await _apiService.getDataPreview(widget.fileId, context);
    if (result != null && mounted) {
      setState(() {
        _columns = List<String>.from(result['columns'] ?? []);
        _columnTypes = Map<String, String>.from(result['column_types'] ?? {});
        _numericColumns = _columns.where((c) {
          final type = _columnTypes[c]?.toLowerCase() ?? '';
          return type.contains('int') || type.contains('float');
        }).toList();
        _isPageLoading = false;
      });
    }
  }

  Future<void> _fetchAnalysisData(String? colName) async {
    if (colName == null) return;
    setState(() {
      _selectedColumn1 = colName;
      _isAnalysisLoading = true;
      _analysisData = null;
    });
    final result = await _apiService.getVisualizationData(widget.fileId, colName, null, context);
    if (result != null && mounted) {
      setState(() {
        _analysisData = result['column_1'];
        _isAnalysisLoading = false;
      });
    }
  }

  Future<void> _fetchScatterData() async {
    if (_selectedScatterX == null || _selectedScatterY == null) return;
    setState(() {
      _isScatterLoading = true;
      _scatterData = null;
    });
    final result = await _apiService.getVisualizationData(widget.fileId, _selectedScatterX!, _selectedScatterY, context);
    if (result != null && mounted) {
      setState(() {
        _scatterData = result['scatter_data'];
        _isScatterLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isPageLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Data Visualization', Icons.auto_awesome),
          const SizedBox(height: 8),
          Text(
            'Explore your data by selecting columns to visualize. The charts will update automatically.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          _buildSingleColumnCard(),
          const SizedBox(height: 24),
          _buildTwoColumnCard(),
          const SizedBox(height: 24),
          _buildTargetSelectionCard(),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedTargetColumn != null ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _selectedTargetColumn != null ? () => widget.onContinue(_selectedTargetColumn!) : null,
              child: const Text('Continue to Model Selection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleColumnCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Single Column Analysis', Icons.analytics_outlined, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildDropdown(_columns, 'Select a column to analyze...', _selectedColumn1, _fetchAnalysisData),
            const SizedBox(height: 24),
            if (_isAnalysisLoading) const Center(child: CircularProgressIndicator()),
            if (_analysisData != null) _buildAnalysisResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoColumnCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Two Column Comparison', Icons.scatter_plot_outlined, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDropdown(_numericColumns, 'Select X-Axis', _selectedScatterX, (val) {
                  setState(() => _selectedScatterX = val);
                  _fetchScatterData();
                })),
                const SizedBox(width: 16),
                Expanded(child: _buildDropdown(_numericColumns, 'Select Y-Axis', _selectedScatterY, (val) {
                  setState(() => _selectedScatterY = val);
                  _fetchScatterData();
                })),
              ],
            ),
            const SizedBox(height: 24),
            if (_isScatterLoading) const Center(child: CircularProgressIndicator()) else if (_scatterData != null) _buildScatterPlot() else Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetSelectionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Select Target Column', Icons.track_changes, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Choose the column you want the model to predict.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            _buildDropdown(_columns, 'Select Target Column...', _selectedTargetColumn, (val) {
              setState(() => _selectedTargetColumn = val);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {TextStyle? style}) {
    return Row(children: [
      Icon(icon, size: 24, color: Theme.of(context).primaryColor),
      const SizedBox(width: 8),
      Text(title, style: style ?? Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildDropdown(List<String> items, String hint, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildAnalysisResults() {
    final type = _analysisData!['type'];
    return type == 'numeric' ? _buildNumericResults() : _buildCategoricalResults();
  }

  Widget _buildNumericResults() {
    final stats = _analysisData!['stats'];
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatCard('Min', (stats['min'] ?? 0).toStringAsFixed(2), Icons.arrow_downward, Colors.blue),
                _buildStatCard('Max', (stats['max'] ?? 0).toStringAsFixed(2), Icons.arrow_upward, Colors.red),
                _buildStatCard('Mean', (stats['mean'] ?? 0).toStringAsFixed(2), Icons.functions, Colors.orange),
                _buildStatCard('Median', (stats['median'] ?? 0).toStringAsFixed(2), Icons.linear_scale, Colors.green),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildBarChart(),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    final chartData = _analysisData!['chart_data'];
    final values = List<num>.from(chartData['values']);
    final labels = List<String>.from(chartData['labels']);

    // 1. Define spacing and calculate the required width for the chart
    const double barWidth = 14.0;
    const double spaceBetweenBars = 10.0;
    final double chartWidth = labels.length * (barWidth + spaceBetweenBars);

    // 2. Wrap the chart in a SingleChildScrollView
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartWidth, // 3. Apply the dynamic width
        height: 300,
        child: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: values.asMap().entries.map((e) {
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                    toY: e.value.toDouble(),
                    color: Colors.blue.shade300,
                    width: barWidth,
                    borderRadius: BorderRadius.circular(4),
                  )
                ]);
              }).toList(),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= labels.length) return const SizedBox.shrink();
                      // 4. Display labels horizontally without rotation
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 8.0,
                        child: Text(
                          labels[index],
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${labels[group.x]}\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      children: <TextSpan>[
                        TextSpan(
                          text: (rod.toY).toString(),
                          style: const TextStyle(color: Colors.yellow),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoricalResults() {
    final chartData = _analysisData!['chart_data'];
    final List<String> labels = List<String>.from(chartData['labels']);
    final List<dynamic> values = List.from(chartData['values']);
    final colors = List.generate(labels.length, (i) => Colors.primaries[i % Colors.primaries.length]);

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: values.asMap().entries.map((e) {
                return PieChartSectionData(
                  color: colors[e.key],
                  value: (e.value as num).toDouble(),
                  title: '',
                  radius: 80,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 100,
          child: SingleChildScrollView(
            child: _buildLegend(labels, colors),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(List<String> labels, List<Color> colors) {
    return Wrap(
      spacing: 16.0,
      runSpacing: 8.0,
      children: List.generate(labels.length, (index) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, color: colors[index]),
            const SizedBox(width: 8),
            Text(labels[index]),
          ],
        );
      }),
    );
  }

  Widget _buildScatterPlot() {
    final xValues = List<num?>.from(_scatterData!['x']).where((e) => e != null).cast<num>().toList();
    final yValues = List<num?>.from(_scatterData!['y']).where((e) => e != null).cast<num>().toList();

    if (xValues.isEmpty || yValues.isEmpty) {
      return const SizedBox(height: 350, child: Center(child: Text("Not enough data to display scatter plot.")));
    }

    final maxX = xValues.isNotEmpty ? xValues.reduce(max).toDouble() : 1.0;
    final intervalX = (maxX > 0 ? maxX / 5 : 1).clamp(1.0, double.infinity);

    return SizedBox(
      height: 350,
      child: Padding(
        padding: const EdgeInsets.only(right: 24.0, top: 16.0),
        child: ScatterChart(
          ScatterChartData(
            scatterSpots: [
              for (int i = 0; i < min(xValues.length, yValues.length); i++)
                ScatterSpot(
                  xValues[i].toDouble(),
                  yValues[i].toDouble(),
                  dotPainter: FlDotCirclePainter(
                    radius: 3,
                    color: Colors.blue.withOpacity(0.7),
                    strokeWidth: 0,
                  ),
                ),
            ],
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: intervalX.toDouble())),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true),
            gridData: const FlGridData(show: true),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 150,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}