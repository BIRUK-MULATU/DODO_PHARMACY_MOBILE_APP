import 'package:flutter/material.dart';

/// Central palette for the DODO Pharmacy app, lifted from the Figma board.
class AppColors {
  AppColors._();

  /// Primary brand yellow.
  static const Color yellow = Color(0xFFFFDE00);
  static const Color yellowDeep = Color(0xFFF3C700);
  static const Color yellowOlive = Color(0xFFCBB400);
  static const Color yellowSoft = Color(0xFFFFF3B0);

  /// Near-black used for headers, buttons and the wave shapes.
  static const Color ink = Color(0xFF0B0B0B);
  static const Color inkSoft = Color(0xFF1A1A18);

  /// Translucent dark used for the pill input fields / read-only fields.
  static const Color field = Color(0xE61C1B16);

  static const Color white = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF8A8A80);
  static const Color textOnYellow = Color(0xFF141400);

  /// Feedback colours for the exam engine.
  static const Color correct = Color(0xFF57B94B);
  static const Color correctFill = Color(0xFFB6E86A);
  static const Color wrong = Color(0xFFE53935);
  static const Color wrongFill = Color(0xFFF08A3C);

  static const Color success = Color(0xFF2E7D32);
  static const Color successBadge = Color(0xFF3FA34D);
}
