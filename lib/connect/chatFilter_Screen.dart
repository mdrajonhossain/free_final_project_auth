import 'package:flutter/material.dart';

class ChatFilterScreen {
  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topRight,
          child: Container(
            margin: const EdgeInsets.only(top: 90, right: 3),
            child: Material(
              color: const Color(0xff1B2335),
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 220,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildOption(
                      context,
                      Icons.forum_outlined,
                      "Threaded messages",
                      () => debugPrint("Filter: Threaded messages"),
                    ),
                    _buildOption(
                      context,
                      Icons.link_rounded,
                      "Messages with links",
                      () => debugPrint("Filter: Messages with links"),
                    ),
                    _buildOption(
                      context,
                      Icons.title_rounded,
                      "Messages with titles",
                      () => debugPrint("Filter: Messages with titles"),
                    ),
                    _buildOption(
                      context,
                      Icons.attach_file_rounded,
                      "Messages with files",
                      () => debugPrint("Filter: Messages with files"),
                    ),
                    _buildOption(
                      context,
                      Icons.star_outline_rounded,
                      "Messages with starred files",
                      () => debugPrint("Filter: Starred files"),
                    ),
                    _buildOption(
                      context,
                      Icons.mark_chat_unread_rounded,
                      "New/Unread messages",
                      () => debugPrint("Filter: Unread messages"),
                    ),
                    _buildOption(
                      context,
                      Icons.flag_outlined,
                      "Flagged messages",
                      () => debugPrint("Filter: Flagged messages"),
                    ),
                    _buildOption(
                      context,
                      Icons.lock_outline_rounded,
                      "Private messages",
                      () => debugPrint("Filter: Private messages"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: anim1,
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
    );
  }

  static Widget _buildOption(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        color: isDestructive ? Colors.redAccent : Colors.white70,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.redAccent : Colors.white,
          fontSize: 14,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
