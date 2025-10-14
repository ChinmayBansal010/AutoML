import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:automl/data/models/upload_summary.dart';
import 'package:automl/data/models/job_models.dart';
import 'dart:io';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  Future<UploadSummary> uploadFile(String filePath, String fileName) async {
    final uri = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', uri);

    final file = await http.MultipartFile.fromPath(
      'file',
      filePath,
      filename: fileName,
    );

    request.files.add(file);

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        return UploadSummary.fromJson(data);
      } else {
        throw Exception('API Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Network or processing error: $e');
    }
  }

  Future<StatusResponse> startTrainingJob(TrainingRequest request) async {
    final uri = Uri.parse('$baseUrl/model/train');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode(request.toJson());

    try {
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        return StatusResponse.fromJson(data);
      } else {
        throw Exception('API Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  Future<StatusResponse> getJobStatus(String taskId) async {
    final uri = Uri.parse('$baseUrl/model/status/$taskId');
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        return StatusResponse.fromJson(data);
      } else {
        throw Exception('API Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }
}
