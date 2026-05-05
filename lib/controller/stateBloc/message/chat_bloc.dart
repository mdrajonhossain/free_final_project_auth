import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/connect/crypto_utils.dart';
import 'package:freeli/controller/api/api_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiServer apiServer = ApiServer();

  ChatBloc() : super(ChatState()) {
    on<ChatFetchRequested>(_onFetchRequested);
    on<ChatLoadMoreRequested>(_onLoadMoreRequested);
    on<ChatMessageSent>(_onMessageSent);
  }

  Future<void> _onFetchRequested(
    ChatFetchRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, currentPage: 1, hasMore: true));
    try {
      Map<String, dynamic>? userData = state.userData;
      String myId = state.myId;

      if (myId.isEmpty) {
        userData = await apiServer.fetchMe();
        myId = userData?['id']?.toString() ?? "";
      }

      final data = await apiServer.fetchMessages(event.conversationId, page: 1);
      final List messages = (data['msgs'] as List?)?.reversed.toList() ?? [];

      emit(
        state.copyWith(
          messages: messages,
          isLoading: false,
          myId: myId,
          userData: userData,
          hasMore: messages.isNotEmpty,
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

  void _onMessageSent(ChatMessageSent event, Emitter<ChatState> emit) {
    final encryptedText = CryptoUtils.encryptMessage(event.text);
    final newMessage = {
      "sender": state.myId,
      "sendername":
          "${state.userData?['firstname'] ?? 'Me'} ${state.userData?['lastname'] ?? ''}"
              .trim(),
      "senderimg":
          state.userData?['img'] ??
          "https://wfss001.freeli.io/profile-pic/Photos/corporate-company-logo-png_seeklogo-425925@1764655943904.png",
      "msg_body": encryptedText,
      "created_at": DateTime.now().toIso8601String(),
    };

    final updatedMessages = List.from(state.messages)..insert(0, newMessage);
    emit(state.copyWith(messages: updatedMessages));
  }
}
