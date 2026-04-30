import 'package:flutter/material.dart';

class AppColors {
  static Color getBackgroundColor(bool isDark) {
    return isDark ? const Color(0xFF052874) : const Color(0xFF030915);
  }

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
  );

  static const Color accentColor = Colors.lightBlueAccent;
}
