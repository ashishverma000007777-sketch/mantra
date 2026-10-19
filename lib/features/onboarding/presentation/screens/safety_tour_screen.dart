import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mantra_button.dart';

class SafetyTourScreen extends StatelessWidget {
  const SafetyTourScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.trust.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.shield_rounded, color: AppColors.trust, size: 36)),
              const SizedBox(height: 24),
              Text('You\'re in control.\nAlways.', style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Mantra is built safety-first. Here\'s what protects you:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ...[
                ('🔒', 'Photos are blurred by default'),
                ('🛡️', 'One-tap SOS alerts your contacts'),
                ('👁️', 'Ghost mode hides you instantly'),
                ('🤖', 'AI monitors for creep behavior'),
                ('🚫', 'No DMs until you\'re ready'),
              ].map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(children: [
                  Text(item.$1, style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 14),
                  Text(item.$2, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ]),
              )),
              const Spacer(),
              MantraButton(label: "I feel safe. Let's go!", onPressed: () => context.go('/home')),
            ],
          ),
        ),
      ),
    );
  }
}
