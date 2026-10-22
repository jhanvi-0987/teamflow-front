import 'package:flutter/material.dart';

class AppColors {
  // Brand colors requested by user:
  // Primary Burgundy: #790D16
  // Secondary Sand Champagne: #E5D3AF
  // Background Ivory: #F5EFE1
  static const Color primary = Color(0xFF790D16);
  static const Color primaryDark = Color(0xFF5A080F);
  static const Color primaryLight = Color(0xFF9E1B27);
  static const Color secondary = Color(0xFFE5D3AF);
  static const Color accent = Color(0xFF790D16);

  // Functional colors
  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFB45309);
  static const Color error = Color(0xFF991B1B);
  static const Color info = Color(0xFF790D16);

  // Main Palette (Warm Light / Ivory Theme)
  static const Color background = Color(0xFFF5EFE1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFAF6EE);
  static const Color border = Color(0xFFE5D3AF);
  static const Color textPrimary = Color(0xFF260407);
  static const Color textSecondary = Color(0xFF6B5E4B);
  static const Color textMuted = Color(0xFF9B8D78);

  // Light Theme palette
  static const Color lightBackground = Color(0xFFF5EFE1);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFFAF6EE);
  static const Color lightBorder = Color(0xFFE5D3AF);
  static const Color lightTextPrimary = Color(0xFF260407);
  static const Color lightTextSecondary = Color(0xFF6B5E4B);
  static const Color lightTextMuted = Color(0xFF9B8D78);

  // Forwarding dark tokens to the new light warm palette for complete consistency
  static const Color darkBackground = Color(0xFFF5EFE1);
  static const Color darkSurface = Color(0xFFFFFFFF);
  static const Color darkSurfaceVariant = Color(0xFFFAF6EE);
  static const Color darkBorder = Color(0xFFE5D3AF);
  static const Color darkTextPrimary = Color(0xFF260407);
  static const Color darkTextSecondary = Color(0xFF6B5E4B);
  static const Color darkTextMuted = Color(0xFF9B8D78);
}

