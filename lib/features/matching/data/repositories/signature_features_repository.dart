// lib/features/matching/data/repositories/signature_features_repository.dart
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/mystery_match_model.dart';
import '../models/compatibility_dna_model.dart';
import '../../../chat/data/models/conversation_quest_model.dart';
import '../../../chat/data/models/gradual_reveal_model.dart';
import '../../../chat/data/models/connection_garden_model.dart';

abstract class SignatureFeaturesRepository {
  // Feature 1: Mystery Match
  Future<List<MysteryMatchModel>> getMysteryCandidates();
  Future<Map<String, dynamic>> exploreCandidate(String targetUserId);
  Future<bool> passCandidate(String targetUserId);

  // Feature 2: Compatibility DNA
  Future<Map<String, dynamic>> getCompatibilityProfile();
  Future<bool> saveCompatibilityAnswers(Map<String, dynamic> answers);
  Future<CompatibilityDnaModel> compareCompatibility(String targetUserId);

  // Feature 3: Conversation Quest
  Future<ConversationQuestModel> getDailyQuest();
  Future<ConversationQuestModel> getConnectionQuest(String connectionId);
  Future<Map<String, dynamic>> submitQuestAnswer(String questId, String connectionId, String answerText);
  Future<bool> reactToQuestAnswer(String questAnswerId, String reaction);

  // Feature 4: Gradual Identity Reveal
  Future<GradualRevealModel> getRevealStatus(String connectionId);
  Future<Map<String, dynamic>> requestRevealStage(String connectionId, String stage);
  Future<Map<String, dynamic>> respondRevealStage(String connectionId, String stage, bool accept);
  Future<Map<String, dynamic>> revokeRevealStage(String connectionId, String stage);
  Future<List<String>> getGatedPhotos(String connectionId);

  // Feature 5: Connection Garden
  Future<ConnectionGardenModel> getConnectionGarden(String connectionId);
  Future<Map<String, dynamic>> logGardenActivity(String connectionId, String activityType, {String? title, String? description});
  Future<bool> toggleGardenPrivacy(String connectionId, bool pause);
}

class SignatureFeaturesRepositoryImpl implements SignatureFeaturesRepository {
  final ApiClient? _client;

  SignatureFeaturesRepositoryImpl({ApiClient? client}) : _client = client;

  // 1. Mystery Match
  @override
  Future<List<MysteryMatchModel>> getMysteryCandidates() async {
    try {
      final res = await ApiClient.instance.get(ApiConstants.mysteryMatch);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final list = res.data['data'] as List? ?? [];
        return list.map((item) => MysteryMatchModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<Map<String, dynamic>> exploreCandidate(String targetUserId) async {
    final res = await ApiClient.instance.post(
      ApiConstants.mysteryExplore,
      data: {'target_user_id': targetUserId},
    );
    if (res.statusCode == 200 && res.data['success'] == true) {
      return res.data['data'] ?? {};
    }
    throw Exception(res.data['error'] ?? 'Failed to explore candidate');
  }

  @override
  Future<bool> passCandidate(String targetUserId) async {
    final res = await ApiClient.instance.post(
      ApiConstants.mysteryPass,
      data: {'target_user_id': targetUserId},
    );
    return res.statusCode == 200 && res.data['success'] == true;
  }

  // 2. Compatibility DNA
  @override
  Future<Map<String, dynamic>> getCompatibilityProfile() async {
    final res = await ApiClient.instance.get(ApiConstants.compatibilityProfile);
    if (res.statusCode == 200 && res.data['success'] == true) {
      return res.data['data'] ?? {};
    }
    return {};
  }

  @override
  Future<bool> saveCompatibilityAnswers(Map<String, dynamic> answers) async {
    final res = await ApiClient.instance.post(
      ApiConstants.compatibilityAnswers,
      data: {'answers': answers},
    );
    return res.statusCode == 200 && res.data['success'] == true;
  }

  @override
  Future<CompatibilityDnaModel> compareCompatibility(String targetUserId) async {
    final res = await ApiClient.instance.get('${ApiConstants.compatibilityCompare}/$targetUserId');
    if (res.statusCode == 200 && res.data['success'] == true) {
      return CompatibilityDnaModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }
    throw Exception(res.data['error'] ?? 'Failed to compute compatibility DNA');
  }

  // 3. Conversation Quest
  @override
  Future<ConversationQuestModel> getDailyQuest() async {
    final res = await ApiClient.instance.get(ApiConstants.questDaily);
    if (res.statusCode == 200 && res.data['success'] == true) {
      return ConversationQuestModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }
    throw Exception(res.data['error'] ?? 'Failed to load daily quest');
  }

  @override
  Future<ConversationQuestModel> getConnectionQuest(String connectionId) async {
    final res = await ApiClient.instance.get('${ApiConstants.questConnection}/$connectionId');
    if (res.statusCode == 200 && res.data['success'] == true) {
      return ConversationQuestModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }
    throw Exception(res.data['error'] ?? 'Failed to load connection quest');
  }

  @override
  Future<Map<String, dynamic>> submitQuestAnswer(String questId, String connectionId, String answerText) async {
    final res = await ApiClient.instance.post(
      ApiConstants.questAnswer,
      data: {
        'quest_id': questId,
        'connection_id': connectionId,
        'answer_text': answerText,
      },
    );
    if (res.statusCode == 200 && res.data['success'] == true) {
      return res.data['data'] ?? {};
    }
    throw Exception(res.data['error'] ?? 'Failed to submit answer');
  }

  @override
  Future<bool> reactToQuestAnswer(String questAnswerId, String reaction) async {
    final res = await ApiClient.instance.post(
      ApiConstants.questReact,
      data: {'quest_answer_id': questAnswerId, 'reaction': reaction},
    );
    return res.statusCode == 200 && res.data['success'] == true;
  }

  // 4. Gradual Identity Reveal
  @override
  Future<GradualRevealModel> getRevealStatus(String connectionId) async {
    final res = await ApiClient.instance.get('${ApiConstants.reveal}/$connectionId');
    if (res.statusCode == 200 && res.data['success'] == true) {
      return GradualRevealModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }
    throw Exception(res.data['error'] ?? 'Failed to load reveal status');
  }

  @override
  Future<Map<String, dynamic>> requestRevealStage(String connectionId, String stage) async {
    final res = await ApiClient.instance.post(
      '${ApiConstants.reveal}/$connectionId/request',
      data: {'stage': stage},
    );
    if (res.statusCode == 200 && res.data['success'] == true) {
      return res.data['data'] ?? {};
    }
    throw Exception(res.data['error'] ?? 'Failed to request reveal stage');
  }

  @override
  Future<Map<String, dynamic>> respondRevealStage(String connectionId, String stage, bool accept) async {
    final res = await ApiClient.instance.post(
      '${ApiConstants.reveal}/$connectionId/respond',
      data: {'stage': stage, 'accept': accept},
    );
    if (res.statusCode == 200 && res.data['success'] == true) {
      return res.data['data'] ?? {};
    }
    throw Exception(res.data['error'] ?? 'Failed to respond to reveal request');
  }

  @override
  Future<Map<String, dynamic>> revokeRevealStage(String connectionId, String stage) async {
    final res = await ApiClient.instance.post(
      '${ApiConstants.reveal}/$connectionId/revoke',
      data: {'stage': stage},
    );
    if (res.statusCode == 200 && res.data['success'] == true) {
      return res.data['data'] ?? {};
    }
    throw Exception(res.data['error'] ?? 'Failed to revoke reveal stage');
  }

  @override
  Future<List<String>> getGatedPhotos(String connectionId) async {
    final res = await ApiClient.instance.get('${ApiConstants.reveal}/$connectionId/media/photo');
    if (res.statusCode == 200 && res.data['success'] == true) {
      final list = res.data['data']?['photo_urls'] as List? ?? [];
      return list.map((e) => e.toString()).toList();
    }
    return [];
  }

  // 5. Connection Garden
  @override
  Future<ConnectionGardenModel> getConnectionGarden(String connectionId) async {
    final res = await ApiClient.instance.get('${ApiConstants.garden}/$connectionId');
    if (res.statusCode == 200 && res.data['success'] == true) {
      return ConnectionGardenModel.fromJson(res.data['data'] as Map<String, dynamic>);
    }
    throw Exception(res.data['error'] ?? 'Failed to load connection garden');
  }

  @override
  Future<Map<String, dynamic>> logGardenActivity(String connectionId, String activityType, {String? title, String? description}) async {
    final res = await ApiClient.instance.post(
      '${ApiConstants.garden}/$connectionId/activity',
      data: {
        'activity_type': activityType,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
      },
    );
    if (res.statusCode == 200 && res.data['success'] == true) {
      return res.data['data'] ?? {};
    }
    throw Exception(res.data['error'] ?? 'Failed to record garden activity');
  }

  @override
  Future<bool> toggleGardenPrivacy(String connectionId, bool pause) async {
    final res = await ApiClient.instance.post(
      '${ApiConstants.garden}/$connectionId/privacy',
      data: {'pause': pause},
    );
    return res.statusCode == 200 && res.data['success'] == true;
  }
}
