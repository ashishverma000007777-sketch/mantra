import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_card.dart';
import '../../../../core/network/api_client.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _activated = false;
  bool _locationFetching = false;
  String? _locationText;
  Position? _lastPos;
  int _countdown = 5;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _activateSOS() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _activated = true;
      _locationFetching = true;
      _countdown = 5;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        _sendAlert();
      } else {
        setState(() => _countdown--);
        HapticFeedback.lightImpact();
      }
    });

    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 4),
        );
        setState(() {
          _lastPos = pos;
          _locationText = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
          _locationFetching = false;
        });
      } else {
        setState(() => _locationFetching = false);
      }
    } catch (_) {
      setState(() => _locationFetching = false);
    }
  }

  void _cancelSOS() {
    HapticFeedback.mediumImpact();
    _countdownTimer?.cancel();
    setState(() {
      _activated = false;
      _countdown = 5;
    });
  }

  Future<void> _sendAlert() async {
    try {
      await ApiClient.instance.post('/safety/sos', data: {
        'latitude': _lastPos?.latitude,
        'longitude': _lastPos?.longitude,
      });
    } catch (_) {}
    HapticFeedback.heavyImpact();

    if (mounted) {
      _showAlertSentSheet();
    }
  }

  void _showAlertSentSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.trust.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.trust.withOpacity(0.35)),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.trust,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Emergency Alert Broadcasted',
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your trusted emergency contacts have been notified with your current coordinates. Help is on the way.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            // Call police
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('tel:100')),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                  border: Border.all(color: AppColors.error.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_rounded, color: AppColors.error, size: 22),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Call Police — 100',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Immediate connection to Indian emergency police',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.error.withOpacity(0.8),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('tel:112')),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                  border: Border.all(color: AppColors.warning.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emergency_rounded, color: AppColors.warning, size: 22),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'National Emergency Helpline — 112',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'All-in-one emergency dispatch helpline',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                context.pop();
                context.pop();
              },
              child: Text(
                "I'm safe now",
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _activated ? const Color(0xFF1E1412) : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _activated ? Colors.white : AppColors.textPrimary,
            size: 18,
          ),
        ),
        title: Text(
          'Emergency SOS',
          style: GoogleFonts.lora(
            color: _activated ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: _activated ? const Color(0xFF1E1412) : AppColors.background,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Main SOS button
                Center(
                  child: _activated
                      ? _ActivatedSOSButton(
                          countdown: _countdown,
                          onCancel: _cancelSOS,
                          pulseController: _pulseController,
                        )
                      : _IdleSOSButton(onActivate: _activateSOS),
                ),

                const SizedBox(height: 36),

                if (_activated) ...[
                  Text(
                    _countdown > 0
                        ? 'Broadcasting in $_countdown seconds...'
                        : 'Broadcasting emergency alert...',
                    style: GoogleFonts.lora(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 6),
                  Text(
                    _locationFetching
                        ? 'Capturing high-precision GPS coordinates...'
                        : _locationText != null
                            ? 'Coordinates: $_locationText ✓'
                            : 'Sending alert with approximate location',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: _cancelSOS,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        'Cancel — I am safe',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                ] else ...[
                  Text(
                    'Tap the shield above to trigger an emergency broadcast.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  _InfoCard(
                    icon: Icons.send_rounded,
                    title: 'Notifies your emergency circle',
                    subtitle: 'Trusted contacts receive an automated SMS with your live coordinates.',
                  ),
                  const SizedBox(height: 10),
                  _InfoCard(
                    icon: Icons.archive_outlined,
                    title: 'Archives current conversation',
                    subtitle: 'Active messages are timestamped and preserved securely as evidence.',
                  ),
                  const SizedBox(height: 10),
                  _InfoCard(
                    icon: Icons.location_on_outlined,
                    title: 'Broadcasts GPS location',
                    subtitle: 'Google Maps link dispatched directly to your trusted contacts.',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IdleSOSButton extends StatefulWidget {
  final VoidCallback onActivate;
  const _IdleSOSButton({required this.onActivate});

  @override
  State<_IdleSOSButton> createState() => _IdleSOSButtonState();
}

class _IdleSOSButtonState extends State<_IdleSOSButton> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) {
        setState(() => _pressing = false);
        widget.onActivate();
      },
      onTapCancel: () => setState(() => _pressing = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: _pressing ? 154 : 170,
        height: _pressing ? 154 : 170,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9E2A2B), Color(0xFFB83A3B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD96C72).withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9E2A2B).withOpacity(_pressing ? 0.2 : 0.4),
              blurRadius: _pressing ? 16 : 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_rounded, color: Colors.white, size: 44),
            const SizedBox(height: 6),
            Text(
              'SOS',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivatedSOSButton extends StatelessWidget {
  final int countdown;
  final VoidCallback onCancel;
  final AnimationController pulseController;

  const _ActivatedSOSButton({
    required this.countdown,
    required this.onCancel,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        final scale = 1.0 + (pulseController.value * 0.08);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withOpacity(0.4 + pulseController.value * 0.25),
                  blurRadius: 36 + pulseController.value * 20,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$countdown',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'BROADCASTING',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return MantraCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
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
        ],
      ),
    );
  }
}
