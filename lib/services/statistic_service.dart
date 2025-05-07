import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learn_hub/const/search_quiz_config.dart';
import 'package:learn_hub/utils/api_helper.dart';

class StatisticService {
  Future<Map<String, dynamic>> countQuiz(SearchQuizConfig config) async {
    try {
      print('Counting quizzes with config: ${config.toJson()}');
      final response = await dio.post(
        '$baseUrl/quiz/count',
        data: config.toJson(),
        options: Options(headers: await getAuthHeaders('application/json')),
      );
      return response.data;
    } catch (e) {
      print('Error counting quizzes: $e');
      return {};
    }
  }
  Future<Map<String, dynamic>> countTotalQuizAttempts() async {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) {
      return {};
    }
    try {
      print('Counting total quiz attempts for user: $currentUserId');
      final response = await dio.get(
        '$baseUrl/results/user/$currentUserId/count',
        options: Options(headers: await getAuthHeaders('application/json')),
      );
      return response.data;
    } catch (e) {
      print('Error counting quizzes: $e');
      return {};
    }
  }
}
