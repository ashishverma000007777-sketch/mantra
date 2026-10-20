import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
        '🏔️ Morning hike or outdoor cycle',
        '☕ Quiet café corner with a book',
        '🛋️ Slow wake-up, music and tea at home',
        '🍳 Cooking an elaborate breakfast with friends',
      ],
    },
    {
      'q': 'When meeting someone new, you naturally tend to...',
      'options': [
        '😃 Jump in with warmth and high energy',
        '😅 Feel cautious at first, then open up deeply',
        '😌 Calmly observe the room and vibes',
        '🤐 Keep quiet until finding a shared interest',
      ],
    },
    {
      'q': 'The conversations that leave you most fulfilled are...',
      'options': [
        '🌊 Deep emotional reflections and personal values',
        '😂 Playful banter and witty back-and-forth',
        '🧠 Intellectual debates on books, ideas, and society',
        '🌱 Daydreams, ambitions, and creative hopes',
      ],
    },
    {
      'q': 'In romantic connections, your emotional style is...',
      'options': [
        '❤️ Expressive and vulnerable from early on',
        '🤔 Thoughtful, grounded, and observant',
        '😄 Lighthearted with humor, deep over time',
        '🌱 Intentional and taking it one step at a time',
      ],
    },
    {
      'q': 'Above all else, you cherish a partner with...',
      'options': [
        '🤝 Unwavering loyalty and presence',
        '💡 Sharp curiosity and depth of thought',
        '💛 Empathy, emotional maturity, and kindness',
        '🚀 Passion, drive, and mutual encouragement',
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => setState(() => _step--),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
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

              const SizedBox(height: 24),

              ...((q['options'] as List<String>).asMap().entries.map((e) {
                final selected = _answers[_step] == e.key;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectAnswer(e.key),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.surfaceVariant.withOpacity(0.6)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.border,
                            width: selected ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.value,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                  color: selected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
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
