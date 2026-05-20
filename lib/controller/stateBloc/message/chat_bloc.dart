import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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
    on<ChatMessageEdited>(_onMessageEdited);
    on<ChatMessageDeleted>(_onMessageDeleted);
    on<ChatMessageTagsUpdated>(_onMessageTagsUpdated); // Add this handler
    on<ChatFileStarred>(_onFileStarred);
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

  Future<void> _onMessageEdited(
    ChatMessageEdited event,
    Emitter<ChatState> emit,
  ) async {
    // 1. Optimistic Update: Use indexWhere for precise replacement in the local list
    final List updatedMessages = List.from(state.messages);
    final int index = updatedMessages.indexWhere(
      (m) => (m['msg_id'] ?? m['id']).toString() == event.msgId,
    );

    if (index != -1) {
      final updated = Map<String, dynamic>.from(updatedMessages[index]);
      // Encrypt body immediately for a consistent internal state
      updated['msg_body'] = CryptoUtils.encryptMessage(event.newText);
      updated['edit_status'] = true;
      updatedMessages[index] = updated;
      emit(state.copyWith(messages: updatedMessages, error: null));
    }

    try {
      // 2. Network Call
      final response = await apiServer.editMessage(
        conversationId: event.conversationId,
        msgId: event.msgId,
        newMsgBody: CryptoUtils.encryptMessage(event.newText),
      );

      // 3. Final Sync: Replace the message with the full server response object
      final List syncedMessages = state.messages.map((m) {
        final String currentId = (m['msg_id'] ?? m['id']).toString();
        if (currentId == event.msgId) {
          return response;
        }
        return m;
      }).toList();

      emit(state.copyWith(messages: syncedMessages, error: null));
      event.onSuccess?.call(); // Call the success callback
    } catch (e) {
      print('[ChatBloc] Error editing message: $e');
      event.onError?.call(e); // Call the error callback with the error object
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onMessageDeleted(
    ChatMessageDeleted event,
    Emitter<ChatState> emit,
  ) async {
    final List updatedMessages = List.from(state.messages);
    final int index = updatedMessages.indexWhere(
      (m) => (m['msg_id'] ?? m['id']).toString() == event.msgId,
    );

    if (index != -1) {
      // Optimistic update: Remove message from list immediately
      updatedMessages.removeAt(index);
      emit(state.copyWith(messages: updatedMessages, error: null));
    }

    try {
      // Network Call
      final response = await apiServer.deleteMessage(
        conversationId: event.conversationId,
        msgId: event.msgId,
        deleteType: event.deleteType,
        isReplyMsg: event.isReplyMsg,
        participants: event.participants,
      );

      if (response['status'] == true) {
        event.onSuccess?.call();
      }
    } catch (e) {
      event.onError?.call(e);
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onMessageTagsUpdated(
    ChatMessageTagsUpdated event,
    Emitter<ChatState> emit,
  ) async {
    final List<Map<String, dynamic>> updatedMessages = List.from(
      state.messages,
    );
    final int msgIndex = updatedMessages.indexWhere(
      (m) => (m['msg_id'] ?? m['id']).toString() == event.msgId,
    );

    if (msgIndex != -1) {
      final Map<String, dynamic> messageToUpdate = Map.from(
        updatedMessages[msgIndex],
      );
      List<dynamic> allAttachments = List.from(
        messageToUpdate['all_attachment'] ?? [],
      );

      final int fileIndex = allAttachments.indexWhere(
        (file) => file['id']?.toString() == event.fileId,
      );

      if (fileIndex != -1) {
        final Map<String, dynamic> fileToUpdate = Map.from(
          allAttachments[fileIndex],
        );
        fileToUpdate['tag_list'] = event.newTagIds; // Update with new tag IDs
        // Assuming tag_list_details is where full tag objects are stored
        fileToUpdate['tag_list_details'] = event.newTagDetails;
        allAttachments[fileIndex] = fileToUpdate;
        messageToUpdate['all_attachment'] = allAttachments;
        updatedMessages[msgIndex] = messageToUpdate;
        // Emit a new state to trigger UI rebuild
        emit(state.copyWith(messages: updatedMessages));
        event.onSuccess?.call();
      } else {
        event.onError?.call("File not found in message attachments.");
      }
    } else {
      event.onError?.call("Message not found.");
    }
  }

  Future<void> _onFileStarred(
    ChatFileStarred event,
    Emitter<ChatState> emit,
  ) async {
    final List<dynamic> updatedMessages = List.from(state.messages);
    final int msgIndex = updatedMessages.indexWhere(
      (m) => (m['msg_id'] ?? m['id']).toString() == event.msgId,
    );

    if (msgIndex != -1) {
      final Map<String, dynamic> messageToUpdate = Map.from(
        updatedMessages[msgIndex],
      );
      List<dynamic> allAttachments = List.from(
        messageToUpdate['all_attachment'] ?? [],
      );

      final int fileIndex = allAttachments.indexWhere(
        (file) => file['id']?.toString() == event.fileId,
      );

      if (fileIndex != -1) {
        final Map<String, dynamic> fileToUpdate = Map.from(
          allAttachments[fileIndex],
        );
        fileToUpdate['star'] = event.star;
        allAttachments[fileIndex] = fileToUpdate;
        messageToUpdate['all_attachment'] = allAttachments;
        updatedMessages[msgIndex] = messageToUpdate;
        emit(state.copyWith(messages: updatedMessages));
      }
    }
  }

  void _onXmppMessageReceived(
    ChatXmppMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    try {
      if (event.message == null || event.message is! Map) return;

      Map<String, dynamic> msgMap = Map<String, dynamic>.from(event.message);

      // 1. Basic Filtering (Type and Conversation)
      // Handle deletion specifically if XMPP sends a 'delete_msg' type
      final String incomingMsgType =
          (msgMap['msg_type'] ?? msgMap['type'] ?? 'chat').toString();
      if (incomingMsgType == 'delete_msg') {
        final String deletedMsgId = (msgMap['msg_id'] ?? msgMap['id'] ?? "")
            .toString();
        if (deletedMsgId.isNotEmpty) {
          final List currentMessages = List.from(state.messages);
          final int deletedIndex = currentMessages.indexWhere(
            (m) => (m['msg_id'] ?? m['id']).toString() == deletedMsgId,
          );
          if (deletedIndex != -1) {
            currentMessages.removeAt(deletedIndex);
            emit(state.copyWith(messages: currentMessages));
            return; // Message deleted, no further processing needed for this XMPP message
          }
        }
      }
      final String type = (msgMap['msg_type'] ?? msgMap['type'] ?? 'chat')
          .toString();
      final bool isChatMessage =
          type == 'chat' ||
          type == 'new_message' ||
          type == 'text' ||
          type == 'edit_msg' ||
          type == 'update_msg';
      if (!isChatMessage) return;

      final String? incomingConvId = msgMap['conversation_id']?.toString();
      final String? activeConvId = state.activeConversationId?.toString();
      if (activeConvId == null || incomingConvId != activeConvId) return;

      final String msgId = (msgMap['msg_id'] ?? msgMap['id'] ?? "").toString();
      if (msgId.isEmpty) return;

      // 2. Metadata Normalization
      msgMap['sender'] = msgMap['sender'] ?? msgMap['created_by_id'];
      if (msgMap['created_by_name'] != null)
        msgMap['sendername'] = msgMap['created_by_name'];
      if (msgMap['created_by_img'] != null)
        msgMap['senderimg'] = msgMap['created_by_img'];

      // 3. Check for existing message (Handle Updates/Edits)
      final int existingIndex = state.messages.indexWhere(
        (m) => (m['msg_id'] ?? m['id'] ?? "").toString() == msgId,
      );

      // 4. Content Processing (Decryption & Attachments)
      // Process content before deciding whether to update or add, ensuring UI always has clean data
      final String rawBody = (msgMap['msg_body'] ?? msgMap['body'] ?? "")
          .toString();
      if (rawBody.isNotEmpty) {
        final String trimmedBody = rawBody.trim();
        if (trimmedBody.startsWith('{') || trimmedBody.startsWith('[')) {
          _processJsonBody(msgMap, trimmedBody);
        } else {
          _attemptDecryption(msgMap, rawBody);
        }
      }

      if (existingIndex != -1) {
        // Update logic: Replace the message in place to avoid duplicates
        final List updatedMessages = List.from(state.messages);
        updatedMessages[existingIndex] = {
          ...updatedMessages[existingIndex],
          ...msgMap,
        };
        emit(state.copyWith(messages: updatedMessages));
        return;
      }

      // 5. New Message Logic (ignore self-messages handled by optimistic updates)
      if (msgMap['sender'] == state.myId) return;

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
