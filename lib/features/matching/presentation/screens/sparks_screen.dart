import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_badge.dart';
import '../../../../core/widgets/mantra_card.dart';
import '../../../../core/widgets/mantra_states.dart';
import '../../../matching/data/models/spark_model.dart';
import '../../../matching/providers/sparks_provider.dart';

class SparksScreen extends ConsumerWidget {
  const SparksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sparksAsync = ref.watch(sparksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SparksHeader(
              sparksCount: sparksAsync.value?.length ?? 0,
            ),
            Expanded(
              child: sparksAsync.when(
                loading: () => const _SparksShimmer(),
                error: (e, _) => MantraErrorState(
                  message: 'Could not load your daily sparks.\nPlease check your connection.',
                  onRetry: () => ref.invalidate(sparksProvider),
                ),
                data: (sparks) {
                  if (sparks.isEmpty) {
                    return MantraEmptyState(
                      icon: Icons.nightlight_round_outlined,
                      title: "You've seen today's sparks",
                      message: 'New sparks arrive every morning at 9 AM.\nMeanwhile, explore community reflections or check your garden.',
                      actionLabel: 'Explore Community',
                      onAction: () => context.go('/community'),
                    );
                  }
                  return _SparksList(sparks: sparks);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparksHeader extends StatelessWidget {
  final int sparksCount;
  const _SparksHeader({required this.sparksCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DAILY CURATION',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Today's Sparks",
                  style: GoogleFonts.lora(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Grounded in emotional depth & compatibility',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 13,
                ),
                const SizedBox(width: 5),
                Text(
                  '$sparksCount remaining',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primaryDark,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
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

class _SparksList extends StatelessWidget {
  final List<SparkModel> sparks;

  const _SparksList({required this.sparks});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: sparks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        return SparkCard(spark: sparks[i])
            .animate(delay: Duration(milliseconds: i * 70))
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.06, end: 0);
      },
    );
  }
}

class SparkCard extends ConsumerStatefulWidget {
  final SparkModel spark;

  const SparkCard({super.key, required this.spark});

  @override
  ConsumerState<SparkCard> createState() => _SparkCardState();
}

class _SparkCardState extends ConsumerState<SparkCard> {
  bool _isPlayingVoice = false;
  bool _actionTaken = false;

  void _onConnect() {
    HapticFeedback.mediumImpact();
    setState(() => _actionTaken = true);
    ref.read(sparksProvider.notifier).connect(widget.spark.userId);
  }

  void _onPass() {
    HapticFeedback.lightImpact();
    setState(() => _actionTaken = true);
    ref.read(sparksProvider.notifier).pass(widget.spark.userId);
  }

  void _onSave() {
    HapticFeedback.selectionClick();
    ref.read(sparksProvider.notifier).save(widget.spark.userId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved ${widget.spark.displayName} for later reflection'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spark = widget.spark;

    return GestureDetector(
      onTap: () => context.push('/sparks/${spark.userId}', extra: spark),
      child: AnimatedOpacity(
        opacity: _actionTaken ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: MantraCard(
          padding: const EdgeInsets.all(16),
          hasShadow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Profile Overview Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BlurredAvatar(
                    imageUrl: spark.profilePhotoUrl,
                    isBlurred: spark.photosBlurred,
                    initial: spark.displayName.isNotEmpty ? spark.displayName[0] : '?',
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                spark.displayName,
                                style: GoogleFonts.lora(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (spark.isVerified) ...[
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.verified_rounded,
                                color: AppColors.trust,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${spark.age} · ${spark.city}',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            MantraBadge.trust(
                              score: spark.trustScore,
                              fontSize: 11,
                            ),
                            if (spark.sharedRoomsCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  '${spark.sharedRoomsCount} shared rooms',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Compatibility Score Badge
                  MantraBadge.compatibility(
                    score: spark.compatibilityScore,
                    fontSize: 11.5,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Voice Introduction Preview Card
              _VoiceIntroButton(
                isPlaying: _isPlayingVoice,
                durationSeconds: spark.voiceDurationSeconds > 0 ? spark.voiceDurationSeconds : 30,
                onTap: () => setState(() => _isPlayingVoice = !_isPlayingVoice),
              ),

              // Interest / Reflection Tags
              if (spark.interests.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: spark.interests.take(4).map((tag) {
                    final isShared = spark.sharedInterests.contains(tag);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: isShared ? AppColors.surfaceVariant : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(
                          color: isShared ? AppColors.primaryLight : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isShared) ...[
                            const Icon(
                              Icons.favorite_rounded,
                              size: 10,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            tag,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: isShared ? AppColors.primaryDark : AppColors.textSecondary,
                              fontWeight: isShared ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),

              // Action Bar: Pass, Save, Connect
              Row(
                children: [
                  // Pass
                  Expanded(
                    flex: 3,
                    child: OutlinedButton.icon(
                      onPressed: _actionTaken ? null : _onPass,
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
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Save for later
                  IconButton.outlined(
                    onPressed: _actionTaken ? null : _onSave,
                    icon: const Icon(Icons.bookmark_outline_rounded, size: 18),
                    color: AppColors.primary,
                    style: IconButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.all(10),
                    ),
                    tooltip: 'Save for reflection',
                  ),
                  const SizedBox(width: 8),

                  // Connect
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _actionTaken ? null : _onConnect,
                        icon: const Icon(Icons.favorite_rounded, size: 16, color: Colors.white),
                        label: Text(
                          'Connect',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlurredAvatar extends StatelessWidget {
  final String? imageUrl;
  final bool isBlurred;
  final String initial;

  const _BlurredAvatar({
    this.imageUrl,
    required this.isBlurred,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
                errorWidget: (_, __, ___) => _fallbackAvatar(),
              )
            else
              _fallbackAvatar(),
            if (isBlurred)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: AppColors.textPrimary.withOpacity(0.2),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Stage 1',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.lora(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _VoiceIntroButton extends StatelessWidget {
  final bool isPlaying;
  final int durationSeconds;
  final VoidCallback onTap;

  const _VoiceIntroButton({
    required this.isPlaying,
    required this.durationSeconds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isPlaying ? AppColors.surfaceVariant : AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          border: Border.all(
            color: isPlaying ? AppColors.primaryLight : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isPlaying ? AppColors.primary : AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPlaying ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isPlaying ? Colors.white : AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isPlaying ? 'Playing Voice Cadence' : 'Voice Introduction',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '0:${durationSeconds.toString().padLeft(2, '0')}',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: List.generate(24, (i) {
                      final heights = [
                        4.0, 8.0, 14.0, 6.0, 11.0, 16.0, 7.0, 10.0,
                        13.0, 8.0, 15.0, 9.0, 5.0, 12.0, 8.0, 14.0,
                        16.0, 7.0, 10.0, 6.0, 11.0, 9.0, 6.0, 4.0,
                      ];
                      final isPastBar = isPlaying && i < 14;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 0.8),
                          height: heights[i % heights.length],
                          decoration: BoxDecoration(
                            color: isPastBar
                                ? AppColors.primary
                                : (isPlaying ? AppColors.primaryLight : AppColors.border),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
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

class _SparksShimmer extends StatelessWidget {
  const _SparksShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
          border: Border.all(color: AppColors.border),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 1200.ms, color: AppColors.surfaceVariant),
    );
  }
}
