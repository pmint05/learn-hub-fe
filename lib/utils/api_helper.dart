import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String baseUrl =
    dotenv.env['SERVER_API_URL'] ?? 'http://localhost:3000';

final Dio dio = Dio();

Future<Map<String, String>> getAuthHeaders(String contentType) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final token = await user.getIdToken();
  return {
    'Authorization': 'Bearer $token',
    'Content-Type': contentType.isNotEmpty ? contentType : 'application/json',
  };
}

Future<Map<String, dynamic>> checkTaskStatus(String taskId) async {
  try {
    final response = await dio.get(
      '$baseUrl/status/$taskId',
      options: Options(headers: await getAuthHeaders('application/json')),
    );

    if (response.statusCode == 200) {
      print("Status for task $taskId: ${response.data}");
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