part of 'chat_bloc.dart';

abstract class ChatEvent {}

class ChatFetchRequested extends ChatEvent {
  final String conversationId;
  ChatFetchRequested(this.conversationId);
}

class ChatLoadMoreRequested extends ChatEvent {
  final String conversationId;
  ChatLoadMoreRequested(this.conversationId);
}

class ChatMessageSent extends ChatEvent {
  final String text;
  ChatMessageSent(this.text);
}
