import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/preview/dev_preview.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_badge.dart';
import '../../../../core/widgets/mantra_card.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/network/api_client.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final isPreview = !kReleaseMode && ref.read(devPreviewProvider);
    if (isPreview) {
      setState(() {
        _profile = {
          'display_name': 'Aria Sharma',
          'age': 26,
          'city': 'Bengaluru',
          'trust_score': 88.0,
          'bio': 'Lover of slow coffee mornings, paperbacks, and unfiltered conversations.',
          'intent': 'Mindful companionship built on mutual respect',
        };
        _isLoading = false;
      });
      return;
    }

    try {
      final res = await ApiClient.instance.get('/profile');
      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() {
          _profile = res.data['data'];
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isPreviewActive = !kReleaseMode && ref.watch(devPreviewProvider);
    final name = _profile?['display_name'] ?? 'Mantra Member';
    final age = _profile?['age'] ?? user?.age ?? 26;
    final city = _profile?['city'] ?? user?.city ?? 'Bengaluru';
    final trustScore = (_profile?['trust_score'] as num?)?.toDouble() ?? 88.0;
    final isPremium = user?.isPremium ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Your Sanctuary',
          style: GoogleFonts.lora(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (!isPremium)
            TextButton.icon(
              onPressed: () => context.push('/premium'),
              icon: const Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
              label: Text(
                'Membership',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                // Development Preview Mode notice if active
                if (isPreviewActive) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.explore_outlined, color: AppColors.accent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Development Preview Mode',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Exploring offline with mock data · No OTP required',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await ref.read(authControllerProvider.notifier).logout();
                            if (context.mounted) context.go('/auth/phone');
                          },
                          child: Text(
                            'Exit',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Editorial Profile Header Card with subtle ambient sanctuary art
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Subtle sanctuary backdrop banner
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: SizedBox(
                          height: 90,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/trust_safety_hero.jpg',
                                fit: BoxFit.cover,
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.3),
                                      AppColors.surface,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 45, 20, 20),
                        child: Column(
                          children: [
                            Center(
                              child: Stack(
                                children: [
                                  Container(
                                    width: 86,
                                    height: 86,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.surfaceSecondary,
                                      border: Border.all(color: AppColors.accent, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accent.withOpacity(0.2),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        name.isNotEmpty ? name[0] : 'M',
                                        style: GoogleFonts.lora(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: InkWell(
                                      onTap: () => context.push('/profile/edit'),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.background, width: 2),
                                        ),
                                        child: const Icon(
                                          Icons.edit_rounded,
                                          size: 13,
                                          color: Color(0xFF080B0D),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              name,
                              style: GoogleFonts.lora(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$age · $city',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            MantraBadge.trust(score: trustScore, fontSize: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 16),

                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Trust Score',
                        value: '${trustScore.toInt()}%',
                        subtitle: 'Verified',
                        icon: Icons.shield_rounded,
                        color: AppColors.trust,
                        onTap: () => context.push('/profile/trust-score'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        title: 'Daily Sparks',
                        value: '7',
                        subtitle: 'Reflections',
                        icon: Icons.auto_awesome_rounded,
                        color: AppColors.accent,
                        onTap: () => context.go('/sparks'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        title: 'Garden Stage',
                        value: 'Sprout',
                        subtitle: 'Blooming',
                        icon: Icons.eco_outlined,
                        color: AppColors.trust,
                        onTap: () => context.push('/conversations'),
                      ),
                    ),
                  ],
                ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.04, end: 0),

                const SizedBox(height: 20),

                Text(
                  'Profile & Personalization',
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                // Settings Cards
                MantraCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      _ProfileTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Edit Profile & Prompts',
                        subtitle: 'Update your cadence, bio & interests',
                        onTap: () => context.push('/profile/edit'),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      _ProfileTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Trust Score & Verification',
                        subtitle: 'Breakdown of your safety standing',
                        onTap: () => context.push('/profile/trust-score'),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      _ProfileTile(
                        icon: Icons.shield_outlined,
                        title: 'Safety Center & SOS',
                        subtitle: 'Trusted contacts, screenshot alerts, ghost mode',
                        onTap: () => context.push('/safety'),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      _ProfileTile(
                        icon: Icons.workspace_premium_outlined,
                        title: 'Mantra Membership',
                        subtitle: isPremium ? 'Active Inner Circle Member' : 'Explore mindful perks',
                        iconColor: AppColors.accent,
                        onTap: () => context.push('/premium'),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      _ProfileTile(
                        icon: Icons.logout_rounded,
                        title: isPreviewActive ? 'Exit Preview Mode' : 'Log Out',
                        subtitle: 'Securely end your current session',
                        textColor: AppColors.error,
                        iconColor: AppColors.error,
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          await ref.read(authControllerProvider.notifier).logout();
                          if (context.mounted) context.go('/auth/phone');
                        },
                      ),
                    ],
                  ),
                ).animate(delay: 140.ms).fadeIn().slideY(begin: 0.04, end: 0),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MantraCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.accent).withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: iconColor ?? AppColors.accent),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          color: AppColors.textMuted,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
    );
  }
}
