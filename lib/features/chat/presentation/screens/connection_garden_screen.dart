// lib/features/chat/presentation/screens/connection_garden_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_card.dart';
import '../../../../core/widgets/mantra_states.dart';
import '../../data/models/connection_garden_model.dart';
import '../../providers/garden_provider.dart';

class ConnectionGardenScreen extends ConsumerWidget {
  final String connectionId;

  const ConnectionGardenScreen({super.key, required this.connectionId});

  String _getBotanicalArt(String stage) {
    switch (stage.toLowerCase()) {
      case 'seed':
        return '🌱';
      case 'sprout':
        return '🌿';
      case 'growing':
        return '🪴';
      case 'bloom':
      case 'blooming':
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Garden',
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'A living metaphor for your mutual bond',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pause or resume garden',
            icon: const Icon(Icons.pause_circle_outline_rounded, size: 21),
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
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => MantraErrorState(
            message: 'Could not load your connection garden.\n${e.toString()}',
            onRetry: () => ref.refresh(connectionGardenFamily(connectionId)),
          ),
          data: (garden) => ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              // Garden Stage Botanical Showcase Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.trustLight.withOpacity(0.35),
                      AppColors.surfaceVariant.withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
                  border: Border.all(color: AppColors.trust.withOpacity(0.3), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.trust,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      garden.stageDescription,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Growth points bar
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'GROWTH POINTS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${garden.growthPoints} / 200',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.trust,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (garden.growthPoints / 200.0).clamp(0.0, 1.0),
                            backgroundColor: AppColors.surface.withOpacity(0.7),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.trust),
                            minHeight: 7,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),

              const SizedBox(height: 16),

              // Next Mindful Step
              MantraCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.spa_outlined, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEXT MINDFUL STEP',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                              letterSpacing: 0.8,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            garden.nextMilestoneSuggestion,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.04, end: 0),

              const SizedBox(height: 20),

              // Milestone Journey Section
              Row(
                children: [
                  const Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Milestone Journey',
                    style: GoogleFonts.lora(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (garden.milestones.isEmpty) ...[
                MantraCard(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Your journey begins here. Complete your first Conversation Quest together!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ] else ...[
                ...garden.milestones.map((m) => MantraCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Center(child: Text('🌿', style: TextStyle(fontSize: 15))),
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
                                      style: GoogleFonts.lora(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      m.achievedAt.isNotEmpty ? m.achievedAt.substring(0, 10) : '',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  m.description,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
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
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, size: 16, color: AppColors.trust),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        garden.antiStreakGuarantee,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
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
