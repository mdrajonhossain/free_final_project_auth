import 'package:flutter/material.dart';

class AppThemeModel {
  final String name;
  final Color backgroundColor;
  final Color textColor;
  final Color subTextColor;
  final Color accentColor;
  final Color cardColor;
  final Color msgSenderBubble;
  final Color msgReceiverBubble;
  final Color msgSenderText;
  final Color msgReceiverText;

  AppThemeModel({
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.subTextColor,
    required this.accentColor,
    required this.cardColor,
    required this.msgSenderBubble,
    required this.msgReceiverBubble,
    required this.msgSenderText,
    required this.msgReceiverText,
  });
}

final List<AppThemeModel> professionalThemes = [
  AppThemeModel(
    name: "Midnight Blue",
    backgroundColor: const Color(0xFF0C1F5E),
    textColor: Colors.white,
    subTextColor: Colors.white70,
    accentColor: const Color(0xFF4C8DFF),
    cardColor: const Color(0xFF162447),
    msgSenderBubble: const Color(0xFF4C8DFF),
    msgReceiverBubble: const Color(0xFF162447),
    msgSenderText: Colors.white,
    msgReceiverText: Colors.white,
  ),
  AppThemeModel(
    name: "Pure White",
    backgroundColor: const Color(0xFFF4F7FC),
    textColor: const Color(0xFF1E293B),
    subTextColor: Colors.black54,
    accentColor: const Color(0xFF4C8DFF),
    cardColor: Colors.white,
    msgSenderBubble: const Color(0xFF4C8DFF),
    msgReceiverBubble: const Color(0xFFE2E8F0),
    msgSenderText: Colors.white,
    msgReceiverText: const Color(0xFF1E293B),
  ),
  AppThemeModel(
    name: "Deep Forest",
    backgroundColor: const Color(0xFF0B2010),
    textColor: Colors.white,
    subTextColor: Colors.white60,
    accentColor: const Color(0xFF2ECC71),
    cardColor: const Color(0xFF142D19),
    msgSenderBubble: const Color(0xFF2ECC71),
    msgReceiverBubble: const Color(0xFF142D19),
    msgSenderText: Colors.white,
    msgReceiverText: Colors.white,
  ),
  AppThemeModel(
    name: "Royal Purple",
    backgroundColor: const Color(0xFF2D033B),
    textColor: Colors.white,
    subTextColor: Colors.white70,
    accentColor: const Color(0xFFBB86FC),
    cardColor: const Color(0xFF3D0850),
    msgSenderBubble: const Color(0xFFBB86FC),
    msgReceiverBubble: const Color(0xFF3D0850),
    msgSenderText: Colors.black,
    msgReceiverText: Colors.white,
  ),
  AppThemeModel(
    name: "Coffee Shop",
    backgroundColor: const Color(0xFF3E2723),
    textColor: const Color(0xFFD7CCC8),
    subTextColor: const Color(0xFFA1887F),
    accentColor: const Color(0xFFFFAB91),
    cardColor: const Color(0xFF4E342E),
    msgSenderBubble: const Color(0xFFFFAB91),
    msgReceiverBubble: const Color(0xFF4E342E),
    msgSenderText: Colors.black,
    msgReceiverText: const Color(0xFFD7CCC8),
  ),
  AppThemeModel(
    name: "Nordic Grey",
    backgroundColor: const Color(0xFF2E3440),
    textColor: const Color(0xFFECEFF4),
    subTextColor: const Color(0xFFD8DEE9),
    accentColor: const Color(0xFF88C0D0),
    cardColor: const Color(0xFF3B4252),
    msgSenderBubble: const Color(0xFF88C0D0),
    msgReceiverBubble: const Color(0xFF3B4252),
    msgSenderText: const Color(0xFF2E3440),
    msgReceiverText: const Color(0xFFECEFF4),
  ),
  AppThemeModel(
    name: "Oceanic",
    backgroundColor: const Color(0xFF002B36),
    textColor: const Color(0xFF839496),
    subTextColor: const Color(0xFF586E75),
    accentColor: const Color(0xFF268BD2),
    cardColor: const Color(0xFF073642),
    msgSenderBubble: const Color(0xFF268BD2),
    msgReceiverBubble: const Color(0xFF073642),
    msgSenderText: Colors.white,
    msgReceiverText: const Color(0xFF839496),
  ),
  AppThemeModel(
    name: "Minimalist Dark",
    backgroundColor: const Color(0xFF121212),
    textColor: Colors.white,
    subTextColor: Colors.white54,
    accentColor: Colors.tealAccent,
    cardColor: const Color(0xFF1E1E1E),
    msgSenderBubble: Colors.tealAccent,
    msgReceiverBubble: const Color(0xFF1E1E1E),
    msgSenderText: Colors.black,
    msgReceiverText: Colors.white,
  ),
  AppThemeModel(
    name: "Classic Slate",
    backgroundColor: const Color(0xFF1E293B),
    textColor: Colors.white,
    subTextColor: Colors.white60,
    accentColor: const Color(0xFF38BDF8),
    cardColor: const Color(0xFF334155),
    msgSenderBubble: const Color(0xFF38BDF8),
    msgReceiverBubble: const Color(0xFF334155),
    msgSenderText: Colors.black,
    msgReceiverText: Colors.white,
  ),
  AppThemeModel(
    name: "Soft Clay",
    backgroundColor: const Color(0xFFF5E6D3),
    textColor: const Color(0xFF5D4037),
    subTextColor: const Color(0xFF8D6E63),
    accentColor: const Color(0xFFD84315),
    cardColor: const Color(0xFFFFF3E0),
    msgSenderBubble: const Color(0xFFD84315),
    msgReceiverBubble: const Color(0xFFFFF3E0),
    msgSenderText: Colors.white,
    msgReceiverText: const Color(0xFF5D4037),
  ),
];
