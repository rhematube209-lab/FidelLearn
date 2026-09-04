import 'package:flutter/material.dart';

/// Modern Professional Design System (Deep Slate & Daylight Porcelain)
class AppTheme {
  AppTheme._();

  // ==========================================
  // 01. CORE COLOR TOKENS (Deep Slate Dark Theme)
  // ==========================================
  static const Color darkBg = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceStrong = Color(0xFF161F30);
  static const Color darkSurfaceGlass = Color(0xF2111827); // ~95% opacity
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkTextSoft = Color(0xFF94A3B8);
  static const Color darkMuted = Color(0xFF64748B);
  static const Color darkBorder = Color(0xFF1E293B);
  static const Color darkBorderSubtle = Color(0x33334155);

  // ==========================================
  // 02. LIGHT THEME OVERRIDES (Daylight Porcelain)
  // ==========================================
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceStrong = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFF1F5F9);
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightTextSoft = Color(0xFF475569);
  static const Color lightMuted = Color(0xFF94A3B8);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderSubtle = Color(0xFFF1F5F9);

  // ==========================================
  // 03. BRAND & ACCENT TOKENS
  // ==========================================
  /// Royal Indigo brand accent
  static const Color brand = Color(0xFF6366F1);

  /// Deep Indigo for primary actions
  static const Color brandStrong = Color(0xFF4F46E5);

  /// Subtle brand tint for badges/chips
  static const Color brandSubtle = Color(0xFFEEF2FF);

  /// Ethiopian Amber Gold (Study Coins, Awards, Streaks)
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentSubtle = Color(0xFFFEF3C7);

  /// Emerald Green (Success, Mastery, Verified Answers, Offline Ready)
  static const Color green = Color(0xFF10B981);
  static const Color greenDark = Color(0xFF059669);
  static const Color greenSubtle = Color(0xFFD1FAE5);

  /// Coral Crimson (Mistakes, Errors, Timer Warnings)
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerDark = Color(0xFFDC2626);
  static const Color dangerSubtle = Color(0xFFFEE2E2);

  /// Vibrant Sky Blue (Informational chips, secondary badges)
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSubtle = Color(0xFFDBEAFE);

  /// Warm Rose (Streaks, Badges)
  static const Color pink = Color(0xFFEC4899);

  // ==========================================
  // COMPATIBILITY ALIASES (Clean Architecture Slices)
  // ==========================================
  static const Color primaryGreen = brandStrong;
  static const Color primaryGreenDark = Color(0xFF4338CA);
  static const Color primaryGreenLight = brand;

  static const Color accentGold = accent;
  static const Color accentGoldLight = Color(0xFFFBBF24);
  static const Color accentGoldDark = accentDark;

  static const Color bgLight = lightBg;
  static const Color surfaceLight = lightSurface;
  static const Color textDark = lightText;
  static const Color textMuted = lightMuted;

  static const Color bgDark = darkBg;
  static const Color surfaceDark = darkSurface;
  static const Color textLight = darkText;
  static const Color textMutedDark = darkMuted;

  static const Color successGreen = green;
  static const Color errorRed = danger;
  static const Color warningOrange = accent;
  static const Color infoBlue = info;

  // ==========================================
  // 04. CORNER RADII SYSTEM
  // ==========================================
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0; // Badges, chips, small buttons
  static const double radiusMd =
      14.0; // Input fields, select boxes, choice options
  static const double radiusLg = 20.0; // Cards, modals, dialogs
  static const double radiusXl = 28.0; // Hero banners, floating overlays
  static const double radiusPill = 999.0; // Filter pills, circular badges

  // ==========================================
  // 05. ELEVATION & SHADOWS
  // ==========================================
  static List<BoxShadow> get cardShadowDark => [
        const BoxShadow(
          color: Color(0x33000000), // subtle dark ambient
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get cardShadowLight => [
        const BoxShadow(
          color: Color(0x0A0F172A), // rgba(15, 23, 42, 0.04)
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
        const BoxShadow(
          color: Color(0x050F172A), // ambient
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get brandGlow => [
        BoxShadow(
          color: brand.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  // ==========================================
  // 06. THEME DATA (Light - Daylight Porcelain)
  // ==========================================
  static ThemeData get lightTheme {
    const baseColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: brandStrong,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.black,
      tertiary: green,
      onTertiary: Colors.white,
      error: danger,
      onError: Colors.white,
      surface: lightSurface,
      onSurface: lightText,
      surfaceContainerHighest: lightSurfaceMuted,
      outline: lightBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: baseColorScheme,
      scaffoldBackgroundColor: lightBg,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        foregroundColor: lightText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandStrong,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightText,
          side: const BorderSide(color: lightBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandStrong,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: brandStrong, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ==========================================
  // 07. THEME DATA (Dark - Deep Slate)
  // ==========================================
  static ThemeData get darkTheme {
    const baseColorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: brand,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.black,
      tertiary: green,
      onTertiary: Colors.white,
      error: danger,
      onError: Colors.white,
      surface: darkSurface,
      onSurface: darkText,
      surfaceContainerHighest: darkSurfaceStrong,
      outline: darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: baseColorScheme,
      scaffoldBackgroundColor: darkBg,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandStrong,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkText,
          side: const BorderSide(color: darkBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: brand, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
