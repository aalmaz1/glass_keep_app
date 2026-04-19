import 'package:flutter/material.dart';

/// Core color constants for the app - Obsidian Vision Premium Dark Theme
class AppColors {
  // Obsidian dark background colors
  static const Color background = Color(0xFF0A0A0C);

  // Text colors
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color.fromRGBO(255, 255, 255, 0.7); // 70% opacity white
  static const Color tertiaryText = Color(0xFF86868B);

  // Glass morphism - Light theme
  static const Color glassLight = Color.fromARGB(48, 255, 255, 255);

  // Obsidian theme colors
  static const Color obsidianDark = Color(0xFF0A0A0C);

  // Accent colors
  static const Color accentBlue = Color(0xFF1FA4FF);
  static const Color accentRed = Color(0xFFFF3B30);
  static const Color accentGreen = Color(0xFF34C759);
  static const Color accentOrange = Color(0xFFFF9500);
  static const Color accentPurple = Color(0xFFC273FF);

  static const List<Shadow> iconShadows = [
    Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 10),
  ];
}

/// Responsive dimensions helper
class ResponsiveDimensions {
  static const double gridPadding = 24.0;
  static const double gridGap = 18.0;
  static const double cardMinWidth = 300.0;
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
