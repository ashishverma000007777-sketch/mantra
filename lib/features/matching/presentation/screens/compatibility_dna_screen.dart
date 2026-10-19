// lib/features/matching/presentation/screens/compatibility_dna_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/compatibility_dna_model.dart';
import '../../providers/compatibility_provider.dart';

class CompatibilityDnaScreen extends ConsumerWidget {
  final String targetUserId;

  const CompatibilityDnaScreen({super.key, required this.targetUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dnaAsync = ref.watch(compatibilityDnaFamily(targetUserId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Compatibility DNA', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: dnaAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text('Could not compute compatibility insights'),
                  const SizedBox(height: 8),
                  Text(e.toString(), style: TextStyle(fontSize: 12, color: AppColors.textMuted), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(compatibilityDnaFamily(targetUserId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (dna) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dna.ethicalNotice,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.4,
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Score Indicator
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${dna.overallAlignment}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'harmony',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
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
                const Text(
                  'Compatibility DNA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Evaluated across ${dna.evaluatedDimensionsCount} mindful dimensions including values, rhythm, and communication.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

class _DimensionCard extends StatelessWidget {
  final String dimensionKey;
  final DimensionInsightModel model;

  const _DimensionCard({required this.dimensionKey, required this.model});

  IconData _getIcon() {
    switch (dimensionKey) {
      case 'communication':
        return Icons.chat_bubble_outline_rounded;
      case 'relationship_intentions':
        return Icons.favorite_border_rounded;
      case 'core_values':
        return Icons.verified_user_outlined;
      case 'lifestyle':
        return Icons.wb_sunny_outlined;
      case 'emotional_readiness':
        return Icons.self_improvement_rounded;
      case 'conflict_resolution':
        return Icons.handshake_outlined;
      case 'shared_interests':
        return Icons.interests_outlined;
      default:
        return Icons.bubble_chart_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = model.score / 100.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getIcon(), size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  model.dimension,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              Text(
                '${model.score}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Score bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                model.score >= 80 ? AppColors.trust : AppColors.primary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),

          // Insight explanation
          Text(
            model.insight,
            style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.35),
          ),

          // Contributing factors
          if (model.contributingFactors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Based on: ',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
                Expanded(
                  child: Text(
                    model.contributingFactors.join(', '),
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ],

          // Shared items tags
          if (model.sharedItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: model.sharedItems.map((item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '✨ $item',
                      style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
