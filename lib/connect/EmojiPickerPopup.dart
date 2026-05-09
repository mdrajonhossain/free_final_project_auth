import 'package:flutter/material.dart';

class EmojiPickerView extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClose;

  const EmojiPickerView({
    super.key,
    required this.controller,
    required this.onClose,
  });

  final List<String> emojis = const [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '😅',
    '😂',
    '🤣',
    '😊',
    '😇',
    '🙂',
    '🙃',
    '😉',
    '😌',
    '😍',
    '🥰',
    '😘',
    '😗',
    '😙',
    '😚',
    '😋',
    '😛',
    '😝',
    '😜',
    '🤪',
    '🤨',
    '🧐',
    '🤓',
    '😎',
    '🤩',
    '🥳',
    '😏',
    '😒',
    '😞',
    '😔',
    '😟',
    '😕',
    '🙁',
    '☹️',
    '😮',
    '😯',
    '😲',
    '😳',
    '🥺',
    '😦',
    '😧',
    '😨',
    '😰',
    '😥',
    '😢',
    '😭',
    '😱',
    '😖',
    '😣',
    '😞',
    '😓',
    '😩',
    '😫',
    '🥱',
    '😤',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280, // Fixed professional height
      decoration: BoxDecoration(
        color: const Color(0xff1B2335).withOpacity(0.95),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  "Pick Emoji",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white54,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: emojis.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    final text = controller.text;
                    final selection = controller.selection;
                    final cursorPosition = selection.start >= 0
                        ? selection.start
                        : text.length;
                    final newText = text.replaceRange(
                      cursorPosition,
                      selection.end >= 0 ? selection.end : text.length,
                      emojis[index],
                    );
                    controller.text = newText;
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(
                        offset: cursorPosition + emojis[index].length,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      emojis[index],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
