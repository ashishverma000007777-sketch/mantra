import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_scaffold.dart';
import '../../../../core/widgets/mantra_button.dart';
import '../../../../core/widgets/mantra_card.dart';

class LivenessScreen extends StatelessWidget {
  const LivenessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MantraScaffold(
      showAmbientGlow: true,
      glowAlignment: Alignment.topCenter,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Liveness Check',
                style: GoogleFonts.lora(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'A quick 5-second 3D face scan confirms you are a real person.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontSize: 14.5,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Camera Viewport Frame with Dark Obsidian Ring & Gold Accent
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.18),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.face_retouching_natural_rounded,
                              size: 72,
                              color: AppColors.primaryLight.withOpacity(0.8),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Face the camera',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Steps
              MantraCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    _InstructionRow(
                      icon: Icons.light_mode_outlined,
                      text: 'Ensure good lighting with no glare or hats.',
                    ),
                    Divider(color: AppColors.borderSubtle, height: 20),
                    _InstructionRow(
                      icon: Icons.remove_red_eye_outlined,
                      text: 'Look straight at the circular lens frame.',
                    ),
                    Divider(color: AppColors.borderSubtle, height: 20),
                    _InstructionRow(
                      icon: Icons.shield_outlined,
                      text: 'Scan is processed securely and never shown on profile.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              MantraButton(
                label: 'Begin Scan',
                onPressed: () => context.go('/onboarding/intent'),
                icon: Icons.camera_alt_outlined,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstructionRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
