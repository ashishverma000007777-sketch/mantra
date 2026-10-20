import 'package:flutter/material.dart';

/// Centralized design tokens for Mantra's "Dark Cinematic Editorial Slow Dating" identity.
/// Philosophy: "Know them before you show yourself."
class AppColors {
  AppColors._();

  // Primary Accent — Muted Warm Gold (Refined & Cinematic)
  static const Color primary = Color(0xFFD6B27A);
  static const Color primaryLight = Color(0xFFE7D5B5);
  static const Color primaryDark = Color(0xFFA58045);
  static const Color accent = Color(0xFFD6B27A);
  static const Color accentLight = Color(0xFFE7D5B5);
  static const Color accentDark = Color(0xFFA58045);

  // Secondary Accent — Sage / Mint (Mindful Balance & Growth)
  static const Color secondary = Color(0xFF8BBFA9);
  static const Color secondaryLight = Color(0xFFB5D9CB);
  static const Color secondaryDark = Color(0xFF5B8F7A);
  static const Color secondaryAccent = Color(0xFF8BBFA9);

  // Trust & Verification — Editorial Sage Green
  static const Color trust = Color(0xFF8BBFA9);
  static const Color trustLight = Color(0xFFB5D9CB);
  static const Color success = Color(0xFF8BBFA9);
  static const Color successLight = Color(0xFFD3EFE3);

  // Canvas & Surfaces — Near-Black / Midnight Charcoal
  static const Color background = Color(0xFF080B0D);
  static const Color backgroundSecondary = Color(0xFF101619);
  static const Color surface = Color(0xFF171E21);
  static const Color surfaceSecondary = Color(0xFF20292C);
  static const Color surfaceVariant = Color(0xFF20292C);
  static const Color surfaceSubtle = Color(0xFF12191C);

  // Legacy compatibility aliases
  static const Color darkBackground = Color(0xFF080B0D);
  static const Color darkSurface = Color(0xFF171E21);
  static const Color darkSurfaceVariant = Color(0xFF20292C);
  static const Color darkBorder = Color(0xFF34403D);

  // Borders & Dividers
  static const Color border = Color(0xFF34403D);
  static const Color borderSubtle = Color(0xFF1F292B);
  static const Color borderLight = Color(0xFF263236);
  static const Color borderHighlight = Color(0x33D6B27A);
  static const Color divider = Color(0xFF1F292B);

  // Typography — Ivory & Atmospheric Grays
  static const Color textPrimary = Color(0xFFF5F1E9);
  static const Color textSecondary = Color(0xFFA9AFAC);
  static const Color textMuted = Color(0xFF747E7A);
  static const Color textLight = Color(0xFFF5F1E9);
  static const Color textMutedDark = Color(0xFF747E7A);

  // Semantic
  static const Color error = Color(0xFFD96C72);
  static const Color errorLight = Color(0xFF5A2528);
  static const Color warning = Color(0xFFD9A05B);
  static const Color warningLight = Color(0xFF543E1F);
  static const Color info = Color(0xFF8BBFA9);

  // Cinematic Highlights & Overlays
  static const Color gold = Color(0xFFD6B27A);
  static const Color goldLight = Color(0xFFE7D5B5);
  static const Color softAccent = Color(0x1AD6B27A);
  static const Color shadow = Color(0x66000000);
  static const Color overlay = Color(0xB3080B0D);
  static const Color overlayLight = Color(0x80080B0D);
  static const Color surfaceGlow = Color(0x0DD6B27A);

  // Shimmer
  static const Color shimmerBase = Color(0xFF171E21);
  static const Color shimmerHighlight = Color(0xFF20292C);

  // Botanical / Connection Garden
  static const Color leafPrimary = Color(0xFF8BBFA9);
  static const Color leafSecondary = Color(0xFF5B8F7A);
  static const Color bloomGold = Color(0xFFD6B27A);
}
