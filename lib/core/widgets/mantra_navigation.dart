import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class MantraNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;

  const MantraNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}

/// Floating translucent bottom navigation inspired by the approved cinematic Home mockup.
class MantraBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<MantraNavItem> items;

  const MantraBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withOpacity(0.85),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = index == currentIndex;

                return GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: 22,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                            if (item.badgeCount != null && item.badgeCount! > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(3.5),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${item.badgeCount}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.background,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Text(
                            item.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cinematic Image Header for Profile, Spark Detail, and editorial story sections.
class MantraImageHeader extends StatelessWidget {
  final String imagePath;
  final bool isAsset;
  final double height;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;
  final Widget? child;

  const MantraImageHeader({
    super.key,
    required this.imagePath,
    this.isAsset = true,
    this.height = 320,
    this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          isAsset
              ? Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppColors.surface),
                )
              : Image.network(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppColors.surface),
                ),
          // Atmospheric Gradient Scrim
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withOpacity(0.3),
                  AppColors.background.withOpacity(0.65),
                  AppColors.background,
                ],
                stops: const [0.0, 0.65, 1.0],
              ),
            ),
          ),
          // Top Controls (Back button & Trailing action)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onBack != null)
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
                          onPressed: onBack,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          // Bottom Content
          if (child != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: child!,
            )
          else if (title != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  title!,
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    subtitle!,
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Segmented and continuous progress bar with slow-dating editorial styling.
class MantraProgressIndicator extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int? currentStep;
  final int? totalSteps;
  final Color? activeColor;
  final Color? backgroundColor;
  final double height;

  const MantraProgressIndicator({
    super.key,
    required this.progress,
    this.currentStep,
    this.totalSteps,
    this.activeColor,
    this.backgroundColor,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (totalSteps != null && totalSteps! > 1) {
      final active = currentStep ?? (progress * totalSteps!).round();
      return Row(
        children: List.generate(totalSteps!, (index) {
          final isStepActive = index < active;
          return Expanded(
            child: Container(
              height: height,
              margin: EdgeInsets.only(right: index < totalSteps! - 1 ? 6 : 0),
              decoration: BoxDecoration(
                color: isStepActive
                    ? (activeColor ?? AppColors.primary)
                    : (backgroundColor ?? AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
          );
        }),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: backgroundColor ?? AppColors.surfaceVariant,
        valueColor: AlwaysStoppedAnimation<Color>(
          activeColor ?? AppColors.primary,
        ),
      ),
    );
  }
}

/// Helper to display bottom sheets styled with Mantra's dark editorial design.
Future<T?> showMantraBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: AppColors.border, width: 1),
    ),
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    builder: (ctx) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: builder(ctx),
    ),
  );
}
