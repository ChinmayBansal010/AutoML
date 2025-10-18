import 'package:flutter/material.dart';
import 'package:automl/core/api_service.dart';

class DataPreviewStep extends StatefulWidget {
  final String fileId;
  final VoidCallback onContinue;

  const DataPreviewStep({
    super.key,
    required this.fileId,
    required this.onContinue,
  });

  @override
  State<DataPreviewStep> createState() => _DataPreviewStepState();
}

class _DataPreviewStepState extends State<DataPreviewStep> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  int _totalRows = 0;
  List<String> _columns = [];
  Map<String, String> _columnTypes = {};
  List<List<dynamic>> _data = [];
  int _rowsPerPage = 10;
  final List<Color> _tagColors = _generateTagColors();

  @override
  void initState() {
    super.initState();
    _fetchDataPreview();
  }

  static List<Color> _generateTagColors() {
    return [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.red.shade300,
      Colors.teal.shade300,
    ];
  }

  Future<void> _fetchDataPreview() async {
    final result = await _apiService.getDataPreview(widget.fileId, context);
    if (result != null && mounted) {
      setState(() {
        _totalRows = result['total_rows'] ?? 0;
        _columns = List<String>.from(result['columns'] ?? []);
        _columnTypes = Map<String, String>.from(result['column_types'] ?? {});
        _data = List<List<dynamic>>.from(result['data'] ?? []);
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    int numericCount = 0;
    int categoricalCount = 0;
    if (!_isLoading) {
      for (var type in _columnTypes.values) {
        final lowerType = type.toLowerCase();
        if (lowerType.contains('int') || lowerType.contains('float')) {
          numericCount++;
        } else {
          categoricalCount++;
        }
      }
    }

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode ? const Color(0xFF1E2939) : Colors.white,
          border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_outlined, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Data Preview',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Review a sample of your dataset. Ensure columns and data types are correct before proceeding.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            Table(
              columnWidths: const <int, TableColumnWidth>{
                0: FlexColumnWidth(),
                1: FlexColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: <TableRow>[
                TableRow(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0, bottom: 16.0),
                      child: _buildSummaryCard('Total Rows', _totalRows.toString(), Icons.table_rows_rounded, Colors.orange),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                      child: _buildSummaryCard('Total Columns', _columns.length.toString(), Icons.view_column_rounded, Colors.blue),
                    ),
                  ],
                ),
                TableRow(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _buildSummaryCard('Numeric Columns', numericCount.toString(), Icons.pin_outlined, Colors.cyan),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: _buildSummaryCard('Categorical Columns', categoricalCount.toString(), Icons.short_text_rounded, Colors.purple),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Column Types',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: _columns.map((colName) {
                    final colorIndex = colName.hashCode % _tagColors.length;
                    return _buildTypeChip(colName, _tagColors[colorIndex], isDarkMode);
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: PaginatedDataTable(
                header: const Text('Dataset Preview'),
                rowsPerPage: _rowsPerPage,
                onRowsPerPageChanged: (value) {
                  setState(() {
                    _rowsPerPage = value!;
                  });
                },
                availableRowsPerPage: const [10, 20, 50, 100],
                columns: _columns
                    .map((col) => DataColumn(label: Text(col, style: const TextStyle(fontWeight: FontWeight.bold))))
                    .toList(),
                source: _PreviewDataSource(_data),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: widget.onContinue,
                child: const Text('Looks Good, Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String colName, Color color, bool isDarkMode) {
    final colType = _columnTypes[colName]?.toLowerCase() ?? 'object';
    final isNumeric = colType.contains('int') || colType.contains('float');
    final typeName = isNumeric ? 'Numeric' : 'Categorical';

    return Chip(
      backgroundColor: isDarkMode ? color.withOpacity(0.3) : color.withOpacity(0.8),
      side: BorderSide.none,
      label: Text.rich(
        TextSpan(
          text: '$colName ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          children: [
            TextSpan(
              text: '($typeName)',
              style: TextStyle(
                fontWeight: FontWeight.normal,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewDataSource extends DataTableSource {
  final List<List<dynamic>> _data;
  _PreviewDataSource(this._data);

  @override
  DataRow getRow(int index) {
    return DataRow(
      cells: _data[index].map((cell) => DataCell(Text(cell.toString()))).toList(),
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => _data.length;
  @override
  int get selectedRowCount => 0;
}