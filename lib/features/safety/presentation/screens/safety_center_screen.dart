// lib/features/safety/presentation/screens/safety_center_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_card.dart';

class SafetyCenterScreen extends ConsumerWidget {
  const SafetyCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Safety & Sanctuary',
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SOS Emergency Card
            _SOSCard(onTap: () => context.push('/safety/sos'))
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.06, end: 0),

            const SizedBox(height: 24),

            Text(
              'Your Safety Controls',
              style: GoogleFonts.lora(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ).animate(delay: 100.ms).fadeIn(),

            const SizedBox(height: 12),

            _SafetyOption(
              icon: Icons.people_alt_rounded,
              iconColor: AppColors.trust,
              title: 'Trusted Contacts',
              subtitle: 'Emergency circle alerted when SOS is triggered',
              badge: '2 added',
              onTap: () => context.push('/safety/trusted-contacts'),
            ).animate(delay: 150.ms).fadeIn().slideX(begin: 0.04, end: 0),

            _SafetyOption(
              icon: Icons.visibility_off_rounded,
              iconColor: AppColors.secondary,
              title: 'Ghost Mode',
              subtitle: 'Browse quietly without appearing in sparks',
              trailing: const _ToggleSwitch(),
              onTap: null,
            ).animate(delay: 200.ms).fadeIn().slideX(begin: 0.04, end: 0),

            _SafetyOption(
              icon: Icons.no_photography_rounded,
              iconColor: AppColors.warning,
              title: 'Screenshot Alerts',
              subtitle: 'Immediate alert if a chat or prompt is captured',
              trailing: const _ToggleSwitch(initialValue: true),
              onTap: null,
            ).animate(delay: 250.ms).fadeIn().slideX(begin: 0.04, end: 0),

            _SafetyOption(
              icon: Icons.nightlight_round,
              iconColor: AppColors.primary,
              title: 'Night Protection',
              subtitle: 'Mute alerts and pause new connections after 11 PM',
              trailing: const _ToggleSwitch(initialValue: true),
              onTap: null,
            ).animate(delay: 300.ms).fadeIn().slideX(begin: 0.04, end: 0),

            const SizedBox(height: 24),

            Text(
              'Privacy & Consent',
              style: GoogleFonts.lora(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ).animate(delay: 380.ms).fadeIn(),

            const SizedBox(height: 12),

            _SafetyOption(
              icon: Icons.blur_on_rounded,
              iconColor: AppColors.primary,
              title: 'Strict Photo Blurring',
              subtitle: 'Requires double mutual confirmation before reveal',
              trailing: const _ToggleSwitch(initialValue: true),
              onTap: null,
            ).animate(delay: 400.ms).fadeIn().slideX(begin: 0.04, end: 0),

            _SafetyOption(
              icon: Icons.location_off_rounded,
              iconColor: AppColors.secondary,
              title: 'City-Level Location Only',
              subtitle: 'Never disclose coordinates or neighborhood',
              trailing: const _ToggleSwitch(initialValue: true),
              onTap: null,
            ).animate(delay: 430.ms).fadeIn().slideX(begin: 0.04, end: 0),

            const SizedBox(height: 24),

            // Safety Support Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withOpacity(0.6),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.support_agent_rounded, color: AppColors.trust, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Human Trust & Safety Team',
                        style: GoogleFonts.lora(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our dedicated safety committee reviews reports and provides 24/7 human oversight. You are never left without support.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ).animate(delay: 480.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

class _SOSCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SOSCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFC94A4A),
              Color(0xFFDC6868),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC94A4A).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emergency_outlined,
                color: Colors.white,
                size: 26,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                    begin: 1.0,
                    end: 1.06,
                    duration: 1500.ms,
                    curve: Curves.easeInOut),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOS Emergency Alert',
                    style: GoogleFonts.lora(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Instantly broadcast location to trusted contacts & archive chat.',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SafetyOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MantraCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                badge!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (trailing == null && badge == null && onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
        ],
      ),
    );
  }
}

class _ToggleSwitch extends StatefulWidget {
  final bool initialValue;
  const _ToggleSwitch({this.initialValue = false});

  @override
  State<_ToggleSwitch> createState() => _ToggleSwitchState();
}

class _ToggleSwitchState extends State<_ToggleSwitch> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value: _value,
        onChanged: (v) {
          HapticFeedback.selectionClick();
          setState(() => _value = v);
        },
        activeColor: AppColors.primary,
        activeTrackColor: AppColors.primaryLight.withOpacity(0.4),
      ),
    );
  }
}
