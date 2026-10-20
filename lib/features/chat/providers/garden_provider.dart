// lib/features/chat/providers/garden_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/connection_garden_model.dart';
import '../../matching/providers/mystery_match_provider.dart';

final connectionGardenFamily =
    AsyncNotifierProvider.family<GardenNotifier, ConnectionGardenModel, String>(
  GardenNotifier.new,
);

class GardenNotifier extends FamilyAsyncNotifier<ConnectionGardenModel, String> {
  @override
  Future<ConnectionGardenModel> build(String arg) async {
    return ref.watch(signatureFeaturesRepoProvider).getConnectionGarden(arg);
  }

  Future<void> logActivity(String activityType, {String? title, String? description}) async {
    await ref.read(signatureFeaturesRepoProvider).logGardenActivity(arg, activityType, title: title, description: description);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(signatureFeaturesRepoProvider).getConnectionGarden(arg),
    );
  }

  Future<void> togglePrivacy(bool pause) async {
    await ref.read(signatureFeaturesRepoProvider).toggleGardenPrivacy(arg, pause);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(signatureFeaturesRepoProvider).getConnectionGarden(arg),
    );
  }
}
