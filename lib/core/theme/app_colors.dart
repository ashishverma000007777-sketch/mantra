import 'package:flutter/material.dart';

/// Centralized design tokens for Mantra's "Warm Editorial + Premium Slow Dating" identity.
/// Philosophy: "Know them before you show yourself."
class AppColors {
  AppColors._();

  // Brand Accent
  static const Color primary = Color(0xFFC66F55);
  static const Color primaryLight = Color(0xFFDF937E);
  static const Color primaryDark = Color(0xFF96432C);

  // Soft Accent
  static const Color surfaceVariant = Color(0xFFF2E2DB);
  static const Color softAccent = Color(0xFFF2E2DB);

  // Secondary - Sage Green (Mindful Balance)
  static const Color secondary = Color(0xFF7A9E7E);
  static const Color secondaryLight = Color(0xFFB5D4B8);
  static const Color secondaryDark = Color(0xFF4A7050);

  // Trust & Verification - Sage / Trust Green
  static const Color trust = Color(0xFF438C70);
  static const Color trustLight = Color(0xFFBFE0D2);
  static const Color success = Color(0xFF438C70);
  static const Color successLight = Color(0xFFD3EFE3);

  // Backgrounds & Surfaces (Light)
  static const Color background = Color(0xFFFAF6F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE7DAD3);
  static const Color border = Color(0xFFE7DAD3);
  static const Color borderLight = Color(0xFFF0E7E2);

  // Backgrounds & Surfaces (Dark - for intentional contrast)
  static const Color darkBackground = Color(0xFF1E1614);
  static const Color darkSurface = Color(0xFF2C2220);
  static const Color darkSurfaceVariant = Color(0xFF3D322F);
  static const Color darkBorder = Color(0xFF4A3E3B);

  // Text - Light mode
  static const Color textPrimary = Color(0xFF30221E);
  static const Color textSecondary = Color(0xFF887670);
  static const Color textMuted = Color(0xFFAFA39F);
  static const Color textLight = Color(0xFFFAF6F2);

  // Text - Dark mode
  static const Color textMutedDark = Color(0xFF9E8D87);

  // Semantic
  static const Color warning = Color(0xFFD9822B);
  static const Color warningLight = Color(0xFFFCE6CA);
  static const Color error = Color(0xFFC94A4A);
  static const Color errorLight = Color(0xFFF9DADA);
  static const Color info = Color(0xFF438C70);

  // Special Accents
  static const Color shadow = Color(0x1430221E);
  static const Color overlay = Color(0x7330221E);
  static const Color gold = Color(0xFFC89D42);
  static const Color platinum = Color(0xFF7E8F9D);

  // Editorial Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFFD88068)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFAF6F2), Color(0xFFF2E2DB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1E1614), Color(0xFF2C2220)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient trustGradient = LinearGradient(
    colors: [trust, Color(0xFF5EAA8D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
