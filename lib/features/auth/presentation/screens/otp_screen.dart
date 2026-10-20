import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/mantra_button.dart';
import '../../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String? initialVerificationId;

  const OtpScreen({super.key, required this.phone, this.initialVerificationId});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  String _otp = '';
  int _resendSeconds = 60;
  Timer? _timer;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.initialVerificationId;
    _startTimer();
    if (_verificationId == null) {
      _sendOtpInitial();
    }
  }

  Future<void> _sendOtpInitial() async {
    final controller = ref.read(authControllerProvider.notifier);
    _verificationId = await controller.sendOtp(widget.phone);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds == 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _resendOtp() async {
    setState(() => _resendSeconds = 60);
    _startTimer();
    final controller = ref.read(authControllerProvider.notifier);
    _verificationId = await controller.sendOtp(widget.phone);
  }

  Future<void> _verify() async {
    if (_otp.length != 6 || _verificationId == null) return;
    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.verifyOtp(_verificationId!, _otp);
    if (!mounted) return;
    if (success) {
      context.go('/auth/kyc');
    } else {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error?.toString().replaceAll('Exception: ', '') ??
                'Invalid OTP. Please verify and try again.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              Text(
                'Enter Verification Code',
                style: GoogleFonts.lora(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              )
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 8),

              Text(
                'We sent a 6-digit verification code to +91 ${widget.phone}',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ).animate(delay: 100.ms).fadeIn(duration: 350.ms),

              const SizedBox(height: 36),

              // PIN Code Fields
              PinCodeTextField(
                appContext: context,
                controller: _otpController,
                length: 6,
                animationType: AnimationType.fade,
                keyboardType: TextInputType.number,
                autoFocus: true,
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  fieldHeight: 54,
                  fieldWidth: 46,
                  activeFillColor: AppColors.surface,
                  inactiveFillColor: AppColors.surface,
                  selectedFillColor: AppColors.surfaceVariant.withOpacity(0.5),
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  selectedColor: AppColors.primary,
                ),
                enableActiveFill: true,
                onChanged: (v) => setState(() => _otp = v),
                onCompleted: (_) => _verify(),
              ).animate(delay: 180.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 28),

              MantraButton(
                label: 'Verify & Continue',
                isLoading: isLoading,
                onPressed: _otp.length == 6 ? _verify : null,
                icon: Icons.check_circle_outline_rounded,
              ).animate(delay: 250.ms).fadeIn(),

              const SizedBox(height: 24),

              Center(
                child: _resendSeconds > 0
                    ? Text(
                        'Resend code in ${_resendSeconds}s',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textMuted,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : TextButton(
                        onPressed: _resendOtp,
                        child: Text(
                          'Resend Verification Code',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
