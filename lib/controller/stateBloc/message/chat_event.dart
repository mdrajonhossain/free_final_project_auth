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
  final String conversationId;
  final String companyId;
  final String senderId;
  final dynamic participants;

  ChatMessageSent({
    required this.text,
    required this.conversationId,
    required this.companyId,
    required this.senderId,
    required this.participants,
  });
}
