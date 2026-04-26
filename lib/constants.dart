import 'package:flutter/material.dart';

/// Core color constants for the app - Obsidian Vision Premium Dark Theme
class AppColors {
  static const String appVersion = 'V1.7.0';

  // Text colors
  static const Color secondaryText = Color.fromRGBO(255, 255, 255, 0.7); // 70% opacity white
  static const Color tertiaryText = Color(0xFF86868B);

  // Glass morphism - Light theme
  static const Color glassLight = Color.fromARGB(25, 255, 255, 255);

  // Obsidian theme colors (primary background)
  static const Color obsidianBlack = Color(0xFF020204);

  // Accent colors
  static const Color accentBlue = Color(0xFF0A84FF);
  static const Color accentTeal = Color(0xFF64FFDA);
  static const Color accentIndigo = Color(0xFF5E5CE6);
  static const Color accentRed = Color(0xFFFF453A);
  static const Color accentDeepPurple = Color(0xFFBF5AF2);

  static const List<Shadow> iconShadows = [
    Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 10),
  ];
}

/// Premium theme definition for Glass Keep
class AppTheme {
  final String name;
  final Color backgroundColor;
  final List<Color> blobColors;
  final Color accentColor;

  const AppTheme({
    required this.name,
    required this.backgroundColor,
    required this.blobColors,
    required this.accentColor,
  });
}

/// Collection of curated glassmorphism-optimized themes
class AppThemes {
  static const List<AppTheme> all = [
    AppTheme(
      name: 'Obsidian',
      backgroundColor: Color(0xFF020204),
      blobColors: [Color(0xFFBF5AF2), Color(0xFF0A84FF), Color(0xFF5E5CE6)],
      accentColor: Color(0xFFBF5AF2),
    ),
    AppTheme(
      name: 'Emerald Aurora',
      backgroundColor: Color(0xFF001A1A),
      blobColors: [Color(0xFF64FFDA), Color(0xFF00C853), Color(0xFF004D40)],
      accentColor: Color(0xFF64FFDA),
    ),
    AppTheme(
      name: 'Ruby Sunset',
      backgroundColor: Color(0xFF1A0000),
      blobColors: [Color(0xFFFF453A), Color(0xFFFF9F0A), Color(0xFF880E4F)],
      accentColor: Color(0xFFFF453A),
    ),
    AppTheme(
      name: 'Midnight Blue',
      backgroundColor: Color(0xFF00001A),
      blobColors: [Color(0xFF64D2FF), Color(0xFF5E5CE6), Color(0xFF0D47A1)],
      accentColor: Color(0xFF64D2FF),
    ),
    AppTheme(
      name: 'Golden Hour',
      backgroundColor: Color(0xFF1A1200),
      blobColors: [Color(0xFFFFD60A), Color(0xFFFF9F0A), Color(0xFF3E2723)],
      accentColor: Color(0xFFFFD60A),
    ),
    AppTheme(
      name: 'Cyberpunk',
      backgroundColor: Color(0xFF12001A),
      blobColors: [Color(0xFFFF375F), Color(0xFF64D2FF), Color(0xFF4A148C)],
      accentColor: Color(0xFFFF375F),
    ),
  ];
}

/// Utility class for common operations
class AppUtils {
  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate password (min 6 chars)
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
}
