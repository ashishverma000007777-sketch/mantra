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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
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
                                    if (spark.profilePhotoUrl != null && spark.profilePhotoUrl!.isNotEmpty)
                                      CachedNetworkImage(
                                        imageUrl: spark.profilePhotoUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
                                        errorWidget: (_, __, ___) => _fallbackAvatar(spark.displayName),
                                      )
                                    else
                                      _fallbackAvatar(spark.displayName),
                                    if (spark.photosBlurred)
                                      BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                                        child: Container(
                                          color: AppColors.textPrimary.withOpacity(0.25),
                                          child: const Center(
                                            child: Icon(
                                              Icons.lock_rounded,
                                              color: Colors.white,
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
                                color: AppColors.surfaceVariant.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Photos gradually reveal as your conversation deepens',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 16),

                    // Voice Cadence Card
                    MantraCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'VOICE CADENCE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                '0:${spark.voiceDurationSeconds.toString().padLeft(2, '0')}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"Hear the tone, warmth, and emotion before seeing the face."',
                            style: GoogleFonts.lora(
                              fontStyle: FontStyle.italic,
                              fontSize: 13.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: () => setState(() => _isPlayingVoice = !_isPlayingVoice),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: _isPlayingVoice ? AppColors.surfaceVariant : AppColors.background,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                                border: Border.all(
                                  color: _isPlayingVoice ? AppColors.primaryLight : AppColors.border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _isPlayingVoice ? AppColors.primary : AppColors.surfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isPlayingVoice ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: _isPlayingVoice ? Colors.white : AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isPlayingVoice ? 'Playing reflection audio' : 'Listen to voice intro',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        LinearProgressIndicator(
                                          value: _isPlayingVoice ? 0.65 : 0.0,
                                          backgroundColor: AppColors.border,
                                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                          minHeight: 3,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 16),

                    // Mindful Reflection Prompt
                    MantraCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'A SUNDAY THOUGHT',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '"My ideal weekend begins with silence, hand-drip coffee, and walking through quiet tree-lined alleys without a destination."',
                            style: GoogleFonts.lora(
                              fontSize: 15,
                              height: 1.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Seeking someone who appreciates deliberate pace over rapid small talk.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: 140.ms).fadeIn().slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 16),

                    // Interests & Core Values
                    if (spark.interests.isNotEmpty) ...[
                      MantraCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CORE INTERESTS & RHYTHMS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: spark.interests.map((tag) {
                                final isShared = spark.sharedInterests.contains(tag);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isShared ? AppColors.surfaceVariant : AppColors.background,
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                    border: Border.all(
                                      color: isShared ? AppColors.primaryLight : AppColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isShared) ...[
                                        const Icon(Icons.sparkles, size: 12, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        tag,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: isShared ? FontWeight.w600 : FontWeight.w500,
                                          color: isShared ? AppColors.primaryDark : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.05, end: 0),
                      const SizedBox(height: 16),
                    ],

                    // Compatibility DNA Card Teaser
                    MantraCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () => context.push('/compatibility/${spark.userId}'),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.psychology_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Explore Compatibility DNA',
                                  style: GoogleFonts.lora(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Review your 7 dimensions of psychological synergy',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                        ],
                      ),
                    ).animate(delay: 220.ms).fadeIn().slideY(begin: 0.05, end: 0),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => _onPass(spark),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                      ),
                      child: Text(
                        'Pass',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isConnecting ? null : () => _onConnect(spark),
                        icon: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                        label: Text(
                          _isConnecting ? 'Connecting...' : 'Connect with Spark',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                        ),
                      ),
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

  Widget _fallbackAvatar(String displayName) {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Text(
          displayName.isNotEmpty ? displayName[0] : '?',
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
