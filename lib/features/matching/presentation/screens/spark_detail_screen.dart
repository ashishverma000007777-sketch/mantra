import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/spark_model.dart';

class SparkDetailScreen extends StatelessWidget {
  final String userId;
  final SparkModel? spark;

  const SparkDetailScreen({super.key, required this.userId, this.spark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(spark?.displayName ?? 'Spark Details'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: ListView(
            children: [
              if (spark != null) ...[
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                    child: Text(
                      spark!.displayName.isNotEmpty ? spark!.displayName[0] : '?',
                      style: const TextStyle(fontSize: 36, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '${spark!.displayName}, ${spark!.age}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Center(
                  child: Text(
                    spark!.city,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.shield_rounded, color: AppColors.trust),
                  title: const Text('Trust Score'),
                  trailing: Text(
                    '${spark!.trustScore.toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                  title: const Text('Compatibility'),
                  trailing: Text(
                    '${spark!.compatibilityScore}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (spark!.interests.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Interests', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: spark!.interests.map((tag) => Chip(
                      label: Text(tag),
                      backgroundColor: AppColors.surface,
                    )).toList(),
                  ),
                ],
              ] else ...[
                Center(child: Text('User ID: $userId')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
