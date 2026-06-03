import 'package:flutter/material.dart';

class AppColors {
  // Color 1: Dark Blue
  static const Color colorBlue = Color.fromRGBO(5, 40, 116, 1);
  // Color 2: Deep Black
  static const Color colorBlack = Color(0xFF030915);

  static Color getBackgroundColor(bool isDark) {
    return isDark ? colorBlack : colorBlue;
  }

  static LinearGradient getPrimaryGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark ? [colorBlack, colorBlue] : [colorBlue, colorBlack],
    );
  }

  static Color getAccentColor(bool isDark) {
    // This ensures the accent/button color is always the "other" color
    // in the palette for contrast.
    return isDark ? colorBlue : colorBlack;
  }
}
