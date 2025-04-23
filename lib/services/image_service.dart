import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageServer {
  static final String _baseUrl =
      dotenv.env['IMAGE_SERVER_API_URL'] ?? 'https://api.imgbb.com/1/upload';
  static final String _apiKey = dotenv.env['IMAGE_SERVER_API_KEY'] ?? '';
  final Dio _dio;

  ImageServer() : _dio = Dio();

  Future<Map<String, dynamic>?> uploadImage({
    required File image,
    String? name,
    int? expiration,
  }) async {
    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final formData = FormData.fromMap({
        'key': _apiKey,
        'image': base64Image,
        if (name != null) 'name': name,
        if (expiration != null) 'expiration': expiration.toString(),
      });

      if (expiration != null && (expiration < 60 || expiration > 15552000)) {
        throw Exception('Expiration must be between 60 and 15552000 seconds');
      }

      final response = await _dio.post(_baseUrl, data: formData);

      return response.data;
    } on DioException catch (e) {
      debugPrint('Image upload failed: ${e.message}');
      if (e.response != null) {
        debugPrint('Response status: ${e.response?.statusCode}');
        debugPrint('Response data: ${e.response?.data}');
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> uploadImageFromUrl({
    required String imageUrl,
    String? name,
    int? expiration,
  }) async {
    try {
      // Create form data
      final formData = FormData.fromMap({
        'key': _apiKey,
        'image': imageUrl,
        if (name != null) 'name': name,
        if (expiration != null) 'expiration': expiration.toString(),
      });

      // Validate expiration range if provided
      if (expiration != null && (expiration < 60 || expiration > 15552000)) {
        throw Exception('Expiration must be between 60 and 15552000 seconds');
      }

      // Make the POST request
      final response = await _dio.post(_baseUrl, data: formData);

      return response.data;
    } on DioException catch (e) {
      debugPrint('Image upload from URL failed: ${e.message}');
      if (e.response != null) {
        debugPrint('Response status: ${e.response?.statusCode}');
        debugPrint('Response data: ${e.response?.data}');
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading image from URL: $e');
      return null;
    }
  }

  static String? getDirectUrl(Map<String, dynamic>? response) {
    if (response == null || !response.containsKey('data')) {
      return null;
    }

    final data = response['data'];
    if (data != null && data.containsKey('url')) {
      return data['url'] as String?;
    }

    return null;
  }

  static String? getThumbnailUrl(Map<String, dynamic>? response) {
    if (response == null || !response.containsKey('data')) {
      print('Response is null or does not contain data');
      return null;
    }

    final data = response['data'];
    if (data != null && data.containsKey('thumb')) {
      return data['thumb']['url'] as String?;
    } else if (data['image'] is String) {
      return data['image']['url'] as String?;
    }

    return null;
  }
}
