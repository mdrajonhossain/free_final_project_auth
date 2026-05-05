part of 'chat_bloc.dart';

class ChatState {
  final List<dynamic> messages;
  final bool isLoading;
  final bool isFetchingMore;
  final bool hasMore;
  final int currentPage;
  final String myId;
  final Map<String, dynamic>? userData;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = true,
    this.isFetchingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.myId = "",
    this.userData,
    this.error,
  });

  ChatState copyWith({
    List<dynamic>? messages,
    bool? isLoading,
    bool? isFetchingMore,
    bool? hasMore,
    int? currentPage,
    String? myId,
    Map<String, dynamic>? userData,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      myId: myId ?? this.myId,
      userData: userData ?? this.userData,
      error: error ?? this.error,
    );
  }
}
