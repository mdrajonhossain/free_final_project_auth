import 'dart:convert';
import 'package:dio/dio.dart'; // Import Dio
import 'package:flutter/foundation.dart';
import 'package:freeli/model/modelScreema_quary.dart';
import '../../model/modelScreema_mutation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gql_exception.dart';
import '../../config/config.dart';

class ApiServer {
  // Singleton instance
  static final ApiServer _instance = ApiServer._internal();
  factory ApiServer() => _instance;
  ApiServer._internal();

  static final Dio _dio = Dio();
  static String? _token;
  // static const String _graphqlUrl = "http://62.151.182.241:4055/workfreeli";
  static const String _graphqlUrl = AppConfig.baseUrl + "/workfreeli";

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

  // ======================== start tag public ===================================
  Future<List<Map<String, dynamic>>> fetch_Public_Tags(
    String? companyId,
  ) async {
    try {
      final data = await ApiServer.call(
        Get_tag_public,
        variables: {"company_id": companyId},
      );
      final List<dynamic> publicTags = data['tags']?['public'] ?? [];
      return List<Map<String, dynamic>>.from(publicTags);
    } on GqlException catch (e) {
      if (e.message == "Authorization error") {
        await ApiServer.clearAuthToken();
      }

      rethrow;
    } catch (e) {
      throw GqlException("Failed to fetch public tags: ${e.toString()}");
    }
  }
  // ======================== End tag public ===================================

  Future<Map<String, dynamic>> fetchAllLink() async {
    try {
      final data = await ApiServer.call(
        """query GetAllLinks { get_file_gallery(tab: "link") { items { id title location } } }""",
      );
      return Map<String, dynamic>.from(data['get_file_gallery'] ?? {});
    } catch (e) {
      throw GqlException("Failed to fetch links");
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

  Future<Map<String, dynamic>> fetchMessages(
    String conversationId, {
    int page = 1,
    String? userId,
  }) async {
    try {
      final data = await ApiServer.call(
        messagesQuery,
        variables: {"conversationId": conversationId, "page": page},
      );
      final messages = data['messages'];
      if (messages != null) {
        return Map<String, dynamic>.from(messages);
      }
      throw const GqlException("Messages data not found");
    } on GqlException catch (e) {
      if (e.message == "Authorization error") {
        await ApiServer.clearAuthToken();
      }
      rethrow;
    } catch (e) {
      throw GqlException("Network error: Please check your connection.");
    }
  }

  // ==========================get_tag_gallery==============================
  Future<Map<String, dynamic>> get_tag_gallery() async {
    try {
      final data = await ApiServer.call(
        Get_file_galleryQuery,
        variables: {
          "conversation_ids": null,
          "file_type": "all",
          "tab": "tag",
          "tag_id": ["tag"],
          "conversation_id": null,
        },
      );
      final galleryData = data['get_file_gallery'];
      if (galleryData != null) {
        print("[API] get_tag_gallery: success");
        return Map<String, dynamic>.from(galleryData);
      }
      throw const GqlException("File gallery data not found");
    } on GqlException catch (e) {
      if (e.message == "Authorization error") {
        await ApiServer.clearAuthToken();
      }
      rethrow;
    } catch (e) {
      print("[API ERROR] get_tag_gallery: $e");
      throw GqlException("Failed to fetch gallery: ${e.toString()}");
    }
  }

  // ==================End

  // ==========================get_File_gallery==============================
  Future<Map<String, dynamic>> get_file_gallery() async {
    try {
      final data = await ApiServer.call(
        Get_file_galleryQuery,
        variables: {
          "conversation_ids": null,
          "file_type": "all",
          "tab": "file",
          "tag_id": ["file"],
          "conversation_id": null,
        },
      );
      final galleryData = data['get_file_gallery'];
      if (galleryData != null) {
        print("[API] get_file_gallery: success");
        return Map<String, dynamic>.from(galleryData);
      }
      throw const GqlException("File gallery data not found");
    } on GqlException catch (e) {
      if (e.message == "Authorization error") {
        await ApiServer.clearAuthToken();
      }
      rethrow;
    } catch (e) {
      print("[API ERROR] get_file_gallery: $e");
      throw GqlException("Failed to fetch gallery: ${e.toString()}");
    }
  }

  // ==================End

  Future<Map<String, dynamic>> sendMessage({
    required String msgBody,
    required String conversationId,
    required String companyId,
    required String senderId,
    required List<String> participants,
    String msgType = "text",
    bool flagged = false,
    String isReplyMsg = "no",
    Map<String, dynamic>? attachFiles,
    List<String>? tags,
    List<Map<String, dynamic>>? allAttachment,
  }) async {
    try {
      final variables = {
        "input": {
          "conversation_id": conversationId,
          "company_id": companyId,
          "sender": senderId,
          "msg_type": msgType,
          "msg_body": msgBody,
          "participants": participants,
          "is_reply_msg": isReplyMsg,
          "flagged": flagged,
          "referenceId": "",
          "reference_type": "",
          "reply_for_msgid": "",
          "is_secret": false,
          if (tags != null && tags.isNotEmpty) "tag_list": tags,
          if (attachFiles != null) "attach_files": attachFiles,
          if (allAttachment != null && allAttachment.isNotEmpty)
            "all_attachment": allAttachment,
        },
      };

      final data = await ApiServer.call(
        sendMessageMutation,
        variables: variables,
      );

      final result = data['send_msg'];

      if (result != null && result['msg'] != null) {
        fetchRooms(senderId);
        return Map<String, dynamic>.from(result['msg']);
      }

      throw const GqlException("Failed to send message: Empty response");
    } on GqlException catch (e) {
      if (e.message == "Authorization error") {
        await ApiServer.clearAuthToken();
      }
      rethrow;
    } catch (e) {
      throw GqlException("Network error: Please check your connection.");
    }
  }

  // ===================Start Call history api===========================
  Future<List<Map<String, dynamic>>> fetchCallHistory(String? userId) async {
    try {
      final data = await ApiServer.call(
        callHistoryGroup,
        variables: {"user_id": userId},
      );
      final List<dynamic> history =
          data['call_history_group']?['history_group'] ?? [];
      return List<Map<String, dynamic>>.from(history);
    } on GqlException catch (e) {
      if (e.message == "Authorization error") {
        await ApiServer.clearAuthToken();
      }
      rethrow;
    } catch (e) {
      throw GqlException("Failed to fetch call history: ${e.toString()}");
    }
  }

  Future<String?> jitsiCallAccept_Call(
    String? userId,
    String? conversationId,
    String? token,
  ) async {
    try {
      final data = await ApiServer.call(
        jitsiCallAcceptdata,
        variables: {
          'user_id': userId,
          'conversation_id': conversationId,
          'token': token,
          'type': 'accept',
          'device_type': 'mobile',
        },
      );
      final result = data['jitsi_call_accept'] as Map<String, dynamic>?;
      return result?['jwt_token']?.toString();
    } on GqlException catch (e) {
      if (e.message == "Authorization error") {
        await ApiServer.clearAuthToken();
      }
      rethrow;
    } catch (e) {
      throw GqlException("Failed to accept Jitsi call: ${e.toString()}");
    }
  }

  // =================== End Call history api===========================
}
