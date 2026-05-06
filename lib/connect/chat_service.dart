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
  }) async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    // Dispatch event to Bloc - Business logic (encryption/API) handled there
    chatBloc.add(
      ChatMessageSent(
        text: text,
        conversationId: conversationId,
        companyId: companyId,
        senderId: chatBloc.state.myId,
        participants: participants,
      ),
    );

    // UI Feedback
    controller.clear();
    onScroll();

    if (chatBloc.state.error != null && context.mounted) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to send message")));
      }
    }
  }
}
