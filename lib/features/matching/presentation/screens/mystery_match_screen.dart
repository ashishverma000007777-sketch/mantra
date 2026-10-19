// lib/features/matching/presentation/screens/mystery_match_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Mystery Match',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'SLOW DATING',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Personality first. Identity with consent.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Compatibility DNA',
            icon: Icon(Icons.psychology_rounded, color: AppColors.primary),
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
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(mysteryMatchProvider.notifier).refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: matchesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text('Could not load mystery matches', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(e.toString(), textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(mysteryMatchProvider.notifier).refresh(),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
          data: (candidates) {
            if (candidates.isEmpty || _currentIndex >= candidates.length) {
              return const _MysteryEmptyState();
            }

            final candidate = candidates[_currentIndex];

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  // Progress indicator
                  LinearProgressIndicator(
                    value: (_currentIndex + 1) / candidates.length,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 3,
                  ),
                  const SizedBox(height: 12),

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: Column(
          children: [
            const Text('✨', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            const Text('Mutual Mystery Match!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Both of you felt drawn to each other\'s minds and values. Your connection seed is now planted 🌱',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (conversationId != null) {
                context.push('/chat/$conversationId');
              } else {
                context.push('/conversations');
              }
            },
            child: const Text('Begin Slow Conversation', style: TextStyle(color: Colors.white)),
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
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.12),
                    AppColors.secondary.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                    ),
                    child: Center(
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
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textMuted),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${candidate.age} yrs · ${candidate.city}',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        // Trust score indicator
                        Row(
                          children: [
                            Icon(Icons.shield_rounded, size: 12, color: AppColors.trust),
                            const SizedBox(width: 4),
                            Text(
                              '${candidate.trustScore.toInt()} Trust Score',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.trust),
                            ),
                            if (candidate.hasVoiceIntro) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.mic_rounded, size: 10, color: AppColors.primary),
                                    SizedBox(width: 2),
                                    Text('Voice recorded', style: TextStyle(fontSize: 10, color: AppColors.primary)),
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

            // Card Body with Mindful Answers
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Relationship Intention Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryLight.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite_outline_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Intention: ${candidate.intent}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Compatibility DNA banner trigger
                  GestureDetector(
                    onTap: onViewDna,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.insights_rounded, size: 16, color: AppColors.secondary),
                              SizedBox(width: 8),
                              Text(
                                'View Compatibility DNA',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary),
                              ),
                            ],
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Prompt answers (Thoughtful Mind Discovery)
                  if (candidate.promptResponses.isNotEmpty) ...[
                    ...candidate.promptResponses.map((p) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border.withOpacity(0.6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.question,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.answer,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],

                  // Personality Tags
                  if (candidate.personalityTags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Values & Interests',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: candidate.personalityTags.map((tag) {
                        final isShared = candidate.sharedInterests.contains(tag);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isShared ? AppColors.primary.withOpacity(0.12) : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isShared ? AppColors.primary.withOpacity(0.4) : AppColors.border,
                            ),
                          ),
                          child: Text(
                            isShared ? '✨ $tag' : tag,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isShared ? FontWeight.w600 : FontWeight.w500,
                              color: isShared ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  // "Not My Vibe"
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: onPass,
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                      label: Text(
                        'Not My Vibe',
                        style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // "Explore Their Mind"
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      onPressed: onExplore,
                      icon: const Icon(Icons.psychology_rounded, size: 18, color: Colors.white),
                      label: const Text(
                        'Explore Mind',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04, end: 0);
  }
}

class _MysteryEmptyState extends StatelessWidget {
  const _MysteryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌙', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              'No More Mystery Matches Today',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'In slow dating, quality comes before quantity. Take time to reflect, nurture your current connections, or check back tomorrow.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
