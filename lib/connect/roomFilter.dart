import 'package:flutter/material.dart';

class roomFilter {
  static void show(
    BuildContext context, {
    required Function(String) onFilterSelected,
  }) {
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
                      Icons.all_inbox_rounded,
                      "All",
                      () => onFilterSelected("all"),
                    ),
                    _buildOption(
                      context,
                      Icons.person_rounded,
                      "Created by me",
                      () => onFilterSelected("me"),
                    ),
                    _buildOption(
                      context,
                      Icons.people_outline_rounded,
                      "Created by others",
                      () => onFilterSelected("others"),
                    ),
                    _buildOption(
                      context,
                      Icons.groups_rounded,
                      "Rooms",
                      () => onFilterSelected("rooms"),
                    ),
                    _buildOption(
                      context,
                      Icons.chat_bubble_outline_rounded,
                      "Direct messages",
                      () => onFilterSelected("direct"),
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
