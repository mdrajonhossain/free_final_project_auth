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
  final dynamic participants;
  final String msgType;
  final Map<String, dynamic>? attachFiles;
  final dynamic tags;
  final dynamic allAttachment;

  ChatMessageSent({
    required this.text,
    required this.conversationId,
    required this.companyId,
    required this.participants,
    this.msgType = 'text',
    this.attachFiles,
    this.tags,
    this.allAttachment,
  });
}

class ChatXmppMessageReceived extends ChatEvent {
  final Map<String, dynamic> message;
  ChatXmppMessageReceived(this.message);
}
