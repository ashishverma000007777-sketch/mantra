import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_scaffold.dart';
import '../../../../core/widgets/mantra_button.dart';
import '../../../../core/widgets/mantra_card.dart';

class SafetyTourScreen extends StatelessWidget {
  const SafetyTourScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const safetyPillars = [
      (
        Icons.blur_on_rounded,
        'Photos are blurred by default',
        'Your visual identity is protected until both parties agree to reveal.',
      ),
      (
        Icons.sos_rounded,
        'One-Tap SOS Emergency Beacon',
        'Instantly alert your trusted contacts with encrypted coordinates.',
      ),
      (
        Icons.visibility_off_outlined,
        'Ghost Mode on Demand',
        'Hide your visibility immediately whenever you need personal pause.',
      ),
      (
        Icons.psychology_outlined,
        'AI Guardian Creep Detection',
        'Continuous automated screening for predatory or harassment behavior.',
      ),
      (
        Icons.chat_bubble_outline_rounded,
        'No Unsolicited Messages',
        'Conversations only open through mutual sparks or verified consent.',
      ),
    ];

    return MantraScaffold(
      showAmbientGlow: true,
      glowAlignment: Alignment.topCenter,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.trust.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.trust.withOpacity(0.35), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.trust.withOpacity(0.12),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(Icons.shield_rounded, color: AppColors.trust, size: 38),
              ),
              const SizedBox(height: 20),

              Text(
                'You are in Control.\nAlways.',
                style: GoogleFonts.lora(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.25,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                'Mantra is designed around psychological safety, mutual consent, and zero harassment.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              ...safetyPillars.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: MantraCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.trust.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.trust.withOpacity(0.25)),
                        ),
                        child: Icon(item.$1, color: AppColors.trust, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$2,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.$3,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),

              const SizedBox(height: 28),

              MantraButton(
                label: "I'm Ready to Enter Mantra",
                onPressed: () => context.go('/home'),
                icon: Icons.explore_outlined,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
