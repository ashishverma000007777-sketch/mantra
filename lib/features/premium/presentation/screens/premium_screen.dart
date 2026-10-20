import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_button.dart';
import '../../../../core/network/api_client.dart';

enum PremiumPlan { gold, platinum }

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  PremiumPlan _selected = PremiumPlan.gold;
  bool _isAnnual = false;
  late Razorpay _razorpay;

  // Prices (Men pricing; women get 50% off — applied server-side)
  static const _goldMonthly = 299;
  static const _goldAnnual = 1999;
  static const _platinumMonthly = 599;
  static const _platinumAnnual = 3999;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  int get _currentPrice {
    if (_selected == PremiumPlan.gold) {
      return _isAnnual ? _goldAnnual : _goldMonthly;
    }
    return _isAnnual ? _platinumAnnual : _platinumMonthly;
  }

  String get _savingsText {
    if (!_isAnnual) return '';
    if (_selected == PremiumPlan.gold) {
      final saved = (_goldMonthly * 12) - _goldAnnual;
      return 'Save ₹$saved / year with annual sanctuary';
    }
    final saved = (_platinumMonthly * 12) - _platinumAnnual;
    return 'Save ₹$saved / year with annual sanctuary';
  }

  Future<void> _startPayment() async {
    HapticFeedback.mediumImpact();
    final planId = _selected == PremiumPlan.gold
        ? (_isAnnual ? 'gold_quarterly' : 'gold_monthly')
        : (_isAnnual ? 'platinum_yearly' : 'platinum_monthly');

    try {
      final res = await ApiClient.instance.post('/payment/order', data: {
        'plan_id': planId,
      });

      if (res.statusCode == 200 && res.data['success'] == true) {
        final orderData = res.data['data'];
        final options = {
          'key': orderData['key_id'] ?? 'rzp_test_placeholder',
          'amount': orderData['amount'],
          'order_id': orderData['order_id'],
          'name': 'Mantra',
          'description':
              '${_selected == PremiumPlan.gold ? 'Gold' : 'Platinum'} ${_isAnnual ? '(Annual)' : '(Monthly)'}',
          'theme': {'color': '#D6B27A'},
        };
        _razorpay.open(options);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['error'] ?? 'Could not create payment order'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment order error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final verifyRes = await ApiClient.instance.post('/payment/verify', data: {
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      });

      if (verifyRes.statusCode == 200 && verifyRes.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome to Mantra ${_selected == PremiumPlan.gold ? 'Gold' : 'Platinum'} ✨'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(verifyRes.data['error'] ?? 'Verification failed'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment verification error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment cancelled or failed. Please try again.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header with celestial aurora photographic artwork
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/premium_aurora.jpg',
                    fit: BoxFit.cover,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.black.withOpacity(0.7),
                          AppColors.background,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.18),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 28),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Mantra Inner Circle',
                          style: GoogleFonts.lora(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Patience rewarded. Intentional depth unlocked.',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Annual / Monthly toggle
                  _BillingToggle(
                    isAnnual: _isAnnual,
                    onChanged: (v) => setState(() => _isAnnual = v),
                  ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: 20),

                  // Plan cards
                  _PlanCard(
                    plan: PremiumPlan.gold,
                    isSelected: _selected == PremiumPlan.gold,
                    isAnnual: _isAnnual,
                    monthlyPrice: _goldMonthly,
                    annualPrice: _goldAnnual,
                    onTap: () => setState(() => _selected = PremiumPlan.gold),
                    features: const [
                      '10 daily Sparks (3 extra reflective slots)',
                      'See who resonated with your cadence',
                      'Read receipts & conversation archives',
                      'Priority placement in mindful algorithm',
                      'Access to 2 curated community rooms',
                    ],
                  ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.04, end: 0),

                  const SizedBox(height: 14),

                  _PlanCard(
                    plan: PremiumPlan.platinum,
                    isSelected: _selected == PremiumPlan.platinum,
                    isAnnual: _isAnnual,
                    monthlyPrice: _platinumMonthly,
                    annualPrice: _platinumAnnual,
                    onTap: () => setState(() => _selected = PremiumPlan.platinum),
                    badge: 'Recommended',
                    features: const [
                      'Everything in Gold tier',
                      '14 daily Sparks for broader discovery',
                      '1 weekly Deep Connect token',
                      'Unlock voice intro earlier in stage flow',
                      'Exclusive intimate community rooms',
                      'Anti-rush profile concierge',
                    ],
                  ).animate(delay: 160.ms).fadeIn().slideY(begin: 0.04, end: 0),

                  const SizedBox(height: 24),

                  // Women's 50% discount notice
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.trust.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                      border: Border.all(color: AppColors.trust.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite_rounded, size: 18, color: AppColors.trust),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Women receive 50% off all membership tiers automatically. No coupon needed.',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.trust,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 220.ms).fadeIn(),

                  const SizedBox(height: 24),

                  // CTA
                  Column(
                    children: [
                      MantraButton(
                        label: _isAnnual
                            ? 'Begin Sanctuary (₹$_currentPrice/yr)'
                            : 'Begin Sanctuary (₹$_currentPrice/mo)',
                        onPressed: _startPayment,
                        icon: Icons.star_rounded,
                      ),
                      if (_savingsText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _savingsText,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.trust,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        'Cancel anytime with a single tap. Transparent billing.',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textMuted,
                          fontSize: 11.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ).animate(delay: 280.ms).fadeIn().slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 28),

                  // Safety features always free note
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: AppColors.textSecondary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'All safety features (SOS, verification, ghost mode, screenshot alerts) are 100% free forever for all members.',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 320.ms).fadeIn(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingToggle extends StatelessWidget {
  final bool isAnnual;
  final ValueChanged<bool> onChanged;

  const _BillingToggle({required this.isAnnual, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Monthly',
            isActive: !isAnnual,
            onTap: () => onChanged(false),
          ),
          _Tab(
            label: 'Annual (Save 40%)',
            isActive: isAnnual,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? const Color(0xFF080B0D) : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PremiumPlan plan;
  final bool isSelected;
  final bool isAnnual;
  final int monthlyPrice;
  final int annualPrice;
  final VoidCallback onTap;
  final List<String> features;
  final String? badge;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.isAnnual,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.onTap,
    required this.features,
    this.badge,
  });

  String get _planName => plan == PremiumPlan.gold ? 'Gold Sanctuary' : 'Platinum Circle';

  Color get _accentColor => plan == PremiumPlan.gold ? AppColors.accent : const Color(0xFFE7D5B5);

  int get _displayPrice => isAnnual ? annualPrice : monthlyPrice;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
          border: Border.all(
            color: isSelected ? _accentColor : AppColors.border,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _planName,
                  style: GoogleFonts.lora(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? _accentColor : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                    ),
                    child: Text(
                      badge!,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.accent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '₹$_displayPrice',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isAnnual ? '/ year' : '/ month',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: isSelected ? _accentColor : AppColors.trust,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
