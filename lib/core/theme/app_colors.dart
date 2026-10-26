import 'package:flutter/material.dart';

class AppColors {
  // Brand colors - Refined Burgundy palette with richer tones
  static const Color primary = Color(0xFF8B1A2B);
  static const Color primaryDark = Color(0xFF6A0F1D);
  static const Color primaryLight = Color(0xFFAD3347);
  static const Color secondary = Color(0xFFE5D3AF);
  static const Color accent = Color(0xFFD4A373);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B1A2B), Color(0xFFB8334A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF5EFE1), Color(0xFFEDE4D0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFCF9F3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF8B1A2B), Color(0xFFB8334A), Color(0xFFD4A373)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Functional colors - more vibrant
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Main Palette (Warm Light / Ivory Theme)
  static const Color background = Color(0xFFF7F2E8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFAF7F0);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8DCCA);
  static const Color borderLight = Color(0xFFF0E8DA);
  static const Color divider = Color(0xFFF0E8DA);

  // Text colors - better contrast hierarchy
  static const Color textPrimary = Color(0xFF1A0A0D);
  static const Color textSecondary = Color(0xFF6B5C50);
  static const Color textMuted = Color(0xFF9B8E82);
  static const Color textOnPrimary = Color(0xFFFFF8F0);

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF8B1A2B).withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: const Color(0xFF8B1A2B).withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: const Color(0xFF8B1A2B).withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  // Legacy tokens (kept for backward compatibility)
  static const Color lightBackground = Color(0xFFF7F2E8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFFAF7F0);
  static const Color lightBorder = Color(0xFFE8DCCA);
  static const Color lightTextPrimary = Color(0xFF1A0A0D);
  static const Color lightTextSecondary = Color(0xFF6B5C50);
  static const Color lightTextMuted = Color(0xFF9B8E82);

  // Forwarding dark tokens to the light warm palette for consistency
  static const Color darkBackground = Color(0xFFF7F2E8);
  static const Color darkSurface = Color(0xFFFFFFFF);
  static const Color darkSurfaceVariant = Color(0xFFFAF7F0);
  static const Color darkBorder = Color(0xFFE8DCCA);
  static const Color darkTextPrimary = Color(0xFF1A0A0D);
  static const Color darkTextSecondary = Color(0xFF6B5C50);
  static const Color darkTextMuted = Color(0xFF9B8E82);
}
