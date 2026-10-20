import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum MantraButtonVariant { primary, secondary, outline, ghost, soft }

/// Primary high-touch interactive button with subtle scale physics and editorial styling.
class MantraButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final MantraButtonVariant variant;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const MantraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = MantraButtonVariant.primary,
    this.width,
    this.height = 50,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<MantraButton> createState() => _MantraButtonState();
}

class _MantraButtonState extends State<MantraButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    if (widget.backgroundColor != null) return widget.backgroundColor!;
    switch (widget.variant) {
      case MantraButtonVariant.primary:
        return AppColors.primary;
      case MantraButtonVariant.secondary:
        return AppColors.surfaceSecondary;
      case MantraButtonVariant.soft:
        return AppColors.softAccent;
      case MantraButtonVariant.outline:
      case MantraButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color get _foregroundColor {
    if (widget.foregroundColor != null) return widget.foregroundColor!;
    switch (widget.variant) {
      case MantraButtonVariant.primary:
        return AppColors.background;
      case MantraButtonVariant.secondary:
        return AppColors.textPrimary;
      case MantraButtonVariant.soft:
        return AppColors.primaryLight;
      case MantraButtonVariant.outline:
        return AppColors.textPrimary;
      case MantraButtonVariant.ghost:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null && !widget.isLoading;

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) {
          if (!isDisabled) {
            HapticFeedback.lightImpact();
            _scaleController.forward();
          }
        },
        onTapUp: (_) => _scaleController.reverse(),
        onTapCancel: () => _scaleController.reverse(),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Material(
            color: isDisabled
                ? AppColors.surface.withOpacity(0.5)
                : _backgroundColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: InkWell(
              onTap: isDisabled ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: widget.variant == MantraButtonVariant.outline
                      ? Border.all(color: AppColors.border, width: 1.2)
                      : widget.variant == MantraButtonVariant.secondary
                          ? Border.all(color: AppColors.borderSubtle, width: 1)
                          : null,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: widget.isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _foregroundColor,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 18, color: _foregroundColor),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Text(
                            widget.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDisabled
                                  ? AppColors.textMuted
                                  : _foregroundColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Standalone Secondary button for auxiliary editorial actions.
class MantraSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double height;
  final bool isLoading;

  const MantraSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.width,
    this.height = 46,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return MantraButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      width: width,
      height: height,
      isLoading: isLoading,
      variant: MantraButtonVariant.secondary,
    );
  }
}

/// Circular or rounded icon button with subtle border and elevation.
class MantraIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;
  final double iconSize;

  const MantraIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.size = 44,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: backgroundColor ?? AppColors.surface,
      shape: CircleBorder(
        side: BorderSide(
          color: borderColor ?? AppColors.border,
          width: 1,
        ),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}
