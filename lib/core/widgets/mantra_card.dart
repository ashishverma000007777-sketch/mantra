import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Solid, dimensional card with controlled borders and subtle elevation.
class MantraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double borderRadius;
  final bool hasShadow;
  final bool hasGlow;

  const MantraCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.borderColor,
    this.borderRadius = AppSpacing.radiusLG,
    this.hasShadow = false,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = BorderSide(
      color: borderColor ?? AppColors.border,
      width: 1,
    );

    final decoration = BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.fromBorderSide(border),
      boxShadow: [
        if (hasShadow)
          const BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        if (hasGlow)
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 1,
          ),
      ],
    );

    Widget content = Container(
      margin: margin,
      decoration: decoration,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Cinematic Image Card with layered background and atmospheric gradient scrim.
class MantraImageCard extends StatelessWidget {
  final String imagePath;
  final bool isAsset;
  final Widget child;
  final double? height;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const MantraImageCard({
    super.key,
    required this.imagePath,
    this.isAsset = true,
    required this.child,
    this.height,
    this.onTap,
    this.borderRadius = AppSpacing.radiusLG,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: isAsset
                ? Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceVariant,
                    ),
                  )
                : Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceVariant,
                    ),
                  ),
          ),
          // Atmospheric Gradient Scrim
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withOpacity(0.15),
                    AppColors.background.withOpacity(0.65),
                    AppColors.background.withOpacity(0.95),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                border: Border.all(color: AppColors.border, width: 1),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
          // Foreground Content
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                height: height,
                padding: padding,
                alignment: Alignment.bottomLeft,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Editorial Section Header with Lora serif title, optional subtitle, and optional action.
class MantraSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const MantraSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lora(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
