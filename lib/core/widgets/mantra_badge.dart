import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum MantraBadgeVariant { trust, primary, soft, outline, warning }

/// Subtle pill badge for trust score, alignment, categories, and verified markers.
class MantraBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final MantraBadgeVariant variant;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const MantraBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = MantraBadgeVariant.soft,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
  });

  factory MantraBadge.trust({
    required double score,
    double fontSize = 11.5,
    EdgeInsetsGeometry? padding,
  }) {
    return MantraBadge(
      label: 'Trust ${score.round()}%',
      icon: Icons.verified_user_outlined,
      variant: MantraBadgeVariant.trust,
      fontSize: fontSize,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
    );
  }

  factory MantraBadge.compatibility({
    required int score,
    double fontSize = 11.5,
    EdgeInsetsGeometry? padding,
  }) {
    return MantraBadge(
      label: '$score% Aligned',
      icon: Icons.bubble_chart_outlined,
      variant: MantraBadgeVariant.primary,
      fontSize: fontSize,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;

    switch (variant) {
      case MantraBadgeVariant.trust:
        bg = AppColors.trust.withOpacity(0.15);
        fg = AppColors.trust;
        border = Border.all(color: AppColors.trust.withOpacity(0.35), width: 1);
        break;
      case MantraBadgeVariant.primary:
        bg = AppColors.primary.withOpacity(0.15);
        fg = AppColors.primary;
        border = Border.all(color: AppColors.primary.withOpacity(0.35), width: 1);
        break;
      case MantraBadgeVariant.soft:
        bg = AppColors.surfaceSecondary;
        fg = AppColors.textSecondary;
        border = Border.all(color: AppColors.borderSubtle, width: 1);
        break;
      case MantraBadgeVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.textPrimary;
        border = Border.all(color: AppColors.border, width: 1);
        break;
      case MantraBadgeVariant.warning:
        bg = AppColors.warning.withOpacity(0.15);
        fg = AppColors.warning;
        border = Border.all(color: AppColors.warning.withOpacity(0.35), width: 1);
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
