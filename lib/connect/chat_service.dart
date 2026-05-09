import 'package:flutter/material.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:freeli/connect/crypto_utils.dart';
import '../controller/stateBloc/message/chat_bloc.dart';

class ChatService {
  static Future<void> sendMessage({
    required BuildContext context,
    required TextEditingController controller,
    required String conversationId,
    required String companyId,
    required dynamic participants, // Accepts String or List
    required ChatBloc chatBloc,
    required VoidCallback onScroll,
    Map<String, dynamic>? attachFiles,
    List<String>? tags,
    List<Map<String, dynamic>>? allAttachment,
  }) async {
    final text = controller.text.trim();
    final bool hasFiles =
        attachFiles != null &&
        attachFiles['allfiles'] is List &&
        (attachFiles['allfiles'] as List).isNotEmpty;

    // Rule: Sending only tags is not allowed. Must have text or files.
    if (text.isEmpty && !hasFiles) return;

    // Rule: Chat screen messages (no files) are "text" only.
    // Rule: Attachment option (has files) are "media_attachment".
    final String finalMsgType = hasFiles ? "media_attachment" : "text";
    final List<String>? effectiveTags = hasFiles ? tags : null;
    final List<Map<String, dynamic>>? effectiveAllAttachment = hasFiles
        ? allAttachment
        : null;

    // Dispatch event to Bloc - Business logic (encryption/API) handled there
    chatBloc.add(
      ChatMessageSent(
        text: text,
        conversationId: conversationId,
        companyId: companyId,
        senderId: chatBloc.state.myId,
        participants: participants,
        attachFiles: hasFiles ? attachFiles : null,
        tags: effectiveTags,
        allAttachment: effectiveAllAttachment,
        msgType: finalMsgType,
      ),
    );

    // UI Feedback
    controller.clear();
    onScroll();

    // Note: Success/Error handling should be managed via BlocListener in the UI
    // because chatBloc.add is an asynchronous operation.
  }
}
