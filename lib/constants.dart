import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Core color constants for the app
class AppColors {
  static const Color background = Color(0xFF0A0A14);
  static const Color surface = Color(0xFF1E1E2E);
  
  // Glass morphism
  static const Color glassLight = Color.fromARGB(64, 255, 255, 255);
  static const Color glassDark = Color.fromARGB(26, 0, 0, 0);
  
  // Utilities
  static const Color white24 = Color.fromARGB(61, 255, 255, 255);
  static const Color white12 = Color.fromARGB(31, 255, 255, 255);
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
