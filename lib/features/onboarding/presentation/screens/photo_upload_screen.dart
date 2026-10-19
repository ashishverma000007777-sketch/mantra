import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_button.dart';
import '../widgets/step_bar.dart';

class PhotoUploadScreen extends StatelessWidget {
  const PhotoUploadScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, actions: [
        TextButton(onPressed: () => context.push('/onboarding/prompts'), child: Text('Skip', style: TextStyle(color: AppColors.textMuted))),
      ]),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepBar(current: 5, total: 6),
              const SizedBox(height: 24),
              Text('Add your photos', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Photos are blurred until you reveal them. You\'re in control.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
              const SizedBox(height: 32),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: List.generate(6, (i) => Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                  ),
                  child: i == 0
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 28),
                        const SizedBox(height: 4),
                        Text('Add', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                      ])
                    : Icon(Icons.add_rounded, color: AppColors.border, size: 24),
                )),
              ),
              const Spacer(),
              MantraButton(label: 'Continue', onPressed: () => context.push('/onboarding/prompts'), icon: Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
