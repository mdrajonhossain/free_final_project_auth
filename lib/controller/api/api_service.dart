import 'dart:convert';
import 'package:dio/dio.dart'; // Import Dio
import 'package:freeli/model/modelScreema_quary.dart';
import '../../model/modelScreema_mutation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gql_exception.dart';

class ApiServer {
  // Singleton instance
  static final ApiServer _instance = ApiServer._internal();
  factory ApiServer() => _instance;
  ApiServer._internal();

  static final Dio _dio = Dio();
  static String? _token;
  static const String _graphqlUrl = "http://62.151.182.241:4055/workfreeli";

  static String? get token => _token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("token");
  }

  static Future<void> setAuthToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString("token", token);
    } else {
      await prefs.remove("token");
    }
  }

  static Future<void> clearAuthToken() async {
    await setAuthToken(null);
  }

  static String? _extractOperationName(String document) {
    final RegExp operationNameRegex = RegExp(r'(query|mutation)\s+(\w+)');
    final match = operationNameRegex.firstMatch(document);
    return match?.group(2);
  }

  static Future<Map<String, dynamic>> call(
    String document, {
    Map<String, dynamic>? variables,
  }) async {
    final operationName = _extractOperationName(document);
    try {
      final response = await _dio.post(
        _graphqlUrl,
        data: {
          'query': document,
          if (operationName != null) 'operationName': operationName,
          if (variables != null && variables.isNotEmpty) 'variables': variables,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_token != null) 'Authorization': 'Bearer $_token',
          },
        ),
      );

      final body = response.data;
      if (body is! Map) {
        throw const GqlException('Unexpected response format from server.');
      }

      final errors = body['errors'];
      if (errors is List && errors.isNotEmpty) {
        final msg =
            ((errors.first as Map)['message'] as String?) ?? 'GraphQL error';
        print('[GQL ERROR] op=$operationName msg=$msg');
        throw GqlException(msg);
      }

      final data = (body['data'] as Map?)?.cast<String, dynamic>() ?? {};
      print(
        '[GQL OK] op=$operationName keys=${data.keys.toList()}',
      ); // ignore: avoid_print
      return data;
    } on GqlException {
      rethrow;
    } on DioException catch (e) {
      final detail =
          e.response?.data?.toString() ??
          e.message ??
          'Network error. Check your connection.';
      throw GqlException(detail);
    } catch (e) {
      throw GqlException(e.toString());
    }
  }

  Future<Map<String, dynamic>> login({
    String? email,
    String? password,
    String? companyId,
    String? code,
    String? sessionToken,
    required String step,
    String deviceId = "android",
  }) async {
    Map<String, dynamic> variables = {"step": step, "deviceId": deviceId};

    if (step == "validate") {
      variables.addAll({"email": email, "password": password});
    } else if (step == "otp") {
      variables.addAll({
        "email": email,
        "code": code,
        "sessionToken": sessionToken,
      });
    } else if (step == "company") {
      variables.addAll({
        "email": email,
        "companyId": companyId,
        "sessionToken": sessionToken,
      });
    } else {
      throw GqlException("Invalid step: $step");
    }

    variables.removeWhere((key, value) => value == null);

    try {
      final response = await _dio.post(
        _graphqlUrl,
        data: {"query": loginMutation, "variables": variables},
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw const GqlException('Unexpected response format from server.');
      }

      if (responseData['errors'] != null) {
        throw GqlException(responseData['errors'][0]['message']);
      }

      final loginData = responseData['data']['login'];

      if (loginData['status'] == true) {
        final String? token = loginData['token'];
        if (token != null && token.isNotEmpty) {
          await ApiServer.setAuthToken(token); // Store the token
        }
        return Map<String, dynamic>.from(loginData);
      } else {
        throw GqlException(loginData['message'] ?? "Login failed");
      }
    } on DioException catch (e) {
      final detail =
          e.response?.data?.toString() ??
          e.message ??
          'Network error. Check your connection.';
      throw GqlException(detail);
    } catch (e) {
      throw GqlException(e.toString());
    }
  }

  // ================= meapi==========================================
  Future<Map<String, dynamic>> fetchMe() async {
    try {
      final data = await ApiServer.call(myQuery);
      final meData = data['me'];
      if (meData != null) {
        return Map<String, dynamic>.from(meData);
      }
      throw const GqlException("User profile not found or session expired");
    } on GqlException catch (e) {
      if (e.message == "Authorization error") {
        await ApiServer.clearAuthToken();
      }
      rethrow;
    } catch (e) {
      throw GqlException("Network error: Please check your connection.");
    }
  }

  Future<Map<String, dynamic>> fetchRooms(String userId) async {
    try {
      final data = await ApiServer.call(
        roomsQuery,
        variables: {"userId": userId},
      );
      final rooms = data['rooms'];
      if (rooms != null) {
        return data;
      }
      throw const GqlException("Rooms data not found");
    } on GqlException catch (e) {
      if (e.message == "Authorization error") {
        await ApiServer.clearAuthToken();
      }
      rethrow;
    } catch (e) {
      throw GqlException("Network error: Please check your connection.");
    }
  }
}
