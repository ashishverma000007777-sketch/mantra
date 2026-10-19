import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_button.dart';
import '../widgets/step_bar.dart';

class PromptsScreen extends StatelessWidget {
  const PromptsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepBar(current: 6, total: 6),
              const SizedBox(height: 24),
              Text('Tell your story', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Choose 3 prompts. These show the real you.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 24),
              ...[
                "The most spontaneous thing I've done...",
                "I'll never shut up about...",
                "My love language is...",
              ].asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSpacing.radiusLG), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.value, style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      decoration: InputDecoration(hintText: 'Your answer...', hintStyle: TextStyle(color: AppColors.textMuted), border: InputBorder.none, contentPadding: EdgeInsets.zero),
                    ),
                  ],
                ),
              )),
              const Spacer(),
              MantraButton(label: "Let's go! 🌱", onPressed: () => context.push('/onboarding/safety-tour'), icon: Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
