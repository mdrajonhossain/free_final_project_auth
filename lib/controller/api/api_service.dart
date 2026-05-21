import 'dart:async';
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

  /// Generates or retrieves a unique signaling token for this device session,
  /// matching the 'getXmppToken' behavior in React.js.
  static Future<String> getSignalingToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? sigToken = prefs.getString("signaling_token");
    if (sigToken == null || sigToken.isEmpty) {
      sigToken =
          DateTime.now().millisecondsSinceEpoch.toRadixString(36) +
          DateTime.now().microsecondsSinceEpoch.toRadixString(36);
      await prefs.setString("signaling_token", sigToken);
    }
    return sigToken;
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
            ((errors.first as Map)['message'] as String?) ??
            'GraphQL error (no message)';
        print('[GQL ERROR] op=$operationName msg=$msg');
        throw GqlException(msg);
      }

      final data = (body['data'] as Map?)?.cast<String, dynamic>() ?? {};
      debugPrint('[GQL OK] op=$operationName keys=${data.keys.toList()}');
      return data;
    } on GqlException catch (e) {
      // Centralized Auth Error Handling
      if (e.message == "Authorization error" ||
          e.message.contains("Unauthorized")) {
        await ApiServer.clearAuthToken();
      }
      rethrow;
    } on DioException catch (e) {
      debugPrint(
        '[DIO ERROR] op=$operationName status=${e.response?.statusCode} data=${e.response?.data}',
      );
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
      // Use the existing call helper for login too
      final data = await ApiServer.call(loginMutation, variables: variables);
      final loginData = data['login'];

      if (loginData != null && loginData['status'] == true) {
        final String? token = loginData['token'];
        if (token != null && token.isNotEmpty) {
          await ApiServer.setAuthToken(token); // Store the token
        }
        return Map<String, dynamic>.from(loginData);
      } else {
        throw GqlException(loginData?['message'] ?? "Login failed");
      }
    } on GqlException {
      rethrow;
    } catch (e) {
      throw GqlException(e.toString());
    }
  }

  // ================= meapi==========================================
  Future<Map<String, dynamic>> fetchMe() async {
    try {
      final data = await ApiServer.call(myQuery);
      final dynamic meData = data['me'];
      if (meData is Map) {
        return meData.cast<String, dynamic>();
      }
      throw const GqlException("User profile not found or session expired");
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
      final dynamic tagsData = data['tags'];
      final List publicTags =
          (tagsData is Map ? tagsData['public'] : null) ?? [];
      return publicTags
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
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
      final dynamic messages = data['messages'];
      if (messages != null && messages is Map) {
        return Map<String, dynamic>.from(messages);
      }
      throw const GqlException("Messages data not found");
    } catch (e) {
      throw GqlException("Network error: Please check your connection.");
    }
  }

  // ==========================get_tag_gallery==============================
  Future<Map<String, dynamic>> get_tag_gallery({
    int page = 1,
    String? tagId,
    String tab = "tag",
  }) async {
    try {
      final data = await ApiServer.call(
        Get_file_galleryQuery,
        variables: {
          "conversation_id": "all_files",
          "conversation_ids": null,
          "uploaded_by": null,
          "file_type": "all",
          "file_sub_type": tagId != null ? "tag" : "all",
          "tag_id": tagId != null ? [tagId] : null,
          "tag_operator": null,
          "file_name": "",
          "from": null,
          "to": null,
          "page": page,
          "tab": tab,
          "selectedFilters": "date_- Descending",
        },
      );
      final galleryData = data['get_file_gallery'];
      if (galleryData != null) {
        print("[API] get_tag_gallery: success");
        return Map<String, dynamic>.from(galleryData);
      }
      throw const GqlException("File gallery data not found");
    } catch (e) {
      print("[API ERROR] get_tag_gallery: $e");
      throw GqlException("Failed to fetch gallery: ${e.toString()}");
    }
  }

  // ==================End

  // ==========================get_File_gallery==============================
  Future<Map<String, dynamic>> get_file_gallery({
    String conversationId = "all_files",
    String fileType = "all",
    String fileSubType = "all",
    String? tagId,
    String? uploadedBy,
    String? tagOperator,
    String fileName = "",
    String? from,
    String? to,
    int page = 1,
    String tab = "file",
    String selectedFilters = "date_- Descending",
  }) async {
    try {
      final data = await ApiServer.call(
        Get_file_galleryQuery,
        variables: {
          "conversation_id": conversationId,
          "conversation_ids": null,
          "uploaded_by": uploadedBy,
          "file_type": fileType,
          "file_sub_type": fileSubType,
          "tag_id": tagId != null ? [tagId] : null,
          "tag_operator": tagOperator,
          "file_name": fileName,
          "from": from,
          "to": to,
          "page": page,
          "tab": tab,
          "selectedFilters": selectedFilters,
        },
      );
      final galleryData = data['get_file_gallery'];
      if (galleryData != null) {
        print("[API] get_file_gallery: success");
        return Map<String, dynamic>.from(galleryData);
      }
      throw const GqlException("File gallery data not found");
    } catch (e) {
      print("[API ERROR] get_file_gallery: $e");
      throw GqlException("Failed to fetch gallery: ${e.toString()}");
    }
  }

  // ==================End

  // ==========================get_files_by_tag==============================
  Future<Map<String, dynamic>?> getFilesByTag(
    String tagId, {
    String conversationId = "all_files",
    String fileType = "all",
    String fileSubType = "tag",
    String fileName = "",
    int page = 1,
    String tab = "tag_file",
    String selectedFilters = "date_- Descending",
    String? uploadedBy,
    String? tagOperator,
    String? from,
    String? to,
  }) async {
    try {
      final data = await ApiServer.call(
        Get_file_galleryQuery,
        variables: {
          "conversation_id": conversationId,
          "conversation_ids": null,
          "uploaded_by": uploadedBy,
          "file_type": fileType,
          "file_sub_type": fileSubType,
          "tag_id": tagId is List ? tagId : [tagId],
          "tag_operator": tagOperator,
          "file_name": fileName,
          "from": from,
          "to": to,
          "page": page,
          "tab": tab,
          "selectedFilters": selectedFilters,
        },
      );
      final galleryData = data['get_file_gallery'];
      if (galleryData != null) {
        return Map<String, dynamic>.from(galleryData);
      }
      return null;
    } catch (e) {
      print("[API ERROR] getFilesByTag: $e");
      return null;
    }
  }

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

      final dynamic result = data['send_msg'];

      if (result != null && result is Map && result['msg'] is Map) {
        // unawaited from dart:async marks that we don't need to wait for the refresh to finish
        unawaited(fetchRooms(senderId));
        return Map<String, dynamic>.from(result['msg']);
      }

      throw const GqlException("Failed to send message: Empty response");
    } catch (e) {
      throw GqlException("Network error: Please check your connection.");
    }
  }

  Future<Map<String, dynamic>> editMessage({
    required String conversationId,
    required String msgId,
    required String newMsgBody,
    String isReply = "no",
  }) async {
    try {
      final variables = {
        "input": {
          "conversation_id": conversationId,
          "msg_id": msgId,
          "new_msg_body": newMsgBody,
          "is_reply": isReply,
        },
      };

      final data = await ApiServer.call(
        editMessageMutation,
        variables: variables,
      );
      final result = data['edit_msg'];
      if (result != null && result['status'] == true && result['msg'] is Map) {
        return Map<String, dynamic>.from(result['msg']);
      }
      // Log the exact reason for failure from the server response
      final String serverMessage =
          result?['message']?.toString() ?? 'Unknown server response';
      print(
        '[API ERROR] editMessage failed: Status=${result?['status']}, Msg=${result?['msg']}, ServerMessage=$serverMessage',
      );
      throw GqlException("Failed to edit message: $serverMessage");
    } catch (e) {
      print('[API ERROR] editMessage caught exception: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteMessage({
    required String conversationId,
    required String msgId,
    required String deleteType,
    required String isReplyMsg,
    required List<String> participants,
  }) async {
    try {
      final variables = {
        "input": {
          "conversation_id": conversationId,
          "msg_id": msgId,
          "delete_type": deleteType,
          "is_reply_msg": isReplyMsg,
          "participants": participants,
        },
      };

      final data = await ApiServer.call(
        deleteMessageMutation,
        variables: variables,
      );
      final result = data['delete_msg'];
      if (result != null && result['status'] == true) {
        return Map<String, dynamic>.from(result);
      }
      // Extract actual server message for GqlException
      final String serverMessage =
          result?['message']?.toString() ?? 'Unknown server response';
      print('[API ERROR] deleteMessage failed: $serverMessage');
      throw GqlException("Failed to delete message: $serverMessage");
    } catch (e) {
      rethrow;
    }
  }

  // ===================Start Call history api===========================
  Future<List<Map<String, dynamic>>> fetchCallHistory(
    String? userId, {
    String? companyId,
  }) async {
    try {
      final data = await ApiServer.call(
        callHistoryGroup,
        variables: {
          "user_id": userId,
          if (companyId != null) "company_id": companyId,
        },
      );
      final dynamic group = data['call_history_group'];
      final List history = (group is Map ? group['history_group'] : null) ?? [];
      return history
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      throw GqlException("Failed to fetch call history: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>?> jitsiCallAccept_Call(
    String? userId,
    String? companyId,
    String? conversationId,
    String? token, {
    String? conversation_type,
    List<dynamic>? participantsAll,
    List<dynamic>? participantsAdmin,
    List<dynamic>? arrParticipants,
    String? convname,
    String? callLink,
    String? callOption = "mobile",
    int? expireUnix,
  }) async {
    try {
      final data = await ApiServer.call(
        jitsiRingCallingQuery,
        variables: {
          'user_id': userId,
          'conversation_id': conversationId,
          'company_id': companyId,
          'token': token,
          'conversation_type': conversation_type,
          if (participantsAll != null) 'participants_all': participantsAll,
          if (participantsAdmin != null)
            'participants_admin': participantsAdmin,
          if (arrParticipants != null) 'arr_participants': arrParticipants,
          if (convname != null) 'convname': convname,
          if (callLink != null) 'call_link': callLink,
          if (callOption != null) 'call_option': callOption,
          if (expireUnix != null) 'expire_unix': expireUnix,
        },
      );
      final result = data['jitsi_ring_calling'] as Map<String, dynamic>?;
      return result;
    } catch (e) {
      throw GqlException("Failed to accept Jitsi call: ${e.toString()}");
    }
  }

  /// Fetches conference metadata and JWT, matching React's 'getRingUser' logic.
  Future<Map<String, dynamic>?> jitsi_ring_users({
    required String userId,
    required String conversationId,
    required String token,
  }) async {
    try {
      final data = await ApiServer.call(
        r'''
        query JitsiRingUsers($user_id: String, $conversation_id: String, $token: String) {
          jitsi_ring_users(user_id: $user_id, conversation_id: $conversation_id, token: $token) {
            status
            jwt_token
            msg
            voip_conv {
              room_name
              conversation_type
              participants_all
              participants_admin
              convname
            }
          }
        }
        ''',
        variables: {
          'user_id': userId,
          'conversation_id': conversationId,
          'token': token,
        },
      );
      final dynamic result = data['jitsi_ring_users'];
      return result is Map ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      throw GqlException("Failed to fetch Jitsi session: ${e.toString()}");
    }
  }

  Future<void> jitsiCallJoin_Call({
    required String userId,
    required String conversationId,
    required String token,
  }) async {
    try {
      await ApiServer.call(
        r'''
        mutation JitsiJoinCalling($user_id: String, $conversation_id: String, $token: String) {
          jitsi_join_calling(user_id: $user_id, conversation_id: $conversation_id, token: $token) {
            status
            message
          }
        }
        ''',
        variables: {
          'user_id': userId,
          'conversation_id': conversationId,
          'token': token,
        },
      );
    } catch (e) {
      throw GqlException("Failed to join Jitsi call: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>> forwardMessage({
    required String originalConversationId,
    required String msgId,
    required String isReplyMsg,
    required List<String> targetConversationIds,
  }) async {
    try {
      final variables = {
        "conversation_id": originalConversationId,
        "msg_id": msgId,
        "is_reply_msg": isReplyMsg,
        "conversation_lists": targetConversationIds,
      };

      final data = await ApiServer.call(forwardMutation, variables: variables);

      final result = data['forward'];
      if (result != null && result is Map) {
        return Map<String, dynamic>.from(result);
      }
      throw const GqlException("Failed to forward message: Empty response");
    } catch (e) {
      throw GqlException(
        "Network error: Please check your connection. ${e.toString()}",
      );
    }
  }
  // =================== End Call history api===========================

  // ===================== Start Filehubs Links ========================
  Future<List<Map<String, dynamic>>> fetchFilehubs_Link() async {
    try {
      // The original query had 'conversation_ids: nul', which is not valid GraphQL.
      // Assuming the intention was to pass an empty list or null,
      // and the new query explicitly defines it as `[String!]`.
      // Defaulting to an empty list for conversation_ids and other common filters.
      final variables = {
        "conversation_ids": [],
        "sort_by": "created_at",
        "sort_style": "-1",
        // Add other variables as needed, e.g.,
        // "from": null,
        // "to": null,
        // "url": null,
        // "user_ids": null,
        // "page": 1,
        // "timezone": null,
      };

      final data = await ApiServer.call(filehubs_Links, variables: variables);
      final List<dynamic> history = data['hub_all_link_msgs']?['links'] ?? [];
      return List<Map<String, dynamic>>.from(history);
    } catch (e) {
      throw GqlException("Failed to fetch filehubs links: ${e.toString()}");
    }
  }

  // ===================== End Filehubs Links ========================

  /// Marks all messages in a conversation as read on the server.
  Future<Map<String, dynamic>> markAsRead(String conversationId) async {
    try {
      final data = await ApiServer.call(
        r'''
        mutation MarkAsRead($conversation_id: String) {
          mark_as_read(conversation_id: $conversation_id) {
            status
            message
          }
        }
        ''',
        variables: {"conversation_id": conversationId},
      );
      final result = data['mark_as_read'];
      return result is Map ? Map<String, dynamic>.from(result) : {};
    } catch (e) {
      debugPrint("[API ERROR] markAsRead: $e");
      return {"status": false, "message": e.toString()};
    }
  }

  /// Rejects an incoming call.
  Future<void> rejectCall({
    required String userId,
    required String conversationId,
    required String token,
  }) async {
    try {
      await ApiServer.call(
        r'''
        query JitsiCallReject($user_id: String, $conversation_id: String, $token: String, $type: String) {
          jitsi_call_reject(user_id: $user_id, conversation_id: $conversation_id, token: $token, type: $type) {
            status
            message
          }
        }
        ''',
        variables: {
          'user_id': userId,
          'conversation_id': conversationId,
          'token': token,
          'type': 'reject',
        },
      );
    } catch (e) {
      debugPrint("[API ERROR] rejectCall: $e");
    }
  }

  Future<Map<String, dynamic>> addRemoveTagIntoFile({
    required String conversationId,
    required String msgId,
    required String fileId, // Ensure fileId is passed here
    required List<String> newTags, // List of new tag IDs
    required List<Map<String, dynamic>> newTagData, // List of new tag objects
    required List<String> removetag, // List of tag IDs to remove
    required List<Map<String, dynamic>>
    removetagData, // List of tag objects to remove
    required List<String> participants,
    String isReply = "no",
  }) async {
    try {
      final variables = {
        // Wrap all fields under a single 'input' key
        "input": {
          "conversation_id": conversationId,
          "file_id": fileId,
          "is_reply": isReply,
          "msg_id": msgId,
          "newtag": newTags,
          "newtag_tag_data":
              newTagData, // Pass directly as List<Map<String, dynamic>>
          "removetag": removetag,
          "removetag_tag_data":
              removetagData, // Pass directly as List<Map<String, dynamic>>
          "participants": participants,
        },
      };
      final data = await ApiServer.call(
        AddRemove_Tag_Into_File,
        variables: variables,
      );
      return Map<String, dynamic>.from(data['add_remove_tag_into_file'] ?? {});
    } catch (e) {
      throw GqlException("Failed to update tags: ${e.toString()}");
    }
  }

  // ======================== End add removetag public ===================================

  Future<Map<String, dynamic>> toggleFileStar({required String fileId}) async {
    try {
      final variables = {
        "input": {"file_id": fileId, "is_reply_msg": "no"},
      };
      final data = await ApiServer.call(FileStarMutation, variables: variables);
      print("4444444444444444444444444, $data");
      return Map<String, dynamic>.from(data['file_star'] ?? {});
    } catch (e) {
      throw GqlException("Failed to update star: ${e.toString()}");
    }
  }
}
