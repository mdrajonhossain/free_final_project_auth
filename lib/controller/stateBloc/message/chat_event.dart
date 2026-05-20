part of 'chat_bloc.dart';

@immutable
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
  final List<String>? tags;
  final List<Map<String, dynamic>>? allAttachment;

  ChatMessageSent({
    required this.text,
    required this.conversationId,
    required this.companyId,
    required this.participants,
    this.msgType = "text",
    this.attachFiles,
    this.tags,
    this.allAttachment,
  });
}

class ChatXmppMessageReceived extends ChatEvent {
  final dynamic message;
  ChatXmppMessageReceived(this.message);
}

class ChatMessageTagsUpdated extends ChatEvent {
  final String conversationId;
  final String msgId;
  final String fileId;
  final List<String> newTagIds;
  final List<Map<String, dynamic>> newTagDetails;
  final VoidCallback? onSuccess;
  final Function(dynamic error)? onError;

  ChatMessageTagsUpdated({
    required this.conversationId,
    required this.msgId,
    required this.fileId,
    required this.newTagIds,
    required this.newTagDetails,
    this.onSuccess,
    this.onError,
  });
}

class ChatMessageEdited extends ChatEvent {
  final String conversationId;
  final String msgId;
  final String newText;
  final Function()? onSuccess;
  final Function(dynamic error)? onError;

  ChatMessageEdited({
    required this.conversationId,
    required this.msgId,
    required this.newText,
    this.onSuccess,
    this.onError,
  });
}

class ChatMessageDeleted extends ChatEvent {
  final String conversationId;
  final String msgId;
  final String deleteType;
  final String isReplyMsg;
  final List<String> participants;
  final Function()? onSuccess;
  final Function(dynamic error)? onError;

  ChatMessageDeleted({
    required this.conversationId,
    required this.msgId,
    this.deleteType = "for_me",
    this.isReplyMsg = "no",
    this.participants = const [],
    this.onSuccess,
    this.onError,
  });
}

class ChatFileStarred extends ChatEvent {
  final String fileId;
  final String msgId;
  final List<dynamic> star;
  ChatFileStarred({
    required this.fileId,
    required this.msgId,
    required this.star,
  });
}
