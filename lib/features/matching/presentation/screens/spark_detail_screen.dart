import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_badge.dart';
import '../../../../core/widgets/mantra_card.dart';
import '../../../../core/widgets/mantra_button.dart';
import '../../data/models/spark_model.dart';
import '../../providers/sparks_provider.dart';

class SparkDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  final SparkModel? spark;

  const SparkDetailScreen({
    super.key,
    required this.userId,
    this.spark,
  });

  @override
  ConsumerState<SparkDetailScreen> createState() => _SparkDetailScreenState();
}

class _SparkDetailScreenState extends ConsumerState<SparkDetailScreen> {
  bool _isPlayingVoice = false;
  bool _isConnecting = false;

  void _onConnect(SparkModel spark) {
    HapticFeedback.mediumImpact();
    setState(() => _isConnecting = true);
    ref.read(sparksProvider.notifier).connect(spark.userId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connected with ${spark.displayName}! Spark sent ✨'),
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) context.pop();
    });
  }

  void _onPass(SparkModel spark) {
    HapticFeedback.lightImpact();
    ref.read(sparksProvider.notifier).pass(spark.userId);
    context.pop();
  }

  void _onSave(SparkModel spark) {
    HapticFeedback.selectionClick();
    ref.read(sparksProvider.notifier).save(spark.userId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved ${spark.displayName} to reflections'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SparkModel? resolvedSpark = widget.spark;
    if (resolvedSpark == null) {
      final sparks = ref.watch(sparksProvider).value ?? [];
      for (final s in sparks) {
        if (s.userId == widget.userId) {
          resolvedSpark = s;
          break;
        }
      }
    }

    if (resolvedSpark == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            'Connection profile not found',
            style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final spark = resolvedSpark;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filledTonal(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => _onSave(spark),
                        icon: const Icon(Icons.bookmark_outline_rounded, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.primary,
                        ),
                        tooltip: 'Save',
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () => context.push('/compatibility/${spark.userId}'),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceVariant,
                          foregroundColor: AppColors.primary,
                        ),
                        tooltip: 'Compatibility DNA',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Profile Content Scroll
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Editorial Hero Card
                    MantraCard(
                      padding: const EdgeInsets.all(20),
                      hasShadow: true,
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppColors.border, width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _buildAvatarImage(spark),
                                    if (spark.photosBlurred)
                                      BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                                        child: Container(
                                          color: AppColors.background.withOpacity(0.4),
                                          child: const Center(
                                            child: Icon(
                                              Icons.lock_rounded,
                                              color: AppColors.primaryLight,
                                              size: 26,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${spark.displayName}, ${spark.age}',
                                style: GoogleFonts.lora(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (spark.isVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: AppColors.trust,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            spark.city,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              MantraBadge.trust(score: spark.trustScore, fontSize: 12),
                              const SizedBox(width: 8),
                              MantraBadge.compatibility(score: spark.compatibilityScore, fontSize: 12),
                            ],
                          ),
                          if (spark.photosBlurred) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.blur_on_rounded, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Photos unblur at Connection Stage 4',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
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
                    ),

                    const SizedBox(height: 16),

                    // Voice Note Player
                    MantraCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: _isPlayingVoice ? AppColors.primary : AppColors.surfaceVariant,
                              foregroundColor: _isPlayingVoice ? AppColors.background : AppColors.primary,
                            ),
                            onPressed: () => setState(() => _isPlayingVoice = !_isPlayingVoice),
                            icon: Icon(
                              _isPlayingVoice ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isPlayingVoice ? 'Playing Voice Intro...' : 'Voice Introduction',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Hear cadence, tone, and presence',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.graphic_eq_rounded, color: AppColors.primary, size: 24),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Interests Section
                    if (spark.interests.isNotEmpty) ...[
                      Text(
                        'Interests & Nuances',
                        style: GoogleFonts.lora(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: spark.interests.map((tag) {
                          final isShared = spark.sharedInterests.contains(tag);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isShared ? AppColors.surfaceVariant : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                              border: Border.all(
                                color: isShared ? AppColors.primary.withOpacity(0.5) : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isShared) ...[
                                  const Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  tag,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: isShared ? AppColors.primaryLight : AppColors.textSecondary,
                                    fontWeight: isShared ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Compatibility DNA Card Shortcut
                    MantraCard(
                      onTap: () => context.push('/compatibility/${spark.userId}'),
                      padding: const EdgeInsets.all(16),
                      borderColor: AppColors.primary.withOpacity(0.3),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bubble_chart_outlined, color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Explore Compatibility DNA',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Deep dive into 7 slow-dating emotional dimensions',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => _onPass(spark),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text(
                        'Pass',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: MantraButton(
                      label: 'Connect Intentional',
                      isLoading: _isConnecting,
                      onPressed: () => _onConnect(spark),
                      icon: Icons.favorite_rounded,
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

  Widget _buildAvatarImage(SparkModel spark) {
    if (spark.profilePhotoUrl != null && spark.profilePhotoUrl!.startsWith('assets/')) {
      return Image.asset(
        spark.profilePhotoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackAvatar(spark.displayName),
      );
    } else if (spark.profilePhotoUrl != null && spark.profilePhotoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: spark.profilePhotoUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
        errorWidget: (_, __, ___) => _fallbackAvatar(spark.displayName),
      );
    }
    return _fallbackAvatar(spark.displayName);
  }

  Widget _fallbackAvatar(String name) {
    final initial = name.isNotEmpty ? name[0] : '?';
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.lora(
            fontSize: 40,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
