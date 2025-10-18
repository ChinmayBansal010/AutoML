import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:automl/utils/snackbar_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiService {
  final String _baseUrl = kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';

  Future<Map<String, dynamic>?> uploadFile(PlatformFile file, BuildContext context) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/upload');
      print('Attempting to upload to: $uri');
      final request = http.MultipartRequest('POST', uri);
      request.headers['X-API-KEY'] = 'VTDzdjjDdQMx6ZvhA8MUNYrhtgH7vv64D2pzBmZD13CNGeZQj4GW4kfUvNGWz72D';
      if (kIsWeb) {
        print('Uploading from web with bytes...'); // <-- LOG 2
        request.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));
      } else {
        print('Uploading from mobile with path: ${file.path}'); // <-- LOG 3
        request.files.add(await http.MultipartFile.fromPath('file', file.path!, filename: file.name));
      }

      final response = await http.Response.fromStream(await request.send());

      print('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        showCustomSnackbar(context, 'File uploaded successfully.');
        return json.decode(response.body);
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

  Future<Map<String, dynamic>?> getVisualizationData(String fileId, String col1, String? col2, BuildContext context) async {
    final uri = Uri.parse('$_baseUrl/api/analysis/visualize/$fileId?col1=$col1${col2 != null ? '&col2=$col2' : ''}');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        showCustomSnackbar(context, 'Failed to get visualization data: ${json.decode(response.body)['detail']}', isError: true);
        return null;
      }
    } catch (e) {
      showCustomSnackbar(context, 'An error occurred: $e', isError: true);
      return null;
    }
  }

  Future<Map<String, dynamic>?> startTrainingJob(String fileId, String targetColumn, Set<String> models, BuildContext context) async {
    final uri = Uri.parse('$_baseUrl/api/model/train');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'file_id': fileId,
          'target_column': targetColumn,
          'models': models.toList(),
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        showCustomSnackbar(context, 'Failed to start training: ${response.body}', isError: true);
        return null;
      }
    } catch (e) {
      showCustomSnackbar(context, 'An error occurred: $e', isError: true);
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTrainingStatus(String taskId, BuildContext context) async {
    final uri = Uri.parse('$_baseUrl/api/model/status/$taskId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode != 404) { // Don't show snackbar for "not found" during initial polling
        showCustomSnackbar(context, 'Failed to get status: ${response.body}', isError: true);
      }
      return null;
    } catch (e) {
      showCustomSnackbar(context, 'An error occurred: $e', isError: true);
      return null;
    }
  }

  void downloadModel(String modelId) {
    final url = '$_baseUrl/api/model/download/$modelId';
    launchUrl(Uri.parse(url));
  }
}
