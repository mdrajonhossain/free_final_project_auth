import 'dart:async';
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
      final serverMsg = await apiServer.sendMessage(
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

      // 3. Update State: Replace optimistic message with real server response
      final List finalMessages = state.messages
          .map((m) => m['msg_id'] == tempId ? serverMsg : m)
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
    // The message is already normalized into a Map in the HomePage XMPP listener
    final Map<String, dynamic> msgMap = Map<String, dynamic>.from(
      event.message,
    );

    // 2. Filter: Only process 'chat' or 'new_message' for the current active room
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

    // 4. Decrypt body if it's an encrypted message
    final String rawBody = (msgMap['msg_body'] ?? msgMap['body'] ?? "")
        .toString();
    if (rawBody.isNotEmpty && !rawBody.startsWith('{')) {
      try {
        msgMap['msg_body'] = CryptoUtils.decryptMessage(rawBody);
      } catch (e) {
        print('❌ Decryption failed in Bloc: $e');
      }
    }

    final updatedMessages = [msgMap, ...state.messages];
    emit(state.copyWith(messages: updatedMessages));
  }
}
