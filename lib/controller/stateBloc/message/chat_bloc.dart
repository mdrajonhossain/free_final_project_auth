import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/connect/crypto_utils.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:freeli/controller/api/xmpp_server.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiServer apiServer = ApiServer();

  ChatBloc() : super(ChatState()) {
    on<ChatFetchRequested>(_onFetchRequested);
    on<ChatLoadMoreRequested>(_onLoadMoreRequested);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatXmppMessageReceived>(_onXmppMessageReceived);
  }

  Future<void> _onFetchRequested(
    ChatFetchRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        currentPage: 1,
        hasMore: true,
        messages: [], // Clear messages when fetching a new conversation
        activeConversationId: event.conversationId,
      ),
    );
    try {
      Map<String, dynamic>? userData = state.userData;
      String myId = state.myId;

      if (myId.isEmpty) {
        userData = await apiServer.fetchMe();
        myId = userData?['id']?.toString() ?? "";
      }

      final data = await apiServer.fetchMessages(
        event.conversationId,
        page: 1,
        userId: myId,
      );
      final List messages = (data['msgs'] as List?)?.reversed.toList() ?? [];

      emit(
        state.copyWith(
          messages: messages,
          isLoading: false,
          myId: myId,
          userData: userData,
          hasMore: messages.isNotEmpty,
          activeConversationId: event.conversationId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadMoreRequested(
    ChatLoadMoreRequested event,
    Emitter<ChatState> emit,
  ) async {
    if (state.isFetchingMore || !state.hasMore) return;

    emit(state.copyWith(isFetchingMore: true));
    try {
      final nextPage = state.currentPage + 1;
      final data = await apiServer.fetchMessages(
        event.conversationId,
        page: nextPage,
      );
      final List newMsgs = (data['msgs'] as List?)?.reversed.toList() ?? [];

      emit(
        state.copyWith(
          messages: [...state.messages, ...newMsgs],
          isFetchingMore: false,
          currentPage: nextPage,
          hasMore: newMsgs.isNotEmpty,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isFetchingMore: false));
    }
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final encryptedText = CryptoUtils.encryptMessage(event.text);
    final String tempId = "temp_${DateTime.now().millisecondsSinceEpoch}";

    final optimisticMessage = {
      "msg_id": tempId,
      "sender": state.myId,
      "sendername":
          "${state.userData?['firstname'] ?? 'Me'} ${state.userData?['lastname'] ?? ''}"
              .trim(),
      "senderimg":
          state.userData?['img'] ??
          "https://wfss001.freeli.io/profile-pic/Photos/corporate-company-logo-png_seeklogo-425925@1764655943904.png",
      "msg_body": encryptedText,
      "created_at": DateTime.now().toIso8601String(),
      "all_attachment": event.attachFiles?['allfiles'] ?? [],
    };

    // 1. Optimistic Update: Add message to list immediately
    final updatedMessages = [optimisticMessage, ...state.messages];
    // Clear previous error state so the UI doesn't show a stale failure notification
    emit(state.copyWith(messages: updatedMessages, error: null));

    try {
      // 2. Network Call
      final response = await apiServer.sendMessage(
        msgBody: event.msgType == "text" ? encryptedText : event.text,
        conversationId: event.conversationId,
        companyId: event.companyId,
        senderId: state.myId,
        participants: event.participants is List
            ? List<String>.from(event.participants)
            : [event.participants.toString()],
        msgType: event.msgType,
        attachFiles: event.attachFiles,
        tags: event.tags,
        allAttachment: event.allAttachment,
      );

      if (response == null) throw Exception("Empty response from server");

      // 3. Update State: Replace optimistic message with real server response
      final List finalMessages = state.messages
          .map((m) => m['msg_id'] == tempId ? response : m)
          .toList();

      emit(state.copyWith(messages: finalMessages, error: null));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onXmppMessageReceived(
    ChatXmppMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    try {
      if (event.message == null || event.message is! Map) return;

      // The message is already normalized into a Map in the HomePage XMPP listener
      Map<String, dynamic> msgMap;
      msgMap = Map<String, dynamic>.from(event.message as Map);

      // 2. Filter: Only process chat messages or explicit 'new_message' events for the current active room
      final String type = (msgMap['msg_type'] ?? msgMap['type'] ?? 'chat')
          .toString();
      final bool isChatMessage =
          type == 'chat' || type == 'new_message' || type == 'text';

      if (!isChatMessage) return;

      final String? incomingConvId = msgMap['conversation_id']?.toString();
      final String? activeConvId = state.activeConversationId?.toString();

      // Strict filtering: Only accept messages that belong to the active room
      if (activeConvId == null || incomingConvId != activeConvId) return;

      // 3. Prevent duplicates and ignore self-messages (handled by optimistic UI)
      if (msgMap['sender'] == state.myId) return;
      if (state.messages.any((m) => m['msg_id'] == msgMap['msg_id'])) return;

      // Normalize sender data from XMPP notification keys
      msgMap['sender'] = msgMap['sender'] ?? msgMap['created_by_id'];
      if (msgMap['created_by_name'] != null) {
        msgMap['sendername'] = msgMap['created_by_name'];
      }
      if (msgMap['created_by_img'] != null) {
        msgMap['senderimg'] = msgMap['created_by_img'];
      }

      // 4. Decrypt body if it's an encrypted message
      final String rawBody = (msgMap['msg_body'] ?? msgMap['body'] ?? "")
          .toString();

      if (rawBody.isNotEmpty) {
        final String trimmedBody = rawBody.trim();
        // Detect if the body is a JSON object or list (XMPP file metadata)
        if (trimmedBody.startsWith('{') || trimmedBody.startsWith('[')) {
          try {
            final dynamic decoded = jsonDecode(trimmedBody);
            final List listData = decoded is List
                ? decoded
                : (decoded != null ? [decoded] : []);

            // Process each attachment and construct the specific URL format
            final List
            processedAttachments = listData.where((item) => item is Map).map((
              item,
            ) {
              final Map<String, dynamic> file = Map<String, dynamic>.from(item);
              final String bucket = (file['bucket'] ?? "").toString();
              final String originalname = (file['originalname'] ?? "")
                  .toString();
              // Build URL: https://wfss001.freeli.io/{bucket}/{originalname}
              file['location'] =
                  "https://wfss001.freeli.io/$bucket/$originalname";
              return file;
            }).toList();

            msgMap['all_attachment'] = processedAttachments;
            msgMap['msg_body'] = ""; // Hide JSON string from user UI
          } catch (e) {
            print('❌ JSON parse failed in Bloc: $e');
            // Fallback decryption if it wasn't actually file JSON
            _attemptDecryption(msgMap, rawBody);
          }
        } else {
          _attemptDecryption(msgMap, rawBody);
        }
      }

      final updatedMessages = [msgMap, ...state.messages];
      emit(state.copyWith(messages: updatedMessages));
    } catch (e, stack) {
      print('❌ Fatal error in _onXmppMessageReceived: $e');
      print(stack);
      // Catching all errors here prevents the entire Bloc from crashing
    }
  }

  // Helper to attempt decryption and handle nested file metadata
  void _attemptDecryption(Map<String, dynamic> msgMap, String body) {
    try {
      final String decrypted = CryptoUtils.decryptMessage(body);
      msgMap['msg_body'] = decrypted;

      // After decryption, check if the content is technical file metadata (JSON)
      final String trimmedDecrypted = decrypted.trim();
      if (trimmedDecrypted.startsWith('{') ||
          trimmedDecrypted.startsWith('[')) {
        _processJsonBody(msgMap, trimmedDecrypted);
      }
    } catch (e) {
      // If not encrypted, check if it's already JSON
      if (body.trim().startsWith('{') || body.trim().startsWith('[')) {
        _processJsonBody(msgMap, body);
      } else {
        msgMap['msg_body'] = body;
      }
    }
  }

  // Centralized logic to parse JSON body and construct the specific XMPP file URL
  void _processJsonBody(Map<String, dynamic> msgMap, String jsonStr) {
    try {
      final dynamic decoded = jsonDecode(jsonStr);
      final List listData = decoded is List
          ? decoded
          : (decoded != null ? [decoded] : []);

      // Build URL format: https://wfss001.freeli.io/{bucket}/{originalname}
      final List processedAttachments = listData
          .where((item) => item is Map)
          .map((item) {
            final Map<String, dynamic> file = Map<String, dynamic>.from(item);
            final String bucket = (file['bucket'] ?? "").toString();
            final String originalname = (file['originalname'] ?? "").toString();
            file['location'] =
                "https://wfss001.freeli.io/$bucket/$originalname";
            return file;
          })
          .toList();

      final List existingAttachments = msgMap['all_attachment'] is List
          ? msgMap['all_attachment']
          : [];

      msgMap['all_attachment'] = [
        ...existingAttachments,
        ...(processedAttachments ?? []),
      ];
      msgMap['msg_body'] =
          ""; // Technical JSON data ইউজারকে টেক্সট হিসেবে দেখাবে না
    } catch (e) {
      // If it looks like technical data but fails to parse, hide the text
      if (jsonStr.contains('"originalname"')) msgMap['msg_body'] = "";
    }
  }
}
