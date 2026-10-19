// lib/features/chat/providers/reveal_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/gradual_reveal_model.dart';
import '../../matching/providers/mystery_match_provider.dart';

final revealProviderFamily =
    AsyncNotifierProvider.family<RevealNotifier, GradualRevealModel, String>(
  RevealNotifier.new,
);

class RevealNotifier extends FamilyAsyncNotifier<GradualRevealModel, String> {
  @override
  Future<GradualRevealModel> build(String arg) async {
    return ref.read(signatureFeaturesRepoProvider).getRevealStatus(arg);
  }

  Future<Map<String, dynamic>> requestStage(String stage) async {
    final res = await ref.read(signatureFeaturesRepoProvider).requestRevealStage(arg, stage);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(signatureFeaturesRepoProvider).getRevealStatus(arg),
    );
    return res;
  }

  Future<Map<String, dynamic>> respondStage(String stage, bool accept) async {
    final res = await ref.read(signatureFeaturesRepoProvider).respondRevealStage(arg, stage, accept);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(signatureFeaturesRepoProvider).getRevealStatus(arg),
    );
    return res;
  }

  Future<Map<String, dynamic>> revokeStage(String stage) async {
    final res = await ref.read(signatureFeaturesRepoProvider).revokeRevealStage(arg, stage);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(signatureFeaturesRepoProvider).getRevealStatus(arg),
    );
    return res;
  }
}
