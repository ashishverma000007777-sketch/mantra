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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gardenAsync = ref.watch(connectionGardenFamily(connectionId));

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
            icon: const Icon(Icons.pause_circle_outline_rounded, size: 21, color: AppColors.textSecondary),
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
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
          error: (e, _) => MantraErrorState(
            message: 'Could not load your connection garden.\n${e.toString()}',
            onRetry: () => ref.refresh(connectionGardenFamily(connectionId)),
          ),
          data: (garden) => ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              // Garden Stage Botanical Showcase Card with bundled photographic hero
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
                  border: Border.all(color: AppColors.trust.withOpacity(0.35), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Botanical Conservatory Image
                      Image.asset(
                        'assets/images/garden_flourish.jpg',
                        fit: BoxFit.cover,
                      ),
                      // Multi-stop gradient overlay for readable editorial typography
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.black.withOpacity(0.75),
                              const Color(0xFF080B0D).withOpacity(0.95),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      // Botanical Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.trust.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                border: Border.all(color: AppColors.trust.withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.eco_rounded, size: 12, color: AppColors.trust),
                                  const SizedBox(width: 5),
                                  Text(
                                    'STAGE: ${garden.stage.toUpperCase()}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                      color: AppColors.trust,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              garden.stageDescription,
                              style: GoogleFonts.lora(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 14),

                            // Growth points bar
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
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),

              const SizedBox(height: 16),

              // Next Mindful Step
              MantraCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.spa_outlined, size: 20, color: AppColors.accent),
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
                              color: AppColors.accent,
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
                  const Icon(Icons.history_rounded, size: 18, color: AppColors.accent),
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
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.trust.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.eco_outlined, size: 18, color: AppColors.trust),
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
                  color: AppColors.surfaceSecondary,
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
