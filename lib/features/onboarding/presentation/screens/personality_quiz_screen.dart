import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_scaffold.dart';
import '../../../../core/widgets/mantra_card.dart';
import '../widgets/step_bar.dart';

class PersonalityQuizScreen extends StatefulWidget {
  const PersonalityQuizScreen({super.key});

  @override
  State<PersonalityQuizScreen> createState() => _PersonalityQuizScreenState();
}

class _PersonalityQuizScreenState extends State<PersonalityQuizScreen> {
  int _step = 0;
  final Map<int, int> _answers = {};

  final _questions = const [
    {
      'q': 'Your ideal Saturday morning looks like...',
      'options': [
        'Morning hike or outdoor nature cycle',
        'Quiet café corner with an evocative book',
        'Slow wake-up, acoustic music and tea at home',
        'Cooking an elaborate breakfast for thoughtful conversation',
      ],
    },
    {
      'q': 'When meeting someone new, you naturally tend to...',
      'options': [
        'Jump in with warmth, presence, and genuine curiosity',
        'Feel cautious at first, then open up deeply',
        'Calmly observe the room, energy, and subtle nuances',
        'Keep quiet until finding a shared philosophical thread',
      ],
    },
    {
      'q': 'The conversations that leave you most fulfilled are...',
      'options': [
        'Deep emotional reflections and personal vulnerability',
        'Playful banter with intellectual wit and rhythm',
        'Explorations of literature, art, and human society',
        'Quiet daydreams, creative crafts, and quiet hopes',
      ],
    },
    {
      'q': 'In romantic connections, your emotional style is...',
      'options': [
        'Open, expressive, and deeply intentional',
        'Thoughtful, grounded, and steady over time',
        'Warm and lighthearted, deepening naturally',
        'Patient and taking one meaningful step at a time',
      ],
    },
    {
      'q': 'Above all else, you cherish a partner with...',
      'options': [
        'Unwavering emotional loyalty and mindful presence',
        'Sharp curiosity, quiet intelligence, and humility',
        'Empathy, gentle kindness, and emotional maturity',
        'Creative passion, drive, and mutual quiet support',
      ],
    },
  ];

  void _selectAnswer(int optionIdx) {
    setState(() => _answers[_step] = optionIdx);
    Future.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      if (_step < _questions.length - 1) {
        setState(() => _step++);
      } else {
        context.push('/onboarding/interests');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_step];
    return MantraScaffold(
      showAmbientGlow: true,
      glowAlignment: Alignment.topRight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
                onPressed: () => setState(() => _step--),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepBar(
                current: 2,
                total: 6,
                stepLabel: 'Question ${_step + 1} of ${_questions.length}',
              ),
              const SizedBox(height: 28),

              Text(
                q['q'] as String,
                style: GoogleFonts.lora(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                  letterSpacing: -0.3,
                ),
                key: ValueKey(_step),
              ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.08, end: 0),

              const SizedBox(height: 28),

              ...((q['options'] as List<String>).asMap().entries.map((e) {
                final selected = _answers[_step] == e.key;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: MantraCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    color: selected ? AppColors.surfaceSecondary : AppColors.surface,
                    borderColor: selected ? AppColors.primary : AppColors.border,
                    hasGlow: selected,
                    onTap: () => _selectAnswer(e.key),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? AppColors.primary.withOpacity(0.2)
                                : AppColors.surfaceVariant,
                            border: Border.all(
                              color: selected ? AppColors.primary : AppColors.borderSubtle,
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            String.fromCharCode(65 + e.key),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: selected ? AppColors.primary : AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            e.value,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              color: selected ? AppColors.primaryLight : AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary, size: 20),
                        ],
                      ],
                    ),
                  ),
                ).animate(delay: Duration(milliseconds: e.key * 50)).fadeIn(duration: 200.ms);
              })),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
