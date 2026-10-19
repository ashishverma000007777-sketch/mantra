// lib/features/chat/presentation/screens/connection_garden_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/connection_garden_model.dart';
import '../../providers/garden_provider.dart';

class ConnectionGardenScreen extends ConsumerWidget {
  final String connectionId;

  const ConnectionGardenScreen({super.key, required this.connectionId});

  String _getBotanicalArt(String stage) {
    switch (stage) {
      case 'seed':
        return '🌱';
      case 'sprout':
        return '🌿';
      case 'growing':
        return '🪴';
      case 'bloom':
        return '🌸';
      default:
        return '🌱';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gardenAsync = ref.watch(connectionGardenFamily(connectionId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Connection Garden', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Pause Garden',
            icon: const Icon(Icons.pause_circle_outline_rounded),
            onPressed: () {
              final garden = gardenAsync.value;
              if (garden != null) {
                ref.read(connectionGardenFamily(connectionId).notifier).togglePrivacy(!garden.isPaused);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(garden.isPaused ? 'Garden resumed 🌱' : 'Garden paused ⏸️')),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: gardenAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.eco_outlined, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text('Could not load connection garden'),
                  const SizedBox(height: 8),
                  Text(e.toString(), style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(connectionGardenFamily(connectionId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (garden) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Garden Stage Botanical Showcase Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.trust.withOpacity(0.18),
                      AppColors.primary.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
                  border: Border.all(color: AppColors.trust.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    // Botanical emoji with gentle breathing animation
                    Text(
                      _getBotanicalArt(garden.stage),
                      style: const TextStyle(fontSize: 68),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                          begin: const Offset(0.96, 0.96),
                          end: const Offset(1.04, 1.04),
                          duration: 2000.ms,
                        ),
                    const SizedBox(height: 14),

                    Text(
                      'STAGE: ${garden.stage.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.trust,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      garden.stageDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Growth points bar
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Growth Points',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                            ),
                            Text(
                              '${garden.growthPoints}/100',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.trust),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: garden.growthPoints / 100.0,
                            backgroundColor: AppColors.surface,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.trust),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Next Mindful Step
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, size: 20, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Next Mindful Milestone',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            garden.nextMilestoneSuggestion,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Milestone History Section
              Row(
                children: [
                  const Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Milestone Journey',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (garden.milestones.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      'Your journey begins here. Complete your first Conversation Quest together!',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ] else ...[
                ...garden.milestones.map((m) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.trust.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(child: Text('🌿', style: TextStyle(fontSize: 16))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      m.title,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    Text(
                                      m.achievedAt.isNotEmpty ? m.achievedAt.substring(0, 10) : '',
                                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  m.description,
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],

              const SizedBox(height: 16),

              // Anti-Streak Notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.nature_people_rounded, size: 16, color: AppColors.trust),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        garden.antiStreakGuarantee,
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
