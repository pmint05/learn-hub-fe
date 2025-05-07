import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:learn_hub/const/material_service_config.dart';
import 'package:learn_hub/utils/api_helper.dart';
import 'package:path/path.dart';

class MaterialManager {
  static final MaterialManager instance = MaterialManager._internal();

  factory MaterialManager() {
    return instance;
  }

  MaterialManager._internal();

  String baseUrl = dotenv.env['SERVER_API_URL'] ?? 'http://localhost:8000';
  final Dio dio = Dio();

  Future<Map<String, dynamic>> uploadMaterial(FileUploadConfig config) async {
    try {
      print('Uploading material with config: ${config.toJson()}');

      final data = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          config.file.path,
          filename: basename(config.file.path),
          contentType: DioMediaType.parse(
            config.fileInfo.extension != null
                ? 'application/${config.fileInfo.extension}'
                : 'application/octet-stream',
          ),
        ),
      });

      print("FormData: ${data.fields}, files: ${data.files}");

      final response = await dio.post(
        '$baseUrl/upload',
        data: data,
        options: Options(headers: await getAuthHeaders('multipart/form-data')),
        queryParameters: {
          'user_id': config.currentUserId,
          'is_public': config.isPublic,
        },
      );
      return response.data;
    } catch (e) {
      print('Error uploading material: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> searchMaterial(
    SearchMaterialConfig config,
  ) async {
    try {
      print('Searching material with config: ${config.toJson()}');

      final response = await dio.post(
        '$baseUrl/document/search',
        data: config.toJson(),
        options: Options(headers: await getAuthHeaders('application/json')),
      );

      return response.data;
    } catch (e) {
      print('Error searching material: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> deleteMaterialById(String id) async {
    try {
      print('Deleting material with id: $id');

      final response = await dio.delete(
        '$baseUrl/document/$id',
        options: Options(headers: await getAuthHeaders('application/json')),
      );

      return response.data;
    } catch (e) {
      print('Error deleting material: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> updateDocumentInfo({
    required String id,
    String? title,
    bool? isPublic,
  }) async {
    try {
      print('Updating document info with id: $id');

      final response = await dio.put(
        '$baseUrl/document',
        // data: {
        //   'title': title,
        //   'description': description,
        //   'is_public': isPublic,
        // },
        queryParameters: {
          'document_id': id,
          if (title != null) 'filename': title,
          if (isPublic != null) 'is_public': isPublic,
        },
        options: Options(headers: await getAuthHeaders('application/json')),
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {
        print('Dio error: ${e.message}');
        return e.response?.data ?? {};
      } else {
        print('Error updating document info: $e');
        return {
          'status': 'error',
          'message': 'An error occurred while updating document info',
        };
      }
    }
  }
}
