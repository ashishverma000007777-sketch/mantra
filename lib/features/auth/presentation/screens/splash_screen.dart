import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/mantra_scaffold.dart';
import '../../../../core/preview/dev_preview.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    final isPreviewActive = !kReleaseMode && ref.read(devPreviewProvider);
    if (isPreviewActive) {
      context.go('/home');
      return;
    }

    final authState = ref.read(authStateProvider);
    authState.when(
      data: (user) {
        if (user == null) {
          context.go('/auth/phone');
        } else if (!user.isOnboarded) {
          context.go('/onboarding/intent');
        } else {
          context.go('/home');
        }
      },
      loading: () => context.go('/auth/phone'),
      error: (_, __) => context.go('/auth/phone'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MantraScaffold(
      showAmbientGlow: true,
      glowAlignment: Alignment.center,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dark obsidian seal with refined warm gold monogram
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.18),
                    blurRadius: 36,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE7D5B5), Color(0xFFD6B27A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      'M',
                      style: GoogleFonts.lora(
                        color: AppColors.background,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                .scale(begin: const Offset(0.88, 0.88), curve: Curves.easeOutBack),

            const SizedBox(height: 28),

            Text(
              'Mantra',
              style: GoogleFonts.lora(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 1.5,
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.15, end: 0),

            const SizedBox(height: 8),

            Text(
              'Know them before you show yourself.',
              style: GoogleFonts.lora(
                color: AppColors.textSecondary,
                fontSize: 14.5,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.2,
              ),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 52),

            // Subtle pulsing indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(
                      delay: Duration(milliseconds: 600 + (i * 180)),
                      onPlay: (c) => c.repeat(),
                    )
                    .fadeIn(duration: 350.ms)
                    .then()
                    .fadeOut(duration: 350.ms);
              }),
            ),
          ],
        ),
      ),
    );
  }
}
