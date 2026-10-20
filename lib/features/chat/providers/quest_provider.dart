// lib/features/chat/providers/quest_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/conversation_quest_model.dart';
import '../../matching/providers/mystery_match_provider.dart';

final dailyQuestProvider = FutureProvider<ConversationQuestModel>((ref) async {
  return ref.watch(signatureFeaturesRepoProvider).getDailyQuest();
});

final connectionQuestFamily =
    AsyncNotifierProvider.family<ConnectionQuestNotifier, ConversationQuestModel, String>(
  ConnectionQuestNotifier.new,
);

class ConnectionQuestNotifier extends FamilyAsyncNotifier<ConversationQuestModel, String> {
  @override
  Future<ConversationQuestModel> build(String arg) async {
    return ref.watch(signatureFeaturesRepoProvider).getConnectionQuest(arg);
  }

  Future<Map<String, dynamic>> submitAnswer(String questId, String answerText) async {
    final result = await ref.read(signatureFeaturesRepoProvider).submitQuestAnswer(questId, arg, answerText);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(signatureFeaturesRepoProvider).getConnectionQuest(arg),
    );
    return result;
  }

  Future<void> react(String answerId, String reaction) async {
    await ref.read(signatureFeaturesRepoProvider).reactToQuestAnswer(answerId, reaction);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(signatureFeaturesRepoProvider).getConnectionQuest(arg),
    );
  }
}
