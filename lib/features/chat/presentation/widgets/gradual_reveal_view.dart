// lib/features/chat/presentation/widgets/gradual_reveal_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/gradual_reveal_model.dart';
import '../../providers/reveal_provider.dart';

class GradualRevealView extends ConsumerWidget {
  final String connectionId;

  const GradualRevealView({super.key, required this.connectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revealAsync = ref.watch(revealProviderFamily(connectionId));

    return revealAsync.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (reveal) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Stepper Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 16, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      'Gradual Reveal',
                      style: GoogleFonts.lora(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: reveal.isPhotoUnlocked
                        ? AppColors.trust.withOpacity(0.15)
                        : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: reveal.isPhotoUnlocked ? AppColors.trust : AppColors.border,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'STAGE: ${reveal.currentStage.toUpperCase()}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: reveal.isPhotoUnlocked ? AppColors.trust : AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 4 Stages Stepper
            Row(
              children: [
                _StagePill(label: 'Mind', isActive: true, isCurrent: reveal.currentStage == 'mind'),
                _StepDivider(isActive: reveal.currentStage != 'mind'),
                _StagePill(
                  label: 'Voice',
                  isActive: reveal.isVoiceUnlocked || reveal.currentStage != 'mind',
                  isCurrent: reveal.currentStage == 'voice',
                ),
                _StepDivider(isActive: reveal.currentStage == 'connection' || reveal.currentStage == 'face'),
                _StagePill(
                  label: 'Bond',
                  isActive: reveal.currentStage == 'connection' || reveal.currentStage == 'face',
                  isCurrent: reveal.currentStage == 'connection',
                ),
                _StepDivider(isActive: reveal.isPhotoUnlocked),
                _StagePill(
                  label: 'Face',
                  isActive: reveal.isPhotoUnlocked,
                  isCurrent: reveal.currentStage == 'face',
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Pending Partner Request Alert
            if (reveal.pendingRequestsFromPartner.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_unread_outlined, size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Partner requested ${reveal.pendingRequestsFromPartner.first} reveal.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.accent,
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ref
                            .read(revealProviderFamily(connectionId).notifier)
                            .respondStage(reveal.pendingRequestsFromPartner.first, true);
                      },
                      child: Text(
                        'Accept',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.textMuted,
                      ),
                      onPressed: () {
                        ref
                            .read(revealProviderFamily(connectionId).notifier)
                            .respondStage(reveal.pendingRequestsFromPartner.first, false);
                      },
                      child: Text(
                        'Decline',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action / Consent Controls
            if (!reveal.isPhotoUnlocked) ...[
              if (reveal.myConsent['face'] == true) ...[
                Text(
                  'You consented to face reveal. Awaiting partner\'s mutual consent.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.accent.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    ),
                  ),
                  onPressed: () => _confirmRequestFaceReveal(context, ref),
                  icon: const Icon(Icons.visibility_outlined, size: 14, color: AppColors.accent),
                  label: Text(
                    'Request Mutual Face Reveal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ] else ...[
              // Photos are unblurred with mutual consent
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.trust),
                      const SizedBox(width: 6),
                      Text(
                        'Photos mutually unblurred ✨',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.trust,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _confirmRevoke(context, ref),
                    child: Text(
                      'Revoke consent',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.error,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmRequestFaceReveal(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: Text(
          'Request Mutual Face Reveal?',
          style: GoogleFonts.lora(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Both participants must explicitly consent before photos are unblurred. Your photos remain protected until your connection also consents.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Not yet',
              style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: const Color(0xFF080B0D),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(revealProviderFamily(connectionId).notifier).requestStage('face');
            },
            child: Text(
              'Give Consent',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRevoke(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: Text(
          'Revoke Face Reveal?',
          style: GoogleFonts.lora(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Photos will be immediately secured and re-blurred. You can request reveal again at any time.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(revealProviderFamily(connectionId).notifier).revokeStage('face');
            },
            child: Text(
              'Revoke Now',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StagePill extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isCurrent;

  const _StagePill({required this.label, required this.isActive, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.accent
            : isActive
                ? AppColors.surfaceSecondary
                : AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: isCurrent || isActive ? AppColors.accent.withOpacity(0.5) : AppColors.border,
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: isCurrent || isActive ? FontWeight.w700 : FontWeight.w500,
          color: isCurrent
              ? const Color(0xFF080B0D)
              : isActive
                  ? AppColors.accent
                  : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _StepDivider extends StatelessWidget {
  final bool isActive;
  const _StepDivider({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 1.5,
        color: isActive ? AppColors.accent.withOpacity(0.5) : AppColors.border,
      ),
    );
  }
}
