import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:learn_hub/const/search_quiz_config.dart';

class QuizManager {
  static final QuizManager instance = QuizManager._internal();

  factory QuizManager() {
    return instance;
  }

  QuizManager._internal();

  final String baseUrl =
      dotenv.env['SERVER_API_URL'] ?? 'http://localhost:8000';
  final Dio dio = Dio();

  Future<Map<String, dynamic>> getQuizzes({
    required SearchQuizConfig config,
  }) async {
    try {
      print('Fetching quizzes with config: ${config.toJson()}');

      final response = await dio.post(
        '$baseUrl/quiz/search',
        data: config.toJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return response.data;
    } catch (e) {
      print('Error fetching quizzes: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getQuizById({
    required String quizId,
  }) async {
    try {
      print('Fetching quiz with ID: $quizId');

      final response = await dio.get(
        '$baseUrl/quiz/$quizId',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return response.data;
    } catch (e) {
      print('Error fetching quizzes: $e');
      return {};
    }
  }
}
