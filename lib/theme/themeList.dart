import 'package:flutter/material.dart';

class AppThemeModel {
  final String name;
  final Color backgroundColor;
  final Color textColor;
  final Color subTextColor;
  final Color accentColor;
  final Color cardColor;

  AppThemeModel({
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.subTextColor,
    required this.accentColor,
    required this.cardColor,
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
  ),
  AppThemeModel(
    name: "Pure White",
    backgroundColor: const Color(0xFFF8FAFC),
    textColor: const Color(0xFF0F172A),
    subTextColor: const Color(0xFF64748B),
    accentColor: const Color(0xFF3B82F6),
    cardColor: Colors.white,
  ),
  AppThemeModel(
    name: "Deep Forest",
    backgroundColor: const Color(0xFF142421),
    textColor: const Color(0xFFE8F3F1),
    subTextColor: const Color(0xFF94A3B8),
    accentColor: const Color(0xFF10B981),
    cardColor: const Color(0xFF1F2F2C),
  ),
  AppThemeModel(
    name: "Royal Purple",
    backgroundColor: const Color(0xFF1A1A2E),
    textColor: Colors.white,
    subTextColor: Colors.white70,
    accentColor: const Color(0xFFE94560),
    cardColor: const Color(0xFF16213E),
  ),
  AppThemeModel(
    name: "Nordic Grey",
    backgroundColor: const Color(0xFF2E3440),
    textColor: const Color(0xFFECEFF4),
    subTextColor: const Color(0xFFD8DEE9),
    accentColor: const Color(0xFF88C0D0),
    cardColor: const Color(0xFF3B4252),
  ),
  AppThemeModel(
    name: "Oceanic",
    backgroundColor: const Color(0xFF0D2137),
    textColor: const Color(0xFFE0E1DD),
    subTextColor: const Color(0xFF778DA9),
    accentColor: const Color(0xFF415A77),
    cardColor: const Color(0xFF1B263B),
  ),
  AppThemeModel(
    name: "Minimalist Dark",
    backgroundColor: const Color(0xFF000000),
    textColor: Colors.white,
    subTextColor: Colors.white54,
    accentColor: const Color(0xFF00D1FF),
    cardColor: const Color(0xFF121212),
  ),
  AppThemeModel(
    name: "Coffee Shop",
    backgroundColor: const Color(0xFF3E2723),
    textColor: const Color(0xFFD7CCC8),
    subTextColor: const Color(0xFFA1887F),
    accentColor: const Color(0xFFFFAB91),
    cardColor: const Color(0xFF4E342E),
  ),
  AppThemeModel(
    name: "Slate Pro",
    backgroundColor: const Color(0xFF1E293B),
    textColor: Colors.white,
    subTextColor: Colors.white60,
    accentColor: const Color(0xFF38BDF8),
    cardColor: const Color(0xFF334155),
  ),
  AppThemeModel(
    name: "Soft Clay",
    backgroundColor: const Color(0xFFF5E6D3),
    textColor: const Color(0xFF5D4037),
    subTextColor: const Color(0xFF8D6E63),
    accentColor: const Color(0xFFD84315),
    cardColor: const Color(0xFFFFF3E0),
  ),
];
