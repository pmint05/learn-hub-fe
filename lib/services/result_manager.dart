import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:learn_hub/const/result_manager_config.dart';
import 'package:learn_hub/utils/api_helper.dart';

class ResultManager {
  static final ResultManager instance = ResultManager._internal();

  factory ResultManager() {
    return instance;
  }

  final String baseUrl =
      dotenv.env['SERVER_API_URL'] ?? 'http://localhost:8000';
  final Dio dio = Dio();

  ResultManager._internal();

  Future<Map<String, dynamic>> createNewResult(
    CreateResultConfig config,
  ) async {
    final url = '$baseUrl/results/quiz';
    try {
      print('Creating new result with config: ${config.toJson()}');
      final response = await dio.post(
        '$url/${config.quizId}/user/${config.currentUserId}',
        data: {},
        options: Options(headers: await getAuthHeaders('application/json')),
      );
      return response.data;
    } catch (e) {
      print('Error creating new result: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> sendAnswer({
    required String resultId,
    required String questionId,
    required int answer,
    required String isCorrect,
  }) async {
    final url = '$baseUrl/results/$resultId/answer';
    try {
      print('Sending answer: $answer for question $questionId in result $resultId');
      final response = await dio.put(
        url,
        data: {
          'answer': answer,
          'is_correct': isCorrect,
          'question_id': questionId,
        },
        options: Options(headers: await getAuthHeaders('application/json')),
      );
      print(response.data);
      return response.data;
    } catch (e) {
      print('Error sending answer: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getResultsByUserId(
    GetResultsByUserIdConfig config,
  ) async {
    print("Getting results with config: ${config.toJson()}");
    final url = '$baseUrl/results/user/${config.currentUserId}';
    try {
      final response = await dio.get(
        url,
        options: Options(headers: await getAuthHeaders('application/json')),
        queryParameters: {
          if (config.size != null) 'limit': config.size,
          if (config.start != null) 'skip': config.start,
          if (config.sortBy != null) 'sort_by': config.sortBy,
          if (config.sortOrder != null) 'sort_order': config.sortOrder,
        },
      );
      return response.data;
    } catch (e) {
      print('Error getting results by user ID: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getResultById({required String resultId}) async {
    final url = '$baseUrl/results/$resultId';
    try {
      final response = await dio.get(
        url,
        options: Options(headers: await getAuthHeaders('application/json')),
      );
      return response.data;
    } catch (e) {
      print('Error getting result data: $e');
      return {};
    }
  }
}
