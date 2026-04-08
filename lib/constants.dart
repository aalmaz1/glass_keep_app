import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Core color constants for the app - Apple Glassmorphism Light Theme
class AppColors {
  // Light background colors (Apple style)
  static const Color background = Color(0xFFF5F5F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color secondaryBackground = Color(0xFFE8E8ED);
  
  // Text colors
  static const Color primaryText = Color(0xFF1D1D1F);
  static const Color secondaryText = Color(0xFF6E6E73);
  static const Color tertiaryText = Color(0xFF86868B);
  
  // Glass morphism - Light theme
  static const Color glassLight = Color.fromARGB(48, 255, 255, 255);
  static const Color glassDark = Color.fromARGB(20, 0, 0, 0);
  static const Color glassBorder = Color.fromARGB(25, 0, 0, 0);
  
  // Utilities
  static const Color white24 = Color.fromARGB(61, 255, 255, 255);
  static const Color white12 = Color.fromARGB(31, 255, 255, 255);
  static const Color black12 = Color.fromARGB(31, 0, 0, 0);
  static const Color black24 = Color.fromARGB(61, 0, 0, 0);
  
  // Accent colors
  static const Color accentBlue = Color(0xFF007AFF);
  static const Color accentRed = Color(0xFFFF3B30);
  static const Color accentGreen = Color(0xFF34C759);
  static const Color accentOrange = Color(0xFFFF9500);
  static const Color accentPurple = Color(0xFFAF52DE);
}

/// Responsive dimensions helper
class ResponsiveDimensions {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  
  static const double paddingXs = 8.0;
  static const double paddingSm = 12.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;
  static const double paddingXl = 32.0;
  
  static const double borderRadiusSm = 8.0;
  static const double borderRadiusMd = 12.0;
  static const double borderRadiusLg = 20.0;
  static const double borderRadiusXl = 30.0;
  
  /// Get horizontal padding based on screen width
  static double getHorizontalPadding(Size size) {
    if (size.width < mobileBreakpoint) {
      return paddingMd;
    } else if (size.width < tabletBreakpoint) {
      return paddingLg;
    } else {
      return paddingXl;
    }
  }
  
  /// Get grid columns based on screen width
  static int getGridColumns(Size size) {
    if (size.width < mobileBreakpoint) {
      return 2;
    } else if (size.width < tabletBreakpoint) {
      return 3;
    } else {
      return 4;
    }
  }
  
  /// Get font size multiplier for responsive typography
  static double getFontSizeMultiplier(Size size) {
    if (size.width < mobileBreakpoint) {
      return 1.0;
    } else if (size.width < tabletBreakpoint) {
      return 1.1;
    } else {
      return 1.2;
    }
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
  
  /// Log only in debug mode
  static void debugLog(String msg) {
    if (kDebugMode) {
      debugPrint('[GlassKeep] $msg');
    }
  }
}
