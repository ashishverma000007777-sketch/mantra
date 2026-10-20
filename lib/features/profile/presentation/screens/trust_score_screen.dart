// lib/features/profile/presentation/screens/trust_score_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_badge.dart';
import '../../../../core/widgets/mantra_card.dart';

class TrustScoreScreen extends StatelessWidget {
  const TrustScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const double trustScore = 88.0;

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
              'Trust & Verification',
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Safety through transparent accountability',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // Score Overview Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
                border: Border.all(color: AppColors.trust.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceSecondary,
                      border: Border.all(color: AppColors.trust, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.trust.withOpacity(0.2),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${trustScore.toInt()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.trust,
                            ),
                          ),
                          Text(
                            'trust',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.trust,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_rounded, color: AppColors.trust, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'High Trust Member',
                        style: GoogleFonts.lora(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phone verified · KYC completed · Zero safety reports',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Trust Score Breakdown',
              style: GoogleFonts.lora(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Breakdown Tiles
            MantraCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: const [
                  _BreakdownItem(
                    icon: Icons.phone_android_rounded,
                    title: 'Phone Authentication',
                    subtitle: 'Secure Firebase OTP verification',
                    points: '+20 pts',
                    isComplete: true,
                  ),
                  Divider(height: 1, color: AppColors.border),
                  _BreakdownItem(
                    icon: Icons.face_rounded,
                    title: 'Liveness & Anti-Spoofing',
                    subtitle: 'Real-time 3D camera verification',
                    points: '+20 pts',
                    isComplete: true,
                  ),
                  Divider(height: 1, color: AppColors.border),
                  _BreakdownItem(
                    icon: Icons.badge_outlined,
                    title: 'Government KYC Verification',
                    subtitle: 'Encrypted Aadhaar / PAN validation',
                    points: '+20 pts',
                    isComplete: true,
                  ),
                  Divider(height: 1, color: AppColors.border),
                  _BreakdownItem(
                    icon: Icons.mic_none_rounded,
                    title: 'Authentic Voice Introduction',
                    subtitle: 'Recorded genuine vocal cadence',
                    points: '+15 pts',
                    isComplete: true,
                  ),
                  Divider(height: 1, color: AppColors.border),
                  _BreakdownItem(
                    icon: Icons.shield_outlined,
                    title: 'Community Safety Record',
                    subtitle: 'Clean history without behavioral flags',
                    points: '+15 pts',
                    isComplete: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Trust Philosophy Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.spa_outlined, size: 16, color: AppColors.trust),
                      const SizedBox(width: 8),
                      Text(
                        'THE MANTRA TRUST PHILOSOPHY',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                          letterSpacing: 0.8,
                          color: AppColors.trust,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our trust score exists to create a sanctuary where every individual is real, verified, and accountable. We never sell your data or display private identification documents.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.45,
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
}

class _BreakdownItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String points;
  final bool isComplete;

  const _BreakdownItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.trust.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: AppColors.trust),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.trust.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              points,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.trust,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
