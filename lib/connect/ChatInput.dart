import 'package:flutter/material.dart';
import '../AppColors.dart';
import 'attchmentPopup.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final String companyId;
  final String? userEmail;
  final Function(List<Map<String, dynamic>>) onAttachmentsPicked;
  final bool
  showAttachmentIcon; // New parameter to control attachment icon visibility

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.companyId,
    required this.onAttachmentsPicked,
    this.userEmail,
    this.showAttachmentIcon = true, // Default to true
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        minLines: 1,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: "Type message...",
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    if (showAttachmentIcon) // Only show attachment icon if true
                      IconButton(
                        onPressed: () async {
                          final results = await AttachmentPopup.show(
                            context,
                            userEmail: userEmail,
                            companyId: companyId,
                          );
                          if (results != null && results.isNotEmpty) {
                            onAttachmentsPicked(results);
                          }
                        },
                        icon: Icon(
                          Icons.attach_file_rounded,
                          color: Colors.white.withOpacity(0.6),
                          size: 22,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    // Emoji icon is always visible
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.emoji_emotions_rounded,
                        color: Colors.white.withOpacity(0.6),
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
            GestureDetector(
              onTap: onSend,
              child: Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xff7C5CFF), Color(0xff5B4DFF)],
                  ),
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
    );
  }
}
