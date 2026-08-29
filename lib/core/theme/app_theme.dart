import 'package:flutter/material.dart';

/// Design System Specification (Cosmic & Daylight Lavender Palette)
class AppTheme {
  AppTheme._();

  // ==========================================
  // 01. CORE COLOR TOKENS (Dark Cosmic Theme)
  // ==========================================
  static const Color darkBg = Color(0xFF090811);
  static const Color darkSurfaceStrong = Color(0xFF191624);
  static const Color darkSurfaceGlass = Color(0xCC191624); // ~80% opacity
  static const Color darkText = Color(0xFFF7F4FF);
  static const Color darkTextSoft = Color(0xFFC2BBCF);
  static const Color darkMuted = Color(0xFF8C8599);
  static const Color darkBorder = Color(0x1AFFFFFF); // rgba(255, 255, 255, 0.10)

  // ==========================================
  // 02. LIGHT THEME OVERRIDES (Daylight Lavender)
  // ==========================================
  static const Color lightBg = Color(0xFFF3F0F8);
  static const Color lightSurface = Color(0xCCFFFFFF); // rgba(255, 255, 255, 0.80)
  static const Color lightSurfaceStrong = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1D1728);
  static const Color lightTextSoft = Color(0xFF4D445C);
  static const Color lightMuted = Color(0xFF7E748E);
  static const Color lightBorder = Color(0x1C2B1B43); // rgba(43, 27, 67, 0.11)

  // ==========================================
  // 03. BRAND & ACCENT TOKENS
  // ==========================================
  /// Electric Violet brand accent
  static const Color brand = Color(0xFF9D7BFF);

  /// Deep Purple buttons & active pills
  static const Color brandStrong = Color(0xFF7951ED);

  /// Warm Amber (Awards, Star, Study Coins)
  static const Color accent = Color(0xFFF3A559);

  /// Magenta glow & sticker tags
  static const Color pink = Color(0xFFEC6CB6);

  /// Mint Green (Success & verified)
  static const Color green = Color(0xFF5FD7A6);

  /// Coral Red (Errors, wrong choices, warnings)
  static const Color danger = Color(0xFFFF6F7D);

  // ==========================================
  // COMPATIBILITY ALIASES (Clean Architecture Slices)
  // ==========================================
  static const Color primaryGreen = brandStrong;
  static const Color primaryGreenDark = Color(0xFF5C35D6);
  static const Color primaryGreenLight = brand;

  static const Color accentGold = accent;
  static const Color accentGoldLight = Color(0xFFF7BD84);
  static const Color accentGoldDark = Color(0xFFDD8832);

  static const Color bgLight = lightBg;
  static const Color surfaceLight = lightSurfaceStrong;
  static const Color textDark = lightText;
  static const Color textMuted = lightMuted;

  static const Color bgDark = darkBg;
  static const Color surfaceDark = darkSurfaceStrong;
  static const Color textLight = darkText;
  static const Color textMutedDark = darkMuted;

  static const Color successGreen = green;
  static const Color errorRed = danger;
  static const Color warningOrange = accent;
  static const Color infoBlue = brand;

  // ==========================================
  // 04. CORNER RADII SYSTEM
  // ==========================================
  static const double radiusSm = 12.0; // Badges, chips, tags
  static const double radiusMd = 18.0; // Input fields, select boxes
  static const double radiusLg = 28.0; // Cards, dialogs, heroes
  static const double radiusXl = 38.0; // Floating hero collages
  static const double radiusPill = 999.0; // Filter pills, category tags

  // ==========================================
  // 05. ELEVATION & SHADOWS
  // ==========================================
  static List<BoxShadow> get cardShadowDark => [
        const BoxShadow(
          color: Color(0x56000000), // rgba(0, 0, 0, 0.34)
          blurRadius: 40,
          offset: Offset(0, 16),
        ),
      ];

  static List<BoxShadow> get cardShadowLight => [
        const BoxShadow(
          color: Color(0x14000000), // rgba(0, 0, 0, 0.08)
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get brandGlow => [
        const BoxShadow(
          color: Color(0x478A5BFF), // rgba(138, 91, 255, 0.28)
          blurRadius: 24,
          offset: Offset(0, 6),
        ),
      ];

  // ==========================================
  // 06. THEME DATA (Light - Daylight Lavender)
  // ==========================================
  static ThemeData get lightTheme {
    const baseColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: brandStrong,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.black,
      tertiary: pink,
      onTertiary: Colors.white,
      error: danger,
      onError: Colors.white,
      surface: lightSurfaceStrong,
      onSurface: lightText,
      surfaceContainerHighest: lightBg,
      outline: Color(0x2E431B6B),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: baseColorScheme,
      scaffoldBackgroundColor: lightBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurfaceStrong,
        elevation: 0,
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandStrong,
          side: const BorderSide(color: brandStrong, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceStrong,
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
          borderSide: const BorderSide(color: brandStrong, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  // ==========================================
  // 07. THEME DATA (Dark - Cosmic Palette)
  // ==========================================
  static ThemeData get darkTheme {
    const baseColorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: brand,
      onPrimary: darkBg,
      secondary: accent,
      onSecondary: Colors.black,
      tertiary: pink,
      onTertiary: Colors.white,
      error: danger,
      onError: Colors.white,
      surface: darkSurfaceStrong,
      onSurface: darkText,
      surfaceContainerHighest: darkBg,
      outline: Color(0x339D7BFF),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: baseColorScheme,
      scaffoldBackgroundColor: darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceStrong,
        elevation: 0,
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brand,
          side: const BorderSide(color: brand, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceStrong,
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
          borderSide: const BorderSide(color: brand, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
