import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:automl/utils/snackbar_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:automl/core/firebase_setup.dart'; // Import Firebase setup

class ApiService {
  final String _baseUrl = kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';

  // NEW FUNCTION: Verifies the API key against the backend server
  Future<bool> verifyApiKey(String apiKey, BuildContext context) async {
    // This assumes your backend has an endpoint (e.g., /api/auth/verify-key)
    // that accepts the key in the header and validates it against the ENV file value.
    final uri = Uri.parse('$_baseUrl/api/auth/verify-key');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'X-API-KEY': apiKey},
        // The body is often empty or a simple ping payload for verification checks
        body: json.encode({}),
      );

      // Status 200 means success (Key is valid according to the backend check)
      if (response.statusCode == 200) {
        if(context.mounted) {
          showCustomSnackbar(context, 'API Key validated successfully.');
        }
        return true;
      } else {
        // Any other status code (e.g., 401 Unauthorized, 403 Forbidden) means failure
        if(context.mounted) {
          showCustomSnackbar(context, 'API Key verification failed: Key is invalid or rejected by the server.', isError: true);
        }
        return false;
      }
    } catch (e) {
      if(context.mounted) {
        showCustomSnackbar(context, 'Network error during API Key verification. Check server connection.', isError: true);
      }
      return false;
    }
  }

  // Helper method to get the API Key and handle missing key
  Future<String?> _getApiKeyAndValidate(BuildContext context) async {
    final user = auth.currentUser;
    if (user == null) {
      if(context.mounted) {
        showCustomSnackbar(context, 'User not authenticated.', isError: true);
      }
      return null;
    }

    final apiKey = await getApiKey(user.uid);
    final doc = await db.collection('users').doc(user.uid).get();
    final isVerified = doc.data()?['isVerified'] ?? false;


    if (apiKey == null || apiKey.isEmpty) {
      if(context.mounted) {
        showCustomSnackbar(
            context,
            'API Key missing. Please add your key in the Profile menu.',
            isError: true);
      }
      return null;
    }

    // Check verification status before proceeding with API calls
    if (!isVerified) {
      if(context.mounted) {
        showCustomSnackbar(context, 'API Key is unverified. Please save and verify it in your Profile.', isError: true);
      }
      return null;
    }

    return apiKey;
  }

  Future<Map<String, dynamic>?> uploadFile(PlatformFile file, BuildContext context) async {
    final apiKey = await _getApiKeyAndValidate(context);
    if (apiKey == null) return null;

    try {
      final uri = Uri.parse('$_baseUrl/api/upload');
      final request = http.MultipartRequest('POST', uri);
      request.headers['X-API-KEY'] = apiKey;

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', file.path!, filename: file.name));
      }

      final response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 200) {
        if(context.mounted) {
          showCustomSnackbar(context, 'File uploaded successfully.');
        }
        return json.decode(response.body);
      } else {
        if(context.mounted) {
          showCustomSnackbar(
              context, 'File upload failed: ${response.body}', isError: true);
        }
        return null;
      }
    } catch (e) {
      if(context.mounted) {
        showCustomSnackbar(
            context, 'An error occurred during upload: $e', isError: true);
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDataPreview(String fileId, BuildContext context) async {
    final apiKey = await _getApiKeyAndValidate(context);
    if (apiKey == null) return null;

    try {
      final uri = Uri.parse('$_baseUrl/api/analysis/preview/$fileId');
      final response = await http.get(uri, headers: {'X-API-KEY': apiKey}); // Add API key

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        if(context.mounted) {
          showCustomSnackbar(
              context, 'Failed to load data preview: ${response.body}',
              isError: true);
        }
        return null;
      }
    } catch (e) {
      if(context.mounted) {
        showCustomSnackbar(
            context, 'An error occurred fetching preview: $e', isError: true);
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> getVisualizationData(String fileId, String col1, String? col2, BuildContext context) async {
    final apiKey = await _getApiKeyAndValidate(context);
    if (apiKey == null) return null;

    final uri = Uri.parse('$_baseUrl/api/analysis/visualize/$fileId?col1=$col1${col2 != null ? '&col2=$col2' : ''}');
    try {
      final response = await http.get(uri, headers: {'X-API-KEY': apiKey}); // Add API key

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        if(context.mounted) {
          showCustomSnackbar(context,
              'Failed to get visualization data: ${json.decode(
                  response.body)['detail']}', isError: true);
        }
        return null;
      }
    } catch (e) {
      if(context.mounted) {
        showCustomSnackbar(context, 'An error occurred: $e', isError: true);
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> startTrainingJob(String fileId, String targetColumn, Set<String> models, BuildContext context) async {
    final apiKey = await _getApiKeyAndValidate(context);
    if (apiKey == null) return null;

    final uri = Uri.parse('$_baseUrl/api/model/train');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'X-API-KEY': apiKey}, // Add API key
        body: json.encode({
          'file_id': fileId,
          'target_column': targetColumn,
          'models': models.toList(),
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        if(context.mounted) {
          showCustomSnackbar(
              context, 'Failed to start training: ${response.body}',
              isError: true);
        }
        return null;
      }
    } catch (e) {
      if(context.mounted) {
        showCustomSnackbar(context, 'An error occurred: $e', isError: true);
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTrainingStatus(String taskId, BuildContext context) async {
    final apiKey = await _getApiKeyAndValidate(context);
    if (apiKey == null) return null;

    final uri = Uri.parse('$_baseUrl/api/model/status/$taskId');
    try {
      final response = await http.get(uri, headers: {'X-API-KEY': apiKey}); // Add API key

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode != 404) {
        if(context.mounted) {
          showCustomSnackbar(
              context, 'Failed to get status: ${response.body}', isError: true);
        }
      }
      return null;
    } catch (e) {
      if(context.mounted) {
        showCustomSnackbar(context, 'An error occurred: $e', isError: true);
      }
      return null;
    }
  }

  void downloadModel(String modelId) {
    // We assume download links can function without a header, but we still ensure the URL is correct.
    final url = '$_baseUrl/api/model/download/$modelId';
    launchUrl(Uri.parse(url));
  }
}
