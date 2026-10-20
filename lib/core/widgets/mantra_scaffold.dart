import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Cinematic Scaffold for Mantra screens.
/// Provides consistent near-black canvas with subtle atmospheric ambient depth,
/// safe area handling, and optional floating bottom navigation / app bar integration.
class MantraScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;
  final bool extendBody;
  final Color? backgroundColor;
  final bool showAmbientGlow;
  final Alignment glowAlignment;

  const MantraScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
    this.backgroundColor,
    this.showAmbientGlow = true,
    this.glowAlignment = Alignment.topRight,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: appBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      extendBody: extendBody,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient cinematic lighting
          if (showAmbientGlow)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: glowAlignment,
                      radius: 1.4,
                      colors: [
                        AppColors.primary.withOpacity(0.045),
                        AppColors.secondary.withOpacity(0.015),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          // Main Body
          body,
        ],
      ),
    );
  }
}
