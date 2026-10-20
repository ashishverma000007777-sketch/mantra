import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/spark_model.dart';
import '../../providers/sparks_provider.dart';

class SparkDetailScreen extends ConsumerWidget {
  final String userId;
  final SparkModel? spark;

  const SparkDetailScreen({super.key, required this.userId, this.spark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SparkModel? resolvedSpark = spark;
    if (resolvedSpark == null) {
      final sparks = ref.watch(sparksProvider).value ?? [];
      for (final s in sparks) {
        if (s.userId == userId) {
          resolvedSpark = s;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(resolvedSpark?.displayName ?? 'Spark Details'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: ListView(
            children: [
              if (resolvedSpark != null) ...[
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                    child: Text(
                      resolvedSpark.displayName.isNotEmpty ? resolvedSpark.displayName[0] : '?',
                      style: const TextStyle(fontSize: 36, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '${resolvedSpark.displayName}, ${resolvedSpark.age}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Center(
                  child: Text(
                    resolvedSpark.city,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.shield_rounded, color: AppColors.trust),
                  title: const Text('Trust Score'),
                  trailing: Text(
                    '${resolvedSpark.trustScore.toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                  title: const Text('Compatibility'),
                  trailing: Text(
                    '${resolvedSpark.compatibilityScore}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (resolvedSpark.interests.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Interests', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: resolvedSpark.interests.map((tag) => Chip(
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
