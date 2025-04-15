import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:learn_hub/const/quizzes_generator_config.dart';
import 'package:learn_hub/const/quizzes_task.dart';

// Add correct path import for file name handling
import 'package:path/path.dart' show basename;
import 'package:shared_preferences/shared_preferences.dart';

class QuizzesGenerator {
  final String baseUrl =
      dotenv.env['SERVER_API_URL'] ?? 'http://localhost:3000';
  final dio = Dio();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  QuizzesTask? _currentTask;

  QuizzesTask? get currentTask => _currentTask;

  Future<void> _loadCurrentTask() async {
    final prefs = await SharedPreferences.getInstance();
    final taskJson = prefs.getString('current_quizzes_task');
    if (taskJson != null) {
      try {
        _currentTask = QuizzesTask.fromJson(json.decode(taskJson));
        print("Loaded task: ${_currentTask!.taskId}");
      } catch (e) {
        print('Error loading task: $e');
        await _clearCurrentTask();
      }
    }
  }

  Future<void> _saveCurrentTask() async {
    if (_currentTask == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'current_quizzes_task',
      json.encode(_currentTask!.toJson()),
    );
  }

  Future<void> _clearCurrentTask() async {
    _currentTask = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_quizzes_task');
  }

  Future<Map<String, String>> _getAuthHeaders(String contentType) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // final token = await user.getIdToken();
    final token = "MY_TOKEN";
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': contentType.isNotEmpty ? contentType : 'application/json',
    };
  }

  Future<QuizzesTask> createQuizzesTask({
    required QuizzesGeneratorConfig config,
    File? file,
    PlatformFile? fileInfo,
    String? text,
    String? url,
    Function(double, String)? onProgress,
  }) async {
    await _loadCurrentTask();

    if (_currentTask != null &&
        ['pending', 'processing'].contains(_currentTask!.status)) {
      return _currentTask!;
    }

    switch (config.source) {
      case QuizzesSource.file:
        return await _createQuizzesTaskFromFile(
          file,
          fileInfo,
          config,
          onProgress,
        );
      case QuizzesSource.text:
        // TODO: Handle this case.
        throw UnimplementedError();
      case QuizzesSource.image:
        // TODO: Handle this case.
        throw UnimplementedError();
      case QuizzesSource.link:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Future<QuizzesTask> _createQuizzesTaskFromFile(
    File? file,
    PlatformFile? fileInfo,
    QuizzesGeneratorConfig config,
    Function(double, String)? onProgress,
  ) async {
    onProgress?.call(0.1, "Reading file");

    final headers = await _getAuthHeaders('multipart/form-data');

    Uint8List fileBytes;
    String fileName;

    if (fileInfo != null && fileInfo.bytes != null) {
      fileBytes = fileInfo.bytes!;
      fileName = fileInfo.name;
    } else if (file != null) {
      try {
        fileBytes = await file.readAsBytes();
        fileName = basename(file.path);
      } catch (e) {
        throw Exception('Failed to read file: ${e.toString()}');
      }
    } else {
      throw Exception('No file provided');
    }

    FormData formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });

    final params = {
      'type': config.type.name.toLowerCase(),
      'mode': config.mode.name.toLowerCase(),
      'difficulty': config.difficulty.name.toLowerCase(),
      'count': config.numberOfQuiz.toString(),
      'lang': config.language.name.toLowerCase(),
      if (currentUserId != null && currentUserId!.isNotEmpty)
        'user_id': currentUserId!,
      'is_public': true,
    };

    try {
      onProgress?.call(0.3, "Uploading file");

      final response = await dio.post(
        '$baseUrl/generate',
        data: formData,
        queryParameters: params,
        options: Options(headers: headers),
        onSendProgress: (sent, total) {
          final progress = 0.3 + (sent / total * 0.5);
          onProgress?.call(
            progress,
            "Uploading file: ${(sent / total * 100).toStringAsFixed(0)}%",
          );
        },
      );

      onProgress?.call(0.9, "Processing response");

      if (response.statusCode == 200) {
        final taskId = response.data['task_id'];
        final status = response.data['status'] ?? 'pending';

        _currentTask = QuizzesTask(
          taskId: taskId,
          createdAt: DateTime.now(),
          config: config,
          status: status,
        );

        await _saveCurrentTask();
        return _currentTask!;
      } else {
        throw Exception('Failed to create task: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('API Error: ${e.response?.statusCode} - ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Invalid request parameters: ${e.response?.data}');
      } else {
        throw Exception('Failed to generate quizzes: ${e.message}');
      }
    }
  }

  Future<String> checkTaskStatus(String taskId) async {
    try {
      final headers = await _getAuthHeaders('application/json');
      final response = await dio.get(
        '$baseUrl/status/$taskId',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final status = response.data['status'];
        if (_currentTask != null && _currentTask!.taskId == taskId) {
          if (status == 'error') {
            final errorMessage = response.data['message'] ?? 'Unknown error';
            _currentTask?.errorMessage = errorMessage;
          }
          _currentTask!.status = status;
          await _saveCurrentTask();
        }
        return status;
      } else {
        throw Exception('Failed to check status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking task status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTaskResult(String taskId) async {
    try {
      final headers = await _getAuthHeaders('application/json');
      final response = await dio.get(
        '$baseUrl/status/$taskId',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data =
            response.data['result']['quizzes'] ??
            response.data['result']['questions'] ??
            response.data['result']['data'] ??
            [];

        final result = List<Map<String, dynamic>>.from(data);

        if (_currentTask != null && _currentTask!.taskId == taskId) {
          _currentTask!.result = result;
          _currentTask!.status = 'completed';
          await _saveCurrentTask();
        }

        return result;
      } else {
        throw Exception('Failed to get result: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting task result: $e');
    }
  }

  Future<void> clearCurrentTask() async {
    await _clearCurrentTask();
  }

  Future<void> loadCurrentTask() async {
    await _loadCurrentTask();
  }

  Future<List<Map<String, dynamic>>> generateQuizzes({
    required QuizzesGeneratorConfig config,
    File? file,
    PlatformFile? fileInfo,
    String? text,
    String? url,
    Function(double, String)? onProgress,
  }) async {
    final task = await createQuizzesTask(
      config: config,
      file: file,
      fileInfo: fileInfo,
      text: text,
      url: url,
      onProgress: onProgress,
    );

    // Poll for status until complete
    String status = task.status;
    while (status != 'completed' && status != 'failed') {
      await Future.delayed(const Duration(seconds: 2));
      status = await checkTaskStatus(task.taskId);
      onProgress?.call(0.95, "Waiting for processing completion... $status");
    }

    if (status == 'failed') {
      throw Exception('Task processing failed');
    }

    // Get the result
    return await getTaskResult(task.taskId);
  }
}

({String type, String subtype}) _getFileType(String path) {
  // Use basename to handle file paths properly
  final ext = basename(path).split('.').last.toLowerCase();
  switch (ext) {
    case 'pdf':
      return (type: 'application', subtype: 'pdf');
    case 'docx':
      return (
        type: 'application',
        subtype: 'vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
    case 'doc':
      return (
        type: 'application',
        subtype: 'vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
    case 'txt':
      return (type: 'text', subtype: 'plain');
    case 'md':
      return (type: 'text', subtype: 'markdown');
    default:
      return (type: 'application', subtype: 'octet-stream');
  }
}
