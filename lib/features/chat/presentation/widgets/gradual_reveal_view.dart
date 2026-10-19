// lib/features/chat/presentation/widgets/gradual_reveal_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      loading: () => const SizedBox(height: 72, child: Center(child: CircularProgressIndicator())),
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
              color: AppColors.shadow.withOpacity(0.04),
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
                    const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Gradual Reveal',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: reveal.isPhotoUnlocked
                        ? AppColors.trust.withOpacity(0.12)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'STAGE: ${reveal.currentStage.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: reveal.isPhotoUnlocked ? AppColors.trust : AppColors.primary,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_unread_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your partner requested ${reveal.pendingRequestsFromPartner.first} reveal.',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 26)),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ref
                            .read(revealProviderFamily(connectionId).notifier)
                            .respondStage(reveal.pendingRequestsFromPartner.first, true);
                      },
                      child: const Text('Accept', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 26)),
                      onPressed: () {
                        ref
                            .read(revealProviderFamily(connectionId).notifier)
                            .respondStage(reveal.pendingRequestsFromPartner.first, false);
                      },
                      child: const Text('Decline', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _confirmRequestFaceReveal(context, ref),
                  icon: const Icon(Icons.visibility_outlined, size: 14, color: AppColors.primary),
                  label: const Text(
                    'Request Mutual Face Reveal',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ],
            ] else ...[
              // Photos are unblurred with mutual consent
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.check_circle_rounded, size: 14, color: AppColors.trust),
                      SizedBox(width: 6),
                      Text(
                        'Photos mutually unblurred ✨',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.trust),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _confirmRevoke(context, ref),
                    child: Text(
                      'Revoke consent',
                      style: TextStyle(fontSize: 11, color: AppColors.error, decoration: TextDecoration.underline),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: AppColors.surface,
        title: const Text('Request Mutual Face Reveal?'),
        content: const Text(
          'Both participants must explicitly consent before photos are unblurred. Your photos will remain hidden until your connection also consents.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not yet'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(revealProviderFamily(connectionId).notifier).requestStage('face');
            },
            child: const Text('Give Consent', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmRevoke(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: AppColors.surface,
        title: const Text('Revoke Face Reveal?'),
        content: const Text(
          'Photos will be immediately secured and re-blurred. You can request reveal again at any time.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(revealProviderFamily(connectionId).notifier).revokeStage('face');
            },
            child: const Text('Revoke Now', style: TextStyle(color: Colors.white)),
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
            ? AppColors.primary
            : isActive
                ? AppColors.primary.withOpacity(0.12)
                : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isCurrent || isActive ? FontWeight.w700 : FontWeight.w500,
          color: isCurrent
              ? Colors.white
              : isActive
                  ? AppColors.primary
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
        height: 2,
        color: isActive ? AppColors.primary.withOpacity(0.5) : AppColors.border,
      ),
    );
  }
}
