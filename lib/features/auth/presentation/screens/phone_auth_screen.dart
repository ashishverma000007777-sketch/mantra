import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_scaffold.dart';
import '../../../../core/widgets/mantra_button.dart';
import '../../../../core/widgets/mantra_card.dart';
import '../../../../core/preview/dev_preview.dart';
import '../../providers/auth_provider.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _agreed = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms to continue')),
      );
      return;
    }

    final controller = ref.read(authControllerProvider.notifier);
    final verificationId = await controller.sendOtp(_phoneController.text.trim());

    if (!mounted) return;

    if (verificationId != null) {
      if (verificationId == 'AUTO_VERIFIED') {
        context.go('/auth/kyc');
      } else {
        context.push('/auth/otp', extra: {
          'phone': _phoneController.text.trim(),
          'verificationId': verificationId,
        });
      }
    } else {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error?.toString().replaceAll('Exception: ', '') ??
                'Failed to send OTP. Please check your network and phone number.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return MantraScaffold(
      showAmbientGlow: true,
      glowAlignment: Alignment.topRight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
            vertical: 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Dark Editorial Brand Monogram
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'M',
                      style: GoogleFonts.lora(
                        color: AppColors.primary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.9, 0.9)),

                const SizedBox(height: 28),

                Text(
                  'Your story\nbegins here.',
                  style: GoogleFonts.lora(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.22,
                    letterSpacing: -0.5,
                  ),
                )
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 10),

                Text(
                  'Slow, intentional dating based on connection before revelation.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                    fontSize: 14.5,
                    height: 1.45,
                  ),
                ).animate(delay: 180.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 36),

                // Phone Input Card
                Text(
                  'PHONE NUMBER',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(AppSpacing.radiusMD - 1),
                            bottomLeft: Radius.circular(AppSpacing.radiusMD - 1),
                          ),
                          border: Border(
                            right: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '🇮🇳 +91',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '98765 43210',
                            fillColor: Colors.transparent,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: AppColors.textMuted,
                              fontSize: 15,
                              letterSpacing: 1.2,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter your phone number';
                            if (v.length != 10) return 'Enter a valid 10-digit number';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 250.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 20),

                // Terms checkbox
                GestureDetector(
                  onTap: () => setState(() => _agreed = !_agreed),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _agreed ? AppColors.primary : AppColors.surface,
                            border: Border.all(
                              color: _agreed ? AppColors.primary : AppColors.border,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: _agreed
                              ? const Icon(Icons.check, color: AppColors.background, size: 14)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'I agree to Mantra\'s ',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 320.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 28),

                MantraButton(
                  label: 'Send Verification Code',
                  isLoading: isLoading,
                  onPressed: _sendOtp,
                  icon: Icons.arrow_forward_rounded,
                ).animate(delay: 380.ms).fadeIn().slideY(begin: 0.1, end: 0),

                const SizedBox(height: 20),

                // Trust Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.trust.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    border: Border.all(color: AppColors.trust.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.trust,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your phone number is strictly private and never shown to matches.',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.trust,
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 440.ms).fadeIn(),

                // Development Preview Mode Option
                if (isDevPreviewSupported) ...[
                  const SizedBox(height: 36),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.borderSubtle)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'DEV PREVIEW MODE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.borderSubtle)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  MantraCard(
                    color: AppColors.surface,
                    borderColor: AppColors.primary.withOpacity(0.35),
                    hasGlow: true,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.explore_outlined, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Explore App Offline',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Browse all screens with curated mock data without SMS OTP.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        MantraButton(
                          label: 'Explore App in Preview Mode',
                          variant: MantraButtonVariant.outline,
                          height: 44,
                          foregroundColor: AppColors.primary,
                          onPressed: () {
                            final success = ref.read(devPreviewProvider.notifier).enterPreview();
                            if (success) {
                              context.go('/home');
                            }
                          },
                        ),
                      ],
                    ),
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
