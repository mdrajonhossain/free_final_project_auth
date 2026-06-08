import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/theme/ThemeCubit.dart';
import 'package:freeli/theme/themeList.dart';

class UserProfilePopup {
  static void show(
    BuildContext context, {
    required String name,
    required String email,
    required String imageUrl,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: const Color.fromARGB(62, 126, 117, 117),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return BlocBuilder<ThemeCubit, AppThemeModel>(
          builder: (context, appTheme) {
            final bool isDark =
                appTheme.backgroundColor.computeLuminance() < 0.5;
            final Color contentColor = isDark ? Colors.white : Colors.black;

            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: appTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color.fromARGB(255, 117, 109, 109),
                      width: 1,
                    ), // Added 4px white border
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
                        blurRadius: 40,
                        spreadRadius: 2,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Close Button
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.close,
                            color: contentColor.withOpacity(0.38),
                            size: 20,
                          ),
                        ),
                      ),
                      // Avatar with Ring
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: appTheme.accentColor,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: contentColor.withOpacity(0.1),
                          backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: contentColor.withOpacity(0.24),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // User Info
                      Text(
                        name,
                        style: TextStyle(
                          color: contentColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          color: contentColor.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Quick Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildAction(
                            Icons.message_outlined,
                            "Chat",
                            appTheme,
                            contentColor,
                          ),
                          const SizedBox(width: 10),
                          _buildAction(
                            Icons.call_rounded,
                            "Call",
                            appTheme,
                            contentColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  static Widget _buildAction(
    IconData icon,
    String label,
    AppThemeModel appTheme,
    Color contentColor,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: appTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: appTheme.accentColor, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: contentColor.withOpacity(0.7), fontSize: 11),
        ),
      ],
    );
  }
}
