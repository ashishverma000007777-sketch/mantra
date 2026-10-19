import '../widgets/step_bar.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_button.dart';

class PersonalityQuizScreen extends StatefulWidget {
  const PersonalityQuizScreen({super.key});
  @override
  State<PersonalityQuizScreen> createState() => _PersonalityQuizScreenState();
}

class _PersonalityQuizScreenState extends State<PersonalityQuizScreen> {
  int _step = 0;
  final Map<int, int> _answers = {};

  final _questions = [
    {
      'q': 'Your ideal Saturday?',
      'options': ['🏔️ Hiking / outdoors', '☕ Cozy café', '🛋️ Home, recharging', '🎶 Live event / concert'],
    },
    {
      'q': 'Meeting someone new, you feel...',
      'options': ['😃 Excited', '😅 Nervous but curious', '😌 Calm observer', '🤐 Quiet until comfortable'],
    },
    {
      'q': 'Conversations you love are...',
      'options': ['🌊 Deep & meaningful', '😂 Fun & playful', '🧠 Intellectual', '🎲 Totally random'],
    },
    {
      'q': 'Your emotional style?',
      'options': ['❤️ Openly expressive', '🤔 Thoughtful & reserved', '😄 Humor is my armor', '🌱 Still figuring out'],
    },
    {
      'q': 'You value most:',
      'options': ['🤝 Loyalty', '💡 Intelligence', '💛 Kindness', '🚀 Ambition'],
    },
  ];

  void _selectAnswer(int optionIdx) {
    setState(() => _answers[_step] = optionIdx);
    Future.delayed(const Duration(milliseconds: 300), () {
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
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepBar(current: _step + 1, total: _questions.length),
              const SizedBox(height: 32),
              Text(
                q['q'] as String,
                style: Theme.of(context).textTheme.headlineMedium,
                key: ValueKey(_step),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 28),
              ...((q['options'] as List<String>).asMap().entries.map((e) {
                final selected = _answers[_step] == e.key;
                return GestureDetector(
                  onTap: () => _selectAnswer(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryLight.withOpacity(0.15) : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
                    ),
                    child: Text(e.value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: selected ? AppColors.primary : AppColors.textPrimary)),
                  ),
                ).animate(delay: Duration(milliseconds: e.key * 60)).fadeIn(duration: 250.ms).slideX(begin: 0.04, end: 0);
              })),
            ],
          ),
        ),
      ),
    );
  }
}
