// lib/features/matching/providers/mystery_match_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/mystery_match_model.dart';
import '../data/repositories/signature_features_repository.dart';

final signatureFeaturesRepoProvider = Provider<SignatureFeaturesRepository>((ref) {
  return SignatureFeaturesRepositoryImpl();
});

final mysteryMatchProvider =
    AsyncNotifierProvider<MysteryMatchNotifier, List<MysteryMatchModel>>(
  MysteryMatchNotifier.new,
);

class MysteryMatchNotifier extends AsyncNotifier<List<MysteryMatchModel>> {
  @override
  Future<List<MysteryMatchModel>> build() async {
    return ref.read(signatureFeaturesRepoProvider).getMysteryCandidates();
  }

  Future<Map<String, dynamic>> explore(String candidateId) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((c) => c.candidateId != candidateId).toList());
    return ref.read(signatureFeaturesRepoProvider).exploreCandidate(candidateId);
  }

  Future<void> pass(String candidateId) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((c) => c.candidateId != candidateId).toList());
    await ref.read(signatureFeaturesRepoProvider).passCandidate(candidateId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(signatureFeaturesRepoProvider).getMysteryCandidates(),
    );
  }
}
