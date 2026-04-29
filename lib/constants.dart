import 'package:flutter/material.dart';

/// Core color constants for the app - Luxury Collection Premium Themes
class AppColors {
  static const String appVersion = 'V1.8.0';

  // Text colors
  static const Color secondaryText = Color.fromRGBO(255, 255, 255, 0.7); // 70% opacity white
  static const Color tertiaryText = Color(0xFF86868B);

  // Glass morphism - Light theme
  static const Color glassLight = Color.fromARGB(25, 255, 255, 255);

  // Luxury collection base colors
  // Note: obsidianBlack is set to Titanium's background for the default "Luxury" first impression
  static const Color obsidianBlack = Color(0xFF1A1A1A); 
  static const Color pureObsidian = Color(0xFF020204);

  // Accent colors - Refined Luxury Palette (V1.8.0)
  // accentDeepPurple is set to Titanium's accent for the default first impression
  static const Color accentBlue = Color(0xFF8ECAE6);
  static const Color accentTeal = Color(0xFF99F6E4);
  static const Color accentIndigo = Color(0xFFA5B4FC);
  static const Color accentRed = Color(0xFFFDA4AF);
  static const Color accentDeepPurple = Color(0xFFE1E1E6); 

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

/// Collection of curated glassmorphism-optimized themes: The Luxury Collection
class AppThemes {
  static const List<AppTheme> all = [
    AppTheme(
      name: 'Titanium',
      backgroundColor: Color(0xFF1A1A1A),
      blobColors: [Color(0xFF2C2C2E), Color(0xFF3A3A3C), Color(0xFF48484A)],
      accentColor: Color(0xFFE1E1E6),
    ),
    AppTheme(
      name: 'Royal Navy',
      backgroundColor: Color(0xFF0A1128),
      blobColors: [Color(0xFF001F3F), Color(0xFF003366), Color(0xFF004080)],
      accentColor: Color(0xFF8ECAE6),
    ),
    AppTheme(
      name: 'Champagne Gold',
      backgroundColor: Color(0xFF1C1917),
      blobColors: [Color(0xFF44403C), Color(0xFF78716C), Color(0xFFA8A29E)],
      accentColor: Color(0xFFF5E1C8),
    ),
    AppTheme(
      name: 'Nordic Ice',
      backgroundColor: Color(0xFF020617),
      blobColors: [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF475569)],
      accentColor: Color(0xFFF1F5F9),
    ),
    AppTheme(
      name: 'Midnight Forest',
      backgroundColor: Color(0xFF061612),
      blobColors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF0F766E)],
      accentColor: Color(0xFFA7F3D0),
    ),
    AppTheme(
      name: 'Pure Obsidian',
      backgroundColor: Color(0xFF020204),
      blobColors: [Color(0xFF171717), Color(0xFF262626), Color(0xFF404040)],
      accentColor: Color(0xFFFAFAFA),
    ),
  ];

  static AppTheme getThemeByName(String name) {
    return all.firstWhere(
      (theme) => theme.name == name,
      orElse: () => all[0],
    );
  }
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
