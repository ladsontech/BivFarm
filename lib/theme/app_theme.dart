import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Theme mode state ──────────────────────────────
  static bool isDark = false; // Default: light theme

  // ─── Adaptive Colors ───────────────────────────────
  static Color get background =>
      isDark ? const Color(0xFF080D08) : const Color(0xFFF5F9F5);
  static Color get surface => isDark ? const Color(0xFF0E140E) : Colors.white;
  static Color get surfaceLight =>
      isDark ? const Color(0xFF141A14) : const Color(0xFFEBF2EB);
  static Color get card => isDark ? const Color(0xFF121812) : Colors.white;
  static Color get cardHover =>
      isDark ? const Color(0xFF1A221A) : const Color(0xFFF0F6F0);
  static Color get border =>
      isDark ? const Color(0xFF1D261D) : const Color(0xFFD4DAD4);
  static Color get borderLight =>
      isDark ? const Color(0xFF242E24) : const Color(0xFFE6EAE6);

  static Color get textPrimary =>
      isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
  static Color get textSecondary =>
      isDark ? const Color(0xFFB0B0B0) : const Color(0xFF5F6368);
  static Color get textMuted =>
      isDark ? const Color(0xFF707070) : const Color(0xFF9AA0A6);

  // ─── Brand Colors (constant across themes) ─────────
  static const Color green = Color(0xFF2E7D32);
  static const Color greenLight = Color(0xFF4CAF50);
  static const Color greenAccent = Color(0xFF00E676);
  static const Color greenDark = Color(0xFF1B5E20);
  static Color get greenSurface =>
      isDark ? const Color(0xFF0D2818) : const Color(0xFFE8F5E9);

  // ─── Premium Gradients ─────────────────────────────
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [greenDark, green],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get lightGradient => LinearGradient(
        colors: [green.withOpacity(0.8), greenLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get surfaceGradient => LinearGradient(
        colors: isDark
            ? [const Color(0xFF0E140E), const Color(0xFF080D08)]
            : [Colors.white, const Color(0xFFF5F9F5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  // ─── Decoration Helpers ─────────────────────────────
  static BoxDecoration glassDecoration(
          {double opacity = 0.1, double blur = 10}) =>
      BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static const Color error = Color(0xFFCF6679);
  static const Color warning = Color(0xFFFFB74D);
  static const Color info = Color(0xFF64B5F6);
  static const Color success = Color(0xFF66BB6A);

  // Status colors (constant)
  static const Color statusPending = Color(0xFFFFB74D);
  static const Color statusReview = Color(0xFF64B5F6);
  static const Color statusAccepted = Color(0xFF66BB6A);
  static const Color statusRejected = Color(0xFFCF6679);
  static const Color statusCompleted = Color(0xFF2E7D32);

  // ─── Theme Data ────────────────────────────────────
  static ThemeData get theme {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: green,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: green,
        secondary: greenLight,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.black,
      ),
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          displayLarge:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          displayMedium:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          displaySmall:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          headlineLarge:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          headlineMedium:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          headlineSmall:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
          titleLarge:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleMedium:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
          titleSmall:
              TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
          bodySmall: TextStyle(color: textMuted),
          labelLarge:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          labelMedium: TextStyle(color: textSecondary),
          labelSmall: TextStyle(color: textMuted),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: greenDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: border, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: greenLight,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: error),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: greenLight,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: greenLight,
        unselectedLabelColor: textMuted,
        indicatorColor: greenLight,
        labelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: greenSurface,
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 0.5),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceLight,
        contentTextStyle: GoogleFonts.inter(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Keep backward compat
  static ThemeData get darkTheme {
    isDark = true;
    return theme;
  }

  static ThemeData get lightTheme {
    isDark = false;
    return theme;
  }
}
