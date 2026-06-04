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
  final Color msgBackgroundColor;
  final Color msgStatusIconColor;

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
    required this.msgBackgroundColor,
    required this.msgStatusIconColor,
  });
}

final List<AppThemeModel> professionalThemes = [
  AppThemeModel(
    name: "Midnight Blue",
    backgroundColor: const Color(0xFF0B132B),
    textColor: Colors.white,
    subTextColor: Colors.white70,
    accentColor: const Color(0xFF5BC0BE),
    cardColor: const Color(0xFF1C2541),
    msgSenderBubble: const Color(0xFF334155), // Professional Slate 700
    msgReceiverBubble: const Color(0xFF1C2541),
    msgSenderText: Colors.white,
    msgReceiverText: Colors.white,
    msgBackgroundColor: const Color(
      0xFFC7BCBB,
    ), // User's requested comfortable grey
    msgStatusIconColor: const Color(0xFF5BC0BE),
  ),
  AppThemeModel(
    name: "Pure White",
    backgroundColor: const Color(0xFFF8FAFC),
    textColor: const Color(0xFF0F172A),
    subTextColor: const Color(0xFF64748B),
    accentColor: const Color(0xFF3B82F6),
    cardColor: Colors.white,
    msgSenderBubble: const Color(0xFF3B82F6),
    msgReceiverBubble: const Color(0xFFF1F5F9),
    msgSenderText: Colors.white,
    msgReceiverText: const Color(0xFF0F172A),
    msgBackgroundColor: const Color(0xFFF8FAFC),
    msgStatusIconColor: const Color(0xFF3B82F6),
  ),
  AppThemeModel(
    name: "Deep Forest",
    backgroundColor: const Color(0xFF142421),
    textColor: const Color(0xFFE8F3F1),
    subTextColor: const Color(0xFF94A3B8),
    accentColor: const Color(0xFF10B981),
    cardColor: const Color(0xFF1F2F2C),
    msgSenderBubble: const Color(0xFF10B981),
    msgReceiverBubble: const Color(0xFF1F2F2C),
    msgSenderText: Colors.white,
    msgReceiverText: const Color(0xFFE8F3F1),
    msgBackgroundColor: const Color(0xFF142421),
    msgStatusIconColor: const Color(0xFF10B981),
  ),
  AppThemeModel(
    name: "Royal Purple",
    backgroundColor: const Color(0xFF1A1A2E),
    textColor: Colors.white,
    subTextColor: Colors.white70,
    accentColor: const Color(0xFFE94560),
    cardColor: const Color(0xFF16213E),
    msgSenderBubble: const Color(0xFFE94560),
    msgReceiverBubble: const Color(0xFF16213E),
    msgSenderText: Colors.white,
    msgReceiverText: Colors.white,
    msgBackgroundColor: const Color(0xFF1A1A2E),
    msgStatusIconColor: const Color(0xFFE94560),
  ),
  AppThemeModel(
    name: "Nordic Grey",
    backgroundColor: const Color(0xFF2E3440),
    textColor: const Color(0xFFECEFF4),
    subTextColor: const Color(0xFFD8DEE9),
    accentColor: const Color(0xFF88C0D0),
    cardColor: const Color(0xFF3B4252),
    msgSenderBubble: const Color(0xFF4C566A),
    msgReceiverBubble: const Color(0xFF3B4252),
    msgSenderText: Colors.white,
    msgReceiverText: const Color(0xFFECEFF4),
    msgBackgroundColor: const Color(0xFF2E3440),
    msgStatusIconColor: const Color(0xFF88C0D0),
  ),
  AppThemeModel(
    name: "Oceanic",
    backgroundColor: const Color(0xFF0D2137),
    textColor: const Color(0xFFE0E1DD),
    subTextColor: const Color(0xFF778DA9),
    accentColor: const Color(0xFF415A77),
    cardColor: const Color(0xFF1B263B),
    msgSenderBubble: const Color(0xFF415A77),
    msgReceiverBubble: const Color(0xFF1B263B),
    msgSenderText: Colors.white,
    msgReceiverText: const Color(0xFFE0E1DD),
    msgBackgroundColor: const Color(0xFF0D2137),
    msgStatusIconColor: const Color(0xFF415A77),
  ),
  AppThemeModel(
    name: "Minimalist Dark",
    backgroundColor: const Color(0xFF000000),
    textColor: Colors.white,
    subTextColor: Colors.white54,
    accentColor: const Color(0xFF00D1FF),
    cardColor: const Color(0xFF121212),
    msgSenderBubble: const Color(0xFF00D1FF),
    msgReceiverBubble: const Color(0xFF121212),
    msgSenderText: Colors.black,
    msgReceiverText: Colors.white,
    msgBackgroundColor: const Color(0xFF000000),
    msgStatusIconColor: const Color(0xFF00D1FF),
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
    msgBackgroundColor: const Color(0xFF3E2723),
    msgStatusIconColor: const Color(0xFFFFAB91),
  ),
  AppThemeModel(
    name: "Slate Pro",
    backgroundColor: const Color(0xFF1E293B),
    textColor: Colors.white,
    subTextColor: Colors.white60,
    accentColor: const Color(0xFF38BDF8),
    cardColor: const Color(0xFF334155),
    msgSenderBubble: const Color(0xFF38BDF8),
    msgReceiverBubble: const Color(0xFF334155),
    msgSenderText: Colors.black,
    msgReceiverText: Colors.white,
    msgBackgroundColor: const Color(0xFF1E293B),
    msgStatusIconColor: const Color(0xFF38BDF8),
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
    msgBackgroundColor: const Color(0xFFF5E6D3),
    msgStatusIconColor: const Color(0xFFD84315),
  ),
];
