import 'package:flutter/material.dart';

class ForgeColors {
  // Backgrounds
  static const Color background = Color(0xFF090D16);
  static const Color surface = Color(0xFF0E1422);
  static const Color surfaceLight = Color(0xFF151D30);
  static const Color card = Color(0xFF131A2A);
  static const Color border = Color(0xFF222E46);
  static const Color borderHover = Color(0xFF334568);

  // Accents
  static const Color primary = Color(0xFF00F0FF); // Cyber Cyan
  static const Color primaryGlow = Color(0x3300F0FF);
  static const Color secondary = Color(0xFF6366F1); // Radiant Indigo
  static const Color accent = Color(0xFF8B5CF6);

  // States
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFF43F5E); // Crimson Rose
  static const Color offline = Color(0xFF64748B); // Slate

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
}

class ForgeTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ForgeColors.background,
      primaryColor: ForgeColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: ForgeColors.primary,
        secondary: ForgeColors.secondary,
        surface: ForgeColors.surface,
        error: ForgeColors.error,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: ForgeColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ForgeColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: ForgeColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ForgeColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ForgeColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: ForgeColors.textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ForgeColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ForgeColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ForgeColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ForgeColors.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ForgeColors.textPrimary,
          side: const BorderSide(color: ForgeColors.border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      dividerColor: ForgeColors.border,
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ForgeColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ForgeColors.border),
        ),
        textStyle: const TextStyle(color: ForgeColors.textPrimary, fontSize: 12),
      ),
    );
  }
}
