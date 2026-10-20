import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preview/dev_preview.dart';
import '../data/models/spark_model.dart';
import '../data/repositories/sparks_repository.dart';

final sparksRepositoryProvider = Provider<SparksRepository>((ref) {
  return SparksRepositoryImpl();
});

final sparksProvider =
    AsyncNotifierProvider<SparksNotifier, List<SparkModel>>(
  SparksNotifier.new,
);

class SparksNotifier extends AsyncNotifier<List<SparkModel>> {
  @override
  Future<List<SparkModel>> build() async {
    final isPreview = !kReleaseMode && ref.watch(devPreviewProvider);
    if (isPreview) {
      return DevMockData.mockSparks;
    }
    return ref.read(sparksRepositoryProvider).getDailySparks();
  }

  Future<void> connect(String userId) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((s) => s.userId != userId).toList());
    final isPreview = !kReleaseMode && ref.read(devPreviewProvider);
    if (!isPreview) {
      await ref.read(sparksRepositoryProvider).connect(userId);
    }
  }

  Future<void> pass(String userId) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((s) => s.userId != userId).toList());
    final isPreview = !kReleaseMode && ref.read(devPreviewProvider);
    if (!isPreview) {
      await ref.read(sparksRepositoryProvider).pass(userId);
    }
  }

  Future<void> save(String userId) async {
    final isPreview = !kReleaseMode && ref.read(devPreviewProvider);
    if (!isPreview) {
      await ref.read(sparksRepositoryProvider).save(userId);
    }
  }
}
