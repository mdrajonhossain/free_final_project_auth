part of 'chat_bloc.dart';

class ChatState {
  final List messages;
  final bool isLoading;
  final bool isFetchingMore;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final String myId;
  final Map<String, dynamic>? userData;
  final String? activeConversationId;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
    this.myId = '',
    this.userData,
    this.activeConversationId,
  });

  ChatState copyWith({
    List? messages,
    bool? isLoading,
    bool? isFetchingMore,
    String? error,
    int? currentPage,
    bool? hasMore,
    String? myId,
    Map<String, dynamic>? userData,
    String? activeConversationId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      myId: myId ?? this.myId,
      userData: userData ?? this.userData,
      activeConversationId: activeConversationId ?? this.activeConversationId,
    );
  }
}
