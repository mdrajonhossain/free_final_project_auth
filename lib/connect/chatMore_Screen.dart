import 'package:flutter/material.dart';

class ChatMoreScreen {
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
                      Icons.file_copy_rounded,
                      "Files",
                      () => debugPrint("Filehub clicked"),
                    ),
                    _buildOption(
                      context,
                      Icons.assignment_rounded,
                      "Task",
                      () => debugPrint("Task list clicked"),
                    ),
                    _buildOption(
                      context,
                      Icons.playlist_add_check_rounded,
                      "Create Task",
                      () => debugPrint("Create Task clicked"),
                    ),
                    _buildOption(
                      context,
                      Icons.settings_rounded,
                      "Room Setting",
                      () => debugPrint("Room Setting clicked"),
                    ),
                    _buildOption(
                      context,
                      Icons.location_on_rounded,
                      "Share location",
                      () => debugPrint("Share location clicked"),
                    ),
                    _buildOption(
                      context,
                      Icons.mark_chat_read_rounded,
                      "Mark all read",
                      () => debugPrint("Mark all read clicked"),
                    ),
                    _buildOption(
                      context,
                      Icons.notifications_off_rounded,
                      "Mute notifications",
                      () => debugPrint("Mute notifications clicked"),
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
