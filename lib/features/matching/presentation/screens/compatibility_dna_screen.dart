// lib/features/matching/presentation/screens/compatibility_dna_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_card.dart';
import '../../../../core/widgets/mantra_states.dart';
import '../../data/models/compatibility_dna_model.dart';
import '../../providers/compatibility_provider.dart';

class CompatibilityDnaScreen extends ConsumerWidget {
  final String targetUserId;

  const CompatibilityDnaScreen({super.key, required this.targetUserId});

  @override
  Widget build(BuildContext context) {
    final dnaAsync = ref.watch(compatibilityDnaFamily(targetUserId));

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
              'Compatibility DNA',
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Psychological and emotional synergy',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: dnaAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => MantraErrorState(
            message: 'Could not compute compatibility insights.\n${e.toString()}',
            onRetry: () => ref.refresh(compatibilityDnaFamily(targetUserId)),
          ),
          data: (dna) => ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              // Overall Alignment Header Card
              _OverallAlignmentCard(dna: dna),
              const SizedBox(height: 20),

              // Section Title
              Row(
                children: [
                  const Icon(Icons.hub_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '7 Dimensions of Alignment',
                    style: GoogleFonts.lora(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Dimension Cards
              ...dna.dimensions.entries.map((entry) => _DimensionCard(
                    dimensionKey: entry.key,
                    model: entry.value,
                  )),

              const SizedBox(height: 16),

              // Ethical Notice Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  border: Border.all(color: AppColors.trust.withOpacity(0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.spa_outlined,
                      size: 18,
                      color: AppColors.trust,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dna.ethicalNotice,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
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

class _OverallAlignmentCard extends StatelessWidget {
  final CompatibilityDnaModel dna;
  const _OverallAlignmentCard({required this.dna});

  @override
  Widget build(BuildContext context) {
    return MantraCard(
      color: AppColors.surface,
      borderColor: AppColors.primary.withOpacity(0.4),
      hasGlow: true,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Circular Score Indicator
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.12),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${dna.overallAlignment}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'harmony',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compatibility DNA',
                  style: GoogleFonts.lora(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Multi-dimensional alignment across communication, emotional depth, values, and pace.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DimensionCard extends StatelessWidget {
  final String dimensionKey;
  final DimensionScore model;

  const _DimensionCard({
    required this.dimensionKey,
    required this.model,
  });

  String get _title {
    return dimensionKey
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: MantraCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${model.score}%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: model.score / 100,
                minHeight: 5,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  model.score >= 80 ? AppColors.primary : AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 10),

            Text(
              model.insight,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
