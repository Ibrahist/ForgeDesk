import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central color palette for ForgeDesk (Blue & White Brand Theme)
class ForgeColors {
  // Backgrounds & Surfaces (Deep Midnight Navy)
  static const Color background = Color(0xFF0A0F1D); // Deep midnight navy
  static const Color surface = Color(0xFF0F182E);    // Rich navy slate surface
  static const Color surfaceLight = Color(0xFF16233B); // Elevated navy card
  static const Color card = Color(0xFF121D36);         // Deep blue glass card
  static const Color border = Color(0xFF1E3557);       // Cool steel blue border
  static const Color borderHover = Color(0xFF2B4C7E);  // Vibrant blue border hover

  // Accents (Royal Blue & Electric Blue)
  static const Color primary = Color(0xFF2563EB);      // Brilliant Royal Blue (matching ForgeDesk brand)
  static const Color primaryLight = Color(0xFF3B82F6); // Electric Bright Blue
  static const Color primaryGlow = Color(0x402563EB);  // Soft royal blue glow
  static const Color secondary = Color(0xFF60A5FA);    // Sky Ice Blue
  static const Color accent = Color(0xFF93C5FD);       // Soft Blue Highlight

  // States
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444);   // Coral Red
  static const Color offline = Color(0xFF64748B); // Slate

  // Text & Foregrounds (Crisp Pure White & Ice Silver)
  static const Color textPrimary = Color(0xFFFFFFFF);  // Pure Crisp White
  static const Color textSecondary = Color(0xFFE2E8F0); // Ice White / Silver
  static const Color textMuted = Color(0xFF94A3B8);     // Cool Slate
  static const Color onPrimary = Color(0xFFFFFFFF);     // White text on primary buttons
}

/// Light palette for ForgeDesk (Crisp White & Royal Blue)
class ForgeLightColors {
  static const Color background = Color(0xFFF8FAFC); // Clean Pure White / Soft Ice
  static const Color surface = Color(0xFFFFFFFF);    // Pure White surface
  static const Color surfaceLight = Color(0xFFF1F5F9); // Light ice-blue card
  static const Color card = Color(0xFFFFFFFF);         // Crisp White card
  static const Color border = Color(0xFFCBD5E1);       // Subtle Ice Border
  static const Color borderHover = Color(0xFF93C5FD);  // Soft Blue Border

  static const Color primary = Color(0xFF2563EB);      // Royal Blue
  static const Color primaryLight = Color(0xFF1D4ED8); // Deep Royal Blue
  static const Color primaryGlow = Color(0x202563EB);
  static const Color secondary = Color(0xFF3B82F6);    // Vibrant Blue
  static const Color accent = Color(0xFF60A5FA);       // Sky Blue

  static const Color textPrimary = Color(0xFF0F172A);  // Deep Navy Slate
  static const Color textSecondary = Color(0xFF334155); // Slate
  static const Color textMuted = Color(0xFF64748B);     // Muted Slate
  static const Color onPrimary = Color(0xFFFFFFFF);
}

class ForgeTheme {
  static ThemeData? _cachedDarkTheme;
  static ThemeData? _cachedLightTheme;

  /// Default Dark Theme: Deep Midnight Navy Blue & Crisp Pure White
  static ThemeData get darkTheme => _cachedDarkTheme ??= _buildDarkTheme();

  /// Light Theme: Clean Pure White & Royal Blue
  static ThemeData get lightTheme => _cachedLightTheme ??= _buildLightTheme();

  static ThemeData _buildDarkTheme() {
    final baseTextTheme = ThemeData.dark().textTheme;
    final orbitronTextTheme = GoogleFonts.orbitronTextTheme(baseTextTheme).apply(
      bodyColor: ForgeColors.textPrimary,
      displayColor: ForgeColors.textPrimary,
    );

    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Orbitron',
      scaffoldBackgroundColor: ForgeColors.background,
      primaryColor: ForgeColors.primary,
      textTheme: orbitronTextTheme,
      colorScheme: const ColorScheme.dark(
        primary: ForgeColors.primary,
        secondary: ForgeColors.secondary,
        surface: ForgeColors.surface,
        error: ForgeColors.error,
        onPrimary: ForgeColors.onPrimary,
        onSecondary: Colors.white,
        onSurface: ForgeColors.textPrimary,
      ),
      iconTheme: const IconThemeData(
        color: ForgeColors.textSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.orbitron(
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
        hintStyle: GoogleFonts.orbitron(color: ForgeColors.textMuted, fontSize: 13),
        labelStyle: GoogleFonts.orbitron(color: ForgeColors.secondary, fontSize: 13),
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
          borderSide: const BorderSide(color: ForgeColors.primaryLight, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ForgeColors.primary,
          foregroundColor: ForgeColors.onPrimary,
          elevation: 2,
          shadowColor: ForgeColors.primaryGlow,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.orbitron(
            fontSize: 14,
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
          textStyle: GoogleFonts.orbitron(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerColor: ForgeColors.border,
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ForgeColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ForgeColors.border),
        ),
        textStyle: GoogleFonts.orbitron(color: ForgeColors.textPrimary, fontSize: 12),
      ),
    );
  }

  static ThemeData _buildLightTheme() {
    final baseTextTheme = ThemeData.light().textTheme;
    final orbitronTextTheme = GoogleFonts.orbitronTextTheme(baseTextTheme).apply(
      bodyColor: ForgeLightColors.textPrimary,
      displayColor: ForgeLightColors.textPrimary,
    );

    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Orbitron',
      scaffoldBackgroundColor: ForgeLightColors.background,
      primaryColor: ForgeLightColors.primary,
      textTheme: orbitronTextTheme,
      colorScheme: const ColorScheme.light(
        primary: ForgeLightColors.primary,
        secondary: ForgeLightColors.secondary,
        surface: ForgeLightColors.surface,
        error: ForgeColors.error,
        onPrimary: ForgeLightColors.onPrimary,
        onSecondary: Colors.white,
        onSurface: ForgeLightColors.textPrimary,
      ),
      iconTheme: const IconThemeData(
        color: ForgeLightColors.textSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.orbitron(
          color: ForgeLightColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: ForgeLightColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ForgeLightColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ForgeLightColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.orbitron(color: ForgeLightColors.textMuted, fontSize: 13),
        labelStyle: GoogleFonts.orbitron(color: ForgeLightColors.primary, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ForgeLightColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ForgeLightColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ForgeLightColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ForgeLightColors.primary,
          foregroundColor: ForgeLightColors.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ForgeLightColors.textPrimary,
          side: const BorderSide(color: ForgeLightColors.border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.orbitron(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerColor: ForgeLightColors.border,
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ForgeLightColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ForgeLightColors.border),
        ),
        textStyle: GoogleFonts.orbitron(color: ForgeLightColors.textPrimary, fontSize: 12),
      ),
    );
  }
}
