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
  List<String> _columns = [];
  List<List<dynamic>> _data = [];
  int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchDataPreview();
  }

  Future<void> _fetchDataPreview() async {
    final result = await _apiService.getDataPreview(widget.fileId, context);
    if (result != null && mounted) {
      setState(() {
        _columns = List<String>.from(result['columns'] ?? []);
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

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Preview',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review a sample of your dataset (first 500 rows). Ensure columns and data types are correct.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCard('Total Rows', _data.length.toString(), Icons.table_rows, Colors.orange),
              _buildSummaryCard('Total Columns', _columns.length.toString(), Icons.view_column, Colors.blue),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: PaginatedDataTable(
              header: const Text('Dataset'),
              rowsPerPage: _rowsPerPage,
              onRowsPerPageChanged: (value) {
                setState(() {
                  _rowsPerPage = value!;
                });
              },
              availableRowsPerPage: const [10, 20, 100],
              columns: _columns.map((col) => DataColumn(label: Text(col, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
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
              ),
              onPressed: widget.onContinue,
              child: const Text('Continue', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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