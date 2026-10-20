import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_button.dart';
import '../widgets/step_bar.dart';

class PhotoUploadScreen extends StatelessWidget {
  const PhotoUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/onboarding/prompts'),
            child: Text(
              'Skip for now',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepBar(current: 5, total: 6),
              const SizedBox(height: 24),

              Text(
                'Upload Your Photos,\nProtected by Default.',
                style: GoogleFonts.lora(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.25,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Mantra places your privacy first: all photos remain gracefully blurred until mutual connection stages unlock them.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 24),

              // Privacy shield banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.blur_on_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Gradual Reveal Guarantee: No one sees your face without your explicit, mutual consent.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
                children: List.generate(6, (i) {
                  final isPrimary = i == 0;
                  return Container(
                    decoration: BoxDecoration(
                      color: isPrimary ? AppColors.surface : AppColors.surfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                      border: Border.all(
                        color: isPrimary ? AppColors.primary : AppColors.border,
                        width: isPrimary ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPrimary ? Icons.add_photo_alternate_rounded : Icons.add_rounded,
                          color: isPrimary ? AppColors.primary : AppColors.textMuted,
                          size: isPrimary ? 28 : 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPrimary ? 'Primary' : 'Photo ${i + 1}',
                          style: GoogleFonts.plusJakartaSans(
                            color: isPrimary ? AppColors.primary : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 36),

              MantraButton(
                label: 'Continue',
                onPressed: () => context.push('/onboarding/prompts'),
                icon: Icons.arrow_forward_rounded,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
