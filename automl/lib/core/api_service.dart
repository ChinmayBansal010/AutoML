import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:automl/utils/snackbar_helper.dart';

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:8000';

  Future<Map<String, dynamic>?> uploadFile(PlatformFile file, BuildContext context) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/upload/');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));

      final response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 200) {
        showCustomSnackbar(context, 'File uploaded successfully.');
        return json.decode(response.body); // This will contain the 'file_id'
      } else {
        showCustomSnackbar(context, 'File upload failed: ${response.body}', isError: true);
        return null;
      }
    } catch (e) {
      showCustomSnackbar(context, 'An error occurred during upload: $e', isError: true);
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDataPreview(String fileId, BuildContext context) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/analysis/preview/$fileId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        showCustomSnackbar(context, 'Failed to load data preview: ${response.body}', isError: true);
        return null;
      }
    } catch (e) {
      showCustomSnackbar(context, 'An error occurred fetching preview: $e', isError: true);
      return null;
    }
  }
}