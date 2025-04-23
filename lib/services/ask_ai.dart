import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:learn_hub/screens/ask.dart';
import 'package:learn_hub/utils/api_helper.dart';
import 'package:path/path.dart';

class AskAi {
  static final AskAi instance = AskAi._internal();

  factory AskAi() {
    return instance;
  }

  AskAi._internal();

  final String baseUrl =
      dotenv.env['SERVER_API_URL'] ?? 'http://localhost:3000';
  final dio = Dio();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  String message = "";
  File? file;

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
        options: Options(headers: await getAuthHeaders('multipart/form-data')),
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
        options: Options(headers: await getAuthHeaders('multipart/form-data')),
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

  Future<Map<String, dynamic>> addContextFileToChat(
    List<ContextFileInfo> contextFiles,
  ) async {
    try {
      print("Adding context: $context, by user: $currentUserId");
      final response = await dio.post(
        '$baseUrl/document/pinecone/${contextFiles.first.id}',
        data: {},
        options: Options(headers: await getAuthHeaders('application/json')),
      );

      print(response);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        print("Failed to add context: ${response.statusCode}");
        throw Exception('Failed to add context');
      }
    } catch (e) {
      print('Error adding context: $e');
      return {'error': e.toString()};
    }
  }
}
