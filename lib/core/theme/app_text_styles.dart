import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Lora Serif for Warm Editorial Headings & Intimate Moments
  static TextStyle _serif(
    double size,
    FontWeight weight,
    Color color, {
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.lora(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing ?? (size >= 24 ? -0.5 : -0.2),
      height: height ?? 1.25,
    );
  }

  // Plus Jakarta Sans for UI, Readability & Precision
  static TextStyle _sans(
    double size,
    FontWeight weight,
    Color color, {
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing ?? (size > 20 ? -0.3 : 0.1),
      height: height ?? 1.4,
    );
  }

  static TextTheme get textTheme => TextTheme(
        displayLarge: _serif(32, FontWeight.w700, AppColors.textPrimary),
        displayMedium: _serif(28, FontWeight.w700, AppColors.textPrimary),
        displaySmall: _serif(24, FontWeight.w600, AppColors.textPrimary),
        headlineLarge: _serif(22, FontWeight.w600, AppColors.textPrimary),
        headlineMedium: _serif(20, FontWeight.w600, AppColors.textPrimary),
        headlineSmall: _sans(18, FontWeight.w600, AppColors.textPrimary),
        titleLarge: _sans(16, FontWeight.w600, AppColors.textPrimary),
        titleMedium: _sans(15, FontWeight.w600, AppColors.textPrimary),
        titleSmall: _sans(13, FontWeight.w600, AppColors.textPrimary),
        bodyLarge: _sans(15, FontWeight.w400, AppColors.textPrimary),
        bodyMedium: _sans(14, FontWeight.w400, AppColors.textPrimary),
        bodySmall: _sans(12, FontWeight.w400, AppColors.textSecondary),
        labelLarge: _sans(14, FontWeight.w600, AppColors.textPrimary),
        labelMedium: _sans(12, FontWeight.w500, AppColors.textSecondary),
        labelSmall: _sans(11, FontWeight.w500, AppColors.textMuted),
      );

  static TextTheme get darkTextTheme => TextTheme(
        displayLarge: _serif(32, FontWeight.w700, AppColors.textLight),
        displayMedium: _serif(28, FontWeight.w700, AppColors.textLight),
        displaySmall: _serif(24, FontWeight.w600, AppColors.textLight),
        headlineLarge: _serif(22, FontWeight.w600, AppColors.textLight),
        headlineMedium: _serif(20, FontWeight.w600, AppColors.textLight),
        headlineSmall: _sans(18, FontWeight.w600, AppColors.textLight),
        titleLarge: _sans(16, FontWeight.w600, AppColors.textLight),
        titleMedium: _sans(15, FontWeight.w600, AppColors.textLight),
        titleSmall: _sans(13, FontWeight.w600, AppColors.textLight),
        bodyLarge: _sans(15, FontWeight.w400, AppColors.textLight),
        bodyMedium: _sans(14, FontWeight.w400, AppColors.textLight),
        bodySmall: _sans(12, FontWeight.w400, AppColors.textMutedDark),
        labelLarge: _sans(14, FontWeight.w600, AppColors.textLight),
        labelMedium: _sans(12, FontWeight.w500, AppColors.textMutedDark),
        labelSmall: _sans(11, FontWeight.w500, AppColors.textMutedDark),
      );

  // Editorial helpers
  static TextStyle get heroDisplay => _serif(28, FontWeight.w600, AppColors.textPrimary);
  static TextStyle get heroDisplayDark => _serif(28, FontWeight.w600, AppColors.textLight);
  static TextStyle get quoteText => GoogleFonts.lora(
        fontSize: 16,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.45,
      );
}
