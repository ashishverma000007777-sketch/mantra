// lib/features/matching/presentation/screens/mystery_match_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_badge.dart';
import '../../../../core/widgets/mantra_card.dart';
import '../../../../core/widgets/mantra_button.dart';
import '../../../../core/widgets/mantra_states.dart';
import '../../data/models/mystery_match_model.dart';
import '../../providers/mystery_match_provider.dart';

class MysteryMatchScreen extends ConsumerStatefulWidget {
  const MysteryMatchScreen({super.key});

  @override
  ConsumerState<MysteryMatchScreen> createState() => _MysteryMatchScreenState();
}

class _MysteryMatchScreenState extends ConsumerState<MysteryMatchScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(mysteryMatchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Mystery Match',
                  style: GoogleFonts.lora(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'SLOW DATING',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Personality first. Identity with mutual consent.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Compatibility DNA',
            icon: const Icon(Icons.psychology_rounded, color: AppColors.primary),
            onPressed: () {
              final candidates = matchesAsync.value ?? [];
              if (candidates.isNotEmpty && _currentIndex < candidates.length) {
                context.push('/compatibility/${candidates[_currentIndex].candidateId}');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No active candidate to compare.')),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textPrimary),
            onPressed: () => ref.read(mysteryMatchProvider.notifier).refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: matchesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => MantraErrorState(
            message: 'Could not load mystery matches.\n${e.toString()}',
            onRetry: () => ref.read(mysteryMatchProvider.notifier).refresh(),
          ),
          data: (candidates) {
            if (candidates.isEmpty || _currentIndex >= candidates.length) {
              return MantraEmptyState(
                icon: Icons.nightlight_round_outlined,
                title: 'No More Mystery Matches Today',
                message: 'In slow dating, quality comes before quantity. Take time to reflect, nurture current connections, or explore community rooms.',
                actionLabel: 'Explore Community',
                onAction: () => context.go('/rooms'),
              );
            }

            final candidate = candidates[_currentIndex];

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  // Progress indicator
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / candidates.length,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Mystery Discovery Card
                  Expanded(
                    child: _MysteryCard(
                      candidate: candidate,
                      onExplore: () async {
                        HapticFeedback.mediumImpact();
                        final res = await ref.read(mysteryMatchProvider.notifier).explore(candidate.candidateId);
                        if (!mounted) return;
                        if (res['is_mutual'] == true) {
                          _showMutualMatchDialog(context, res['conversation_id']);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Explored ${candidate.pseudonym}\'s mind ✨'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      onPass: () {
                        HapticFeedback.lightImpact();
                        ref.read(mysteryMatchProvider.notifier).pass(candidate.candidateId);
                      },
                      onViewDna: () => context.push('/compatibility/${candidate.candidateId}'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showMutualMatchDialog(BuildContext context, String? conversationId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
        backgroundColor: AppColors.surface,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mutual Mystery Match!',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontWeight: FontWeight.w600,
                fontSize: 22,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Both of you felt drawn to each other\'s minds and values. Your connection seed is now planted 🌱',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          MantraButton(
            label: 'Begin Slow Conversation',
            onPressed: () {
              Navigator.pop(ctx);
              if (conversationId != null) {
                context.push('/chat/$conversationId');
              } else {
                context.push('/conversations');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _MysteryCard extends StatelessWidget {
  final MysteryMatchModel candidate;
  final VoidCallback onExplore;
  final VoidCallback onPass;
  final VoidCallback onViewDna;

  const _MysteryCard({
    required this.candidate,
    required this.onExplore,
    required this.onPass,
    required this.onViewDna,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Silhouette Header & Pseudonym Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                border: const Border(
                  bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Masked silhouette avatar
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              candidate.pseudonym,
                              style: GoogleFonts.lora(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${candidate.age} yrs · ${candidate.city}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            MantraBadge.trust(
                              score: candidate.trustScore,
                              fontSize: 10.5,
                            ),
                            if (candidate.hasVoiceIntro) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                  border: Border.all(color: AppColors.borderSubtle),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.mic_rounded, size: 10, color: AppColors.primary),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Voice intro',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable prompts & values
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intent quote
                    if (candidate.intent.isNotEmpty) ...[
                      Text(
                        'INTENT & VISION',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '"${candidate.intent}"',
                        style: GoogleFonts.lora(
                          fontStyle: FontStyle.italic,
                          fontSize: 14.5,
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Personality tags
                    if (candidate.personalityTags.isNotEmpty) ...[
                      Text(
                        'VALUES & CORE PILLARS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: candidate.personalityTags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Prompt responses
                    ...candidate.promptResponses.map((pr) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pr.question,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              pr.answer,
                              style: GoogleFonts.lora(
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtle, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Pass
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                      ),
                      onPressed: onPass,
                      child: Text(
                        'Pass',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // DNA button
                  IconButton.outlined(
                    tooltip: 'Compatibility DNA',
                    icon: const Icon(Icons.bubble_chart_outlined, size: 20),
                    color: AppColors.primary,
                    style: IconButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: onViewDna,
                  ),
                  const SizedBox(width: 8),

                  // Explore Spark
                  Expanded(
                    flex: 3,
                    child: MantraButton(
                      label: 'Explore Mind',
                      icon: Icons.auto_awesome_rounded,
                      onPressed: onExplore,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
