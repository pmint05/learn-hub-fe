import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart';

class AskAi {
  final String baseUrl =
      dotenv.env['SERVER_API_URL'] ?? 'http://localhost:3000';
  final dio = Dio();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  String message = "";
  File? file;

  Future<Map<String, String>> _getAuthHeaders(String contentType) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final token = await user.getIdToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': contentType.isNotEmpty ? contentType : 'application/json',
    };
  }

  Future<Map<String, dynamic>> addFileToChat(
    File file,
    PlatformFile fileInfo,
  ) async {
    try {
      print(file);
      print(fileInfo);

      final data = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: basename(file.path),
          contentType: DioMediaType.parse(
            fileInfo.extension != null
                ? 'application/${fileInfo.extension}'
                : 'application/octet-stream',
          ),
        ),
      });

      print("FormData: ${data.fields}, files: ${data.files}");


      final response = await dio.post(
        '$baseUrl/add',
        data: data,
        options: Options(headers: await _getAuthHeaders('multipart/form-data')),
        queryParameters: {'user_id': currentUserId, 'is_public': false},
      );

      if (response.statusCode == 200) {
        print("${fileInfo.name} uploaded successfully");
        return response.data;
      } else {
        print("Failed to upload ${fileInfo.name}: ${response.statusCode}");
        throw Exception('Failed to upload file');
      }
    } catch (e) {
      print('Error uploading file: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendMessageToChat(
    String message,
    String chatId,
  ) async {
    try {
      print("Sending message: $message, by user: $currentUserId");
      final response = await dio.post(
        '$baseUrl/query',
        data: FormData.fromMap({
          'query_text': message,
          'user_id': currentUserId,
        }),
        options: Options(headers: await _getAuthHeaders('multipart/form-data')),
      );

      print(response);
      if (response.statusCode == 200) {
        print("Message sent successfully");
        return response.data;
      } else {
        print("Failed to send message: ${response.statusCode}");
        throw Exception('Failed to send message');
      }
    } catch (e) {
      print('Error sending message: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> checkStatus(String taskId) async {
    try {
      final response = await dio.get(
        '$baseUrl/status/$taskId',
        options: Options(headers: await _getAuthHeaders('application/json')),
      );

      if (response.statusCode == 200) {
        print("Status checked successfully");
        return response.data;
      } else {
        print("Failed to check status: ${response.statusCode}");
        throw Exception('Failed to check status');
      }
    } catch (e) {
      print('Error checking status: $e');
      return {'error': e.toString()};
    }
  }
}
