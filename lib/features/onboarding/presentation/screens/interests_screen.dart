import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_scaffold.dart';
import '../../../../core/widgets/mantra_button.dart';
import '../widgets/step_bar.dart';

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final Set<String> _selected = {};

  final _interests = const [
    'Vinyl & Indie Music',
    'Literature & Poetry',
    'Mindful Fitness',
    'Cinema & Auteur Film',
    'Culinary & Filter Coffee',
    'Slow Travel',
    'Board Games & Strategy',
    'Creative Technology',
    'Art & Gallery Walks',
    'Nature & Mountain Trails',
    'Cricket & Sports',
    'Theatre & Performing Arts',
    'Film Photography',
    'Yoga & Meditation',
    'Contemporary Dance',
    'Stand-up & Satire',
    'Sourdough & Baking',
    'Urban Cycling',
    'Cosmology & Science',
    'Sustainable Living',
    'Philosophy & Ethics',
    'Animal Welfare',
    'Architecture & Urbanism',
    'Terracotta Pottery',
  ];

  @override
  Widget build(BuildContext context) {
    final canContinue = _selected.length >= 3;

    return MantraScaffold(
      showAmbientGlow: true,
      glowAlignment: Alignment.topRight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingHorizontal,
                vertical: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StepBar(current: 3, total: 6),
                  const SizedBox(height: 20),
                  Text(
                    'What gives you\njoy and meaning?',
                    style: GoogleFonts.lora(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.25,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select at least 3 interests to anchor your profile and slow community discovery.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingHorizontal,
                  vertical: 8,
                ),
                child: Wrap(
                  spacing: 9,
                  runSpacing: 10,
                  children: _interests.map((interest) {
                    final isSel = _selected.contains(interest);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSel) {
                            _selected.remove(interest);
                          } else {
                            if (_selected.length < 8) {
                              _selected.add(interest);
                            }
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primary.withOpacity(0.18)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(
                            color: isSel ? AppColors.primary : AppColors.border,
                            width: isSel ? 1.4 : 1,
                          ),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          interest,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                            color: isSel ? AppColors.primaryLight : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingHorizontal,
                vertical: 16,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtle, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selected.length} of 8 selected',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: canContinue ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),
                        if (!canContinue)
                          Text(
                            'Pick at least 3',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    MantraButton(
                      label: 'Continue',
                      onPressed: canContinue
                          ? () => context.push('/onboarding/voice')
                          : null,
                      icon: Icons.arrow_forward_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
