import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart';
import '../../config/config.dart';
import 'api_service.dart';
import 'gql_exception.dart';

class ApifilesServer {
  static final ApifilesServer _instance = ApifilesServer._internal();
  factory ApifilesServer() => _instance;
  ApifilesServer._internal();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.fileServerUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  String? get _token => ApiServer.token;

  MediaType _getMediaType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return MediaType('image', ext);
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'zip':
        return MediaType('application', 'zip');
      case 'mp4':
        return MediaType('video', 'mp4');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    required String bucketName,
    required String sl,
    required String fileName,
    bool isAI = false,
    void Function(int, int)? onProgress,
  }) async {
    try {
      final file = File(filePath);

      if (!file.existsSync()) {
        throw GqlException("File not found");
      }

      FormData formData = FormData.fromMap({
        "bucket_name": bucketName,
        "sl": sl,
        "file_upload": await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: _getMediaType(fileName),
        ),
      });
      final response = await _dio.post(
        "/v1/upload_obj",
        data: formData,
        onSendProgress: onProgress,
        options: Options(
          headers: {
            if (_token != null) "Authorization": "Bearer $_token",

            "Accept": "application/json",
          },
        ),
      );
      // print("UPLOAD RESPONSE = ${response.data}");
      final data = response.data;
      if (data == null) {
        throw GqlException("Empty response");
      }

      return Map<String, dynamic>.from(data);
    } on DioException catch (e) {
      throw GqlException(
        e.response?.data.toString() ?? e.message ?? "Upload failed",
      );
    } catch (e) {
      throw GqlException(e.toString());
    }
  }
}
