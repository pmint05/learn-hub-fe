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

  Future<Map<String, dynamic>> getResultsByUserId(
    GetResultsByUserIdConfig config,
  ) async {
    final url = '$baseUrl/results/user/${config.currentUserId}';
    try {
      final response = await dio.get(
        url,
        options: Options(headers: await getAuthHeaders('application/json')),
      );
      return response.data;
    } catch (e) {
      print('Error getting results by user ID: $e');
      return {};
    }
  }
}
