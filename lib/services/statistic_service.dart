
import 'package:dio/dio.dart';
import 'package:learn_hub/utils/api_helper.dart';

class StatisticService {

  Future<Map<String, dynamic>> countQuizs() async {
    try {
      final response = await dio.get(
        '$baseUrl/quiz/count',
        options: Options(headers: await getAuthHeaders('application/json')),
      );
      return response.data;
    } catch (e) {
      print('Error counting quizzes: $e');
      return {};
    }
  }
}