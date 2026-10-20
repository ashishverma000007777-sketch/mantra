import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
    '🎵 Vinyl & Music',
    '📚 Literature & Books',
    '🏋️ Mindful Fitness',
    '🎬 Cinema & Indies',
    '🍕 Culinary & Coffee',
    '✈️ Slow Travel',
    '🎮 Board & Video Games',
    '💻 Technology & Coding',
    '🎨 Art & Galleries',
    '🌿 Nature & Hiking',
    '🏏 Cricket & Sports',
    '🎭 Theatre & Plays',
    '📸 35mm Photography',
    '🧘 Yoga & Meditation',
    '💃 Classical & Modern Dance',
    '🎤 Stand-up & Comedy',
    '🍳 Home Baking',
    '🚴 Cycling & Trails',
    '📰 Current Affairs',
    '🔭 Astronomy & Cosmos',
    '🛍️ Sustainable Fashion',
    '🌙 Philosophy',
    '🐾 Animal Rescue',
    '🏡 Architecture & Plants',
  ];

  @override
  Widget build(BuildContext context) {
    final canContinue = _selected.length >= 3;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
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
                    'Select at least 3 interests to anchor your profile and community discovery.',
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

            // Scrollable Wrap solving the previous overflow bug
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
                  children: _interests.map((tag) {
                    final sel = _selected.contains(tag);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (sel) {
                          _selected.remove(tag);
                        } else {
                          _selected.add(tag);
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.surfaceVariant
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(
                            color: sel ? AppColors.primary : AppColors.border,
                            width: sel ? 1.6 : 1,
                          ),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                            color: sel ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Bottom action container with safe area
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingHorizontal,
                vertical: 14,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: MantraButton(
                label: canContinue
                    ? 'Continue (${_selected.length} selected)'
                    : 'Select at least 3 (${_selected.length}/3)',
                onPressed: canContinue ? () => context.push('/onboarding/voice') : null,
                icon: Icons.arrow_forward_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
