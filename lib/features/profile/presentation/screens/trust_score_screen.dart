import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TrustScoreScreen extends StatelessWidget {
  const TrustScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Trust Score'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.shield_rounded, size: 64, color: AppColors.trust),
                const SizedBox(height: 12),
                const Text('Trust Score: 85', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('High Trust Member · Verified Phone & Liveness', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('How your score is calculated', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ListTile(leading: const Icon(Icons.check_circle_rounded, color: Colors.green), title: const Text('Phone verified'), trailing: const Text('+20')),
          ListTile(leading: const Icon(Icons.check_circle_rounded, color: Colors.green), title: const Text('Profile photos added'), trailing: const Text('+15')),
          ListTile(leading: const Icon(Icons.check_circle_rounded, color: Colors.green), title: const Text('Voice intro recorded'), trailing: const Text('+20')),
          ListTile(leading: const Icon(Icons.check_circle_rounded, color: Colors.green), title: const Text('Zero safety reports'), trailing: const Text('+30')),
        ],
      ),
    );
  }
}
