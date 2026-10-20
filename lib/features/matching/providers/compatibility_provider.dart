// lib/features/matching/providers/compatibility_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/compatibility_dna_model.dart';
import 'mystery_match_provider.dart';

final compatibilityDnaFamily =
    FutureProvider.family<CompatibilityDnaModel, String>((ref, targetUserId) async {
  return ref.watch(signatureFeaturesRepoProvider).compareCompatibility(targetUserId);
});

final myCompatibilityProfileProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(signatureFeaturesRepoProvider).getCompatibilityProfile();
});
