import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/mantra_button.dart';
import '../widgets/step_bar.dart';

class IntentScreen extends ConsumerStatefulWidget {
  const IntentScreen({super.key});

  @override
  ConsumerState<IntentScreen> createState() => _IntentScreenState();
}

class _IntentScreenState extends ConsumerState<IntentScreen> {
  String? _selectedIntent;

  final _intents = const [
    {
      'id': 'meaningful',
      'emoji': '🌱',
      'title': 'Something Meaningful',
      'subtitle': 'Seeking a slow, emotionally deep romantic connection.',
    },
    {
      'id': 'partner',
      'emoji': '🏡',
      'title': 'Long-term Life Partner',
      'subtitle': 'Looking for someone to build a shared future and life with.',
    },
    {
      'id': 'friendship',
      'emoji': '🤝',
      'title': 'Deep Friendship',
      'subtitle': 'Genuine companions who appreciate heartfelt conversations.',
    },
    {
      'id': 'conversations',
      'emoji': '☕',
      'title': 'Thoughtful Conversations',
      'subtitle': 'Love discussing books, philosophies, and everyday nuances.',
    },
    {
      'id': 'exploring',
      'emoji': '✨',
      'title': 'Open & Exploring',
      'subtitle': 'Letting connections unfold naturally without rigid labels.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const StepBar(current: 1, total: 6),
              const SizedBox(height: 28),

              Text(
                'What brings\nyou to Mantra?',
                style: GoogleFonts.lora(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.25,
                  letterSpacing: -0.4,
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 8),

              Text(
                'Intentions guide our matching algorithm so you only meet people moving at your pace.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ).animate(delay: 100.ms).fadeIn(),

              const SizedBox(height: 24),

              ...List.generate(_intents.length, (i) {
                final intent = _intents[i];
                final isSelected = _selectedIntent == intent['id'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _IntentCard(
                    emoji: intent['emoji']!,
                    title: intent['title']!,
                    subtitle: intent['subtitle']!,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedIntent = intent['id']),
                  ),
                ).animate(delay: Duration(milliseconds: 120 + i * 60)).fadeIn(duration: 250.ms);
              }),

              const SizedBox(height: 24),

              MantraButton(
                label: 'Continue',
                onPressed: _selectedIntent != null
                    ? () => context.push('/onboarding/quiz')
                    : null,
                icon: Icons.arrow_forward_rounded,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntentCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _IntentCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceVariant.withOpacity(0.5) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
