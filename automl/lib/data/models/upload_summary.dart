import 'package:flutter/material.dart';

@immutable
class UploadSummary {
  final String fileId;
  final String filename;
  final int rowCount;
  final List<String> columns;
  final Map<String, String> columnDtypes;
  final List<Map<String, dynamic>> sampleData;

  const UploadSummary({
    required this.fileId,
    required this.filename,
    required this.rowCount,
    required this.columns,
    required this.columnDtypes,
    required this.sampleData,
  });

  factory UploadSummary.fromJson(Map<String, dynamic> json) {
    return UploadSummary(
      fileId: json['file_id'] as String,
      filename: json['filename'] as String,
      rowCount: json['row_count'] as int,
      columns: List<String>.from(json['columns'] as List),
      columnDtypes: Map<String, String>.from(json['column_dtypes'] as Map),
      sampleData: List<Map<String, dynamic>>.from(json['sample_data'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file_id': fileId,
      'filename': filename,
      'row_count': rowCount,
      'columns': columns,
      'column_dtypes': columnDtypes,
      'sample_data': sampleData,
    };
  }
}
