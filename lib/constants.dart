import 'package:flutter/material.dart';

/// Core color constants for the app - Obsidian Vision Premium Dark Theme
class AppColors {
  // Text colors
  static const Color secondaryText = Color.fromRGBO(255, 255, 255, 0.7); // 70% opacity white
  static const Color tertiaryText = Color(0xFF86868B);

  // Glass morphism - Light theme
  static const Color glassLight = Color.fromARGB(25, 255, 255, 255);

  // Obsidian theme colors (primary background)
  static const Color obsidianDark = Color(0xFF050508);

  // Accent colors
  static const Color accentBlue = Color(0xFF007AFF);
  static const Color accentTeal = Color(0xFF64FFDA);
  static const Color accentIndigo = Color(0xFF5E5CE6);
  static const Color accentRed = Color(0xFFFF453A);
  static const Color accentPurple = Color(0xFFBF5AF2);

  static const List<Shadow> iconShadows = [
    Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 10),
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
