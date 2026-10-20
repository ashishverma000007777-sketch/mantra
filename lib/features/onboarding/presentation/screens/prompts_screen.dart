import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_scaffold.dart';
import '../../../../core/widgets/mantra_button.dart';
import '../../../../core/widgets/mantra_card.dart';
import '../widgets/step_bar.dart';

class PromptsScreen extends StatelessWidget {
  const PromptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const prompts = [
      "The most spontaneous, joyful thing I've done...",
      "A life philosophy that anchors my everyday decisions...",
      "What slow, intentional love means to me...",
    ];

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
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepBar(current: 6, total: 6),
              const SizedBox(height: 24),

              Text(
                'Tell Your Story in Depth.',
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
                'Answers to these prompts spark genuine first conversations beyond trivial small talk.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 24),

              ...prompts.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: MantraCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.value,
                        style: GoogleFonts.lora(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Share your authentic thoughts...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: AppColors.textMuted,
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          fillColor: Colors.transparent,
                          filled: false,
                        ),
                      ),
                    ],
                  ),
                ),
              )),

              const SizedBox(height: 28),

              MantraButton(
                label: 'Save & View Safety Tour',
                onPressed: () => context.push('/onboarding/safety-tour'),
                icon: Icons.shield_outlined,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
