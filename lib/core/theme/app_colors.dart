import 'package:flutter/material.dart';

class AppColors {
  // Brand colors - Earthy Olive & Warm Cream Palette
  // Core palette requested:
  // #F8F3D9 (Alabaster Cream)
  // #EBE5C2 (Pale Almond Sand)
  // #B9B28A (Muted Khaki Olive)
  // #504B38 (Deep Espresso Olive)

  static const Color primary = Color(0xFF504B38);
  static const Color primaryDark = Color(0xFF383427);
  static const Color primaryLight = Color(0xFF6E674F);
  static const Color secondary = Color(0xFFB9B28A);
  static const Color accent = Color(0xFFB9B28A);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF504B38), Color(0xFF6E674F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF8F3D9), Color(0xFFEBE5C2)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAF7E6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF504B38), Color(0xFF6E674F), Color(0xFFB9B28A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Functional colors - harmonious with the earthy palette
  static const Color success = Color(0xFF3E7B54);
  static const Color successLight = Color(0xFFE2EFE7);
  static const Color warning = Color(0xFFC48827);
  static const Color warningLight = Color(0xFFFAF2DF);
  static const Color error = Color(0xFFB84233);
  static const Color errorLight = Color(0xFFF9E8E5);
  static const Color info = Color(0xFF4A7298);
  static const Color infoLight = Color(0xFFE7EFF7);

  // Main Palette
  static const Color background = Color(0xFFF8F3D9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEBE5C2);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFB9B28A);
  static const Color borderLight = Color(0xFFE2DCBC);
  static const Color divider = Color(0xFFE0D9B0);

  // Text colors - tailored for high contrast readability on cream
  static const Color textPrimary = Color(0xFF28251C);
  static const Color textSecondary = Color(0xFF756F52);
  static const Color textMuted = Color(0xFF9E9770);
  static const Color textOnPrimary = Color(0xFFF8F3D9);

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF504B38).withValues(alpha: 0.05),
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
          color: const Color(0xFF504B38).withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: const Color(0xFF504B38).withValues(alpha: 0.28),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  // Backward compatibility tokens
  static const Color lightBackground = Color(0xFFF8F3D9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEBE5C2);
  static const Color lightBorder = Color(0xFFB9B28A);
  static const Color lightTextPrimary = Color(0xFF28251C);
  static const Color lightTextSecondary = Color(0xFF756F52);
  static const Color lightTextMuted = Color(0xFF9E9770);

  static const Color darkBackground = Color(0xFFF8F3D9);
  static const Color darkSurface = Color(0xFFFFFFFF);
  static const Color darkSurfaceVariant = Color(0xFFEBE5C2);
  static const Color darkBorder = Color(0xFFB9B28A);
  static const Color darkTextPrimary = Color(0xFF28251C);
  static const Color darkTextSecondary = Color(0xFF756F52);
  static const Color darkTextMuted = Color(0xFF9E9770);
}
