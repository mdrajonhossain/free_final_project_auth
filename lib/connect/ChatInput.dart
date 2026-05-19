import 'package:flutter/material.dart';
import 'package:freeli/connect/PopUpFile/EmojiPickerPopup.dart';
import 'package:freeli/connect/PopUpFile/attchmentPopup.dart';
import 'package:freeli/controller/stateBloc/message/chat_bloc.dart';
import '../AppColors.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final String companyId;
  final String? userEmail;
  final String conversationId;
  final dynamic participants;
  final ChatBloc chatBloc;
  final Function(List<Map<String, dynamic>>) onAttachmentsPicked;
  final bool showAttachmentIcon;
  final bool group;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.companyId,
    required this.onAttachmentsPicked,
    required this.conversationId,
    required this.participants,
    required this.chatBloc,
    this.group = false,
    this.userEmail,
    this.showAttachmentIcon = true,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _showEmoji = false;
  final FocusNode _focusNode = FocusNode();

  void _toggleEmoji() {
    setState(() {
      _showEmoji = !_showEmoji;
    });

    if (_showEmoji) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showEmoji)
          EmojiPickerView(
            controller: widget.controller,
            onClose: () => setState(() => _showEmoji = false),
          ),

        SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 14),
            decoration: BoxDecoration(
              color: AppColors.primaryGradient.colors[0],
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        // LOCK ICON
                        widget.group
                            ? Row(
                                children: [
                                  const SizedBox(width: 14),
                                  Container(
                                    height: 34,
                                    width: 34,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.lock_rounded,
                                      color: Colors.white.withOpacity(0.7),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                              )
                            : const SizedBox(width: 18),

                        // TEXT FIELD
                        Expanded(
                          child: TextField(
                            focusNode: _focusNode,
                            controller: widget.controller,
                            onTap: () {
                              if (_showEmoji) {
                                setState(() => _showEmoji = false);
                              }
                            },
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            minLines: 1,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              hintText: "Message...",
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        // ATTACHMENT ICON
                        if (widget.showAttachmentIcon)
                          IconButton(
                            onPressed: () async {
                              final results = await AttachmentPopup.show(
                                context,
                                userEmail: widget.userEmail,
                                companyId: widget.companyId,
                                conversationId: widget.conversationId,
                                participants: widget.participants,
                                chatBloc: widget.chatBloc,
                              );

                              if (results != null && results.isNotEmpty) {
                                widget.onAttachmentsPicked(results);
                              }
                            },
                            icon: Icon(
                              Icons.attach_file_rounded,
                              color: Colors.white.withOpacity(0.6),
                              size: 22,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),

                        // EMOJI ICON
                        IconButton(
                          onPressed: _toggleEmoji,
                          icon: Icon(
                            _showEmoji
                                ? Icons.keyboard_rounded
                                : Icons.emoji_emotions_rounded,
                            color: _showEmoji
                                ? const Color(0xff7C5CFF)
                                : Colors.white.withOpacity(0.6),
                            size: 22,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),

                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // SEND BUTTON
                GestureDetector(
                  onTap: widget.onSend,
                  child: Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xff7C5CFF), Color(0xff5B4DFF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff7C5CFF).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
