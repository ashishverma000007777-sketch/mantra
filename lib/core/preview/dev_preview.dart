// lib/core/preview/dev_preview.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/models/user_model.dart';
import '../../features/matching/data/models/spark_model.dart';
import '../../features/matching/data/models/mystery_match_model.dart';
import '../../features/matching/data/models/compatibility_dna_model.dart';
import '../../features/matching/data/repositories/signature_features_repository.dart';
import '../../features/chat/data/models/conversation_quest_model.dart';
import '../../features/chat/data/models/gradual_reveal_model.dart';
import '../../features/chat/data/models/connection_garden_model.dart';
import '../../features/chat/data/models/message_model.dart';

/// Whether development preview is permitted on this runtime build.
/// Strictly FALSE in release/production builds (compile-time constant).
bool get isDevPreviewSupported => !kReleaseMode;

/// Development Preview state provider.
/// Completely decoupled from real credentials and production storage.
final devPreviewProvider = StateNotifierProvider<DevPreviewNotifier, bool>((ref) {
  return DevPreviewNotifier();
});

class DevPreviewNotifier extends StateNotifier<bool> {
  DevPreviewNotifier() : super(false);

  /// Enters development preview mode.
  /// Strictly rejected if running in release mode.
  bool enterPreview() {
    if (kReleaseMode) {
      // Security restriction: strictly prohibited in release/production builds
      state = false;
      return false;
    }
    state = true;
    return true;
  }

  /// Exits development preview mode and restores unauthenticated state.
  void exitPreview() {
    state = false;
  }
}

/// Mindfully structured, offline mock data for development UI testing.
class DevMockData {
  DevMockData._();

  static UserModel get previewUser => UserModel(
        id: 'dev-preview-user-001',
        phoneHash: 'dev_preview_phone_hash_only',
        verificationLevel: 4,
        accountStatus: 'active',
        gender: 'woman',
        age: 26,
        city: 'Bengaluru',
        createdAt: DateTime(2026, 1, 15),
        lastActive: DateTime.now(),
        isPremium: false,
        premiumTier: null,
        isOnboarded: true,
      );

  static List<SparkModel> get mockSparks => const [
        SparkModel(
          userId: 'dev-spark-001',
          displayName: 'Aanya',
          age: 25,
          city: 'Bengaluru',
          profilePhotoUrl: 'assets/images/portrait_aanya.jpg',
          photosBlurred: true,
          trustScore: 88.0,
          compatibilityScore: 92,
          isVerified: true,
          interests: ['Chai', 'Literature', 'Film Photography', 'Indie Rock'],
          voiceIntroUrl: null,
          voiceDurationSeconds: 18,
          sharedInterests: ['Chai', 'Literature'],
          sharedRoomsCount: 2,
        ),
        SparkModel(
          userId: 'dev-spark-002',
          displayName: 'Kabir',
          age: 27,
          city: 'Mumbai',
          profilePhotoUrl: 'assets/images/portrait_kabir.jpg',
          photosBlurred: true,
          trustScore: 84.0,
          compatibilityScore: 86,
          isVerified: true,
          interests: ['Architecture', 'Hiking', 'Slow Living', 'Podcasts'],
          voiceIntroUrl: null,
          voiceDurationSeconds: 22,
          sharedInterests: ['Slow Living'],
          sharedRoomsCount: 1,
        ),
        SparkModel(
          userId: 'dev-spark-003',
          displayName: 'Meera',
          age: 26,
          city: 'Pune',
          profilePhotoUrl: 'assets/images/portrait_meera.jpg',
          photosBlurred: true,
          trustScore: 91.0,
          compatibilityScore: 89,
          isVerified: true,
          interests: ['Pottery', 'Poetry', 'Jazz', 'Filter Coffee'],
          voiceIntroUrl: null,
          voiceDurationSeconds: 15,
          sharedInterests: ['Poetry', 'Filter Coffee'],
          sharedRoomsCount: 3,
        ),
      ];

  static List<MysteryMatchModel> get mockMysteryCandidates => const [
        MysteryMatchModel(
          candidateId: 'dev-mystery-001',
          pseudonym: 'Silent Reader',
          age: 26,
          city: 'Bengaluru',
          intent: 'Looking for a thoughtful, slow-paced relationship',
          personalityTags: ['Introspective', 'Creative', 'Values-driven', 'Calm'],
          sharedInterests: ['Books', 'Tea rituals', 'Art museums'],
          promptResponses: [
            MysteryPromptResponse(
              question: 'The book that fundamentally shifted how I see the world',
              answer: 'The Overstory by Richard Powers. It reminded me to live with deep patience and humility.',
            ),
            MysteryPromptResponse(
              question: 'My ideal Sunday evening in three words',
              answer: 'Warm lamp, rain, chai.',
            ),
            MysteryPromptResponse(
              question: 'A boundary I hold sacred in love',
              answer: 'Giving each other the space to grow independently without hurry.',
            ),
          ],
          trustScore: 89.0,
          hasVoiceIntro: true,
          photosHidden: true,
        ),
        MysteryMatchModel(
          candidateId: 'dev-mystery-002',
          pseudonym: 'Wandering Storyteller',
          age: 28,
          city: 'Mumbai',
          intent: 'Meaningful companionship built on shared curiosity',
          personalityTags: ['Empathetic', 'Musical', 'Grounded', 'Attentive'],
          sharedInterests: ['Old Hindi songs', 'Heritage walks', 'Writing'],
          promptResponses: [
            MysteryPromptResponse(
              question: 'Something I value far more than convenience',
              answer: 'Handwritten notes and taking the long scenic train route home.',
            ),
            MysteryPromptResponse(
              question: 'What slow dating means to me',
              answer: 'Getting to know the mind and cadence of someone before their appearance takes over.',
            ),
          ],
          trustScore: 86.0,
          hasVoiceIntro: true,
          photosHidden: true,
        ),
      ];

  static CompatibilityDnaModel mockCompatibilityDna(String targetUserId) => CompatibilityDnaModel(
        targetUserId: targetUserId,
        overallAlignment: 88,
        evaluatedDimensionsCount: 4,
        dimensions: const {
          'values': DimensionInsightModel(
            dimension: 'Core Values & Ethics',
            score: 92,
            insight: 'High alignment on mutual respect, honesty, and financial transparency.',
            contributingFactors: ['Prioritizes family harmony', 'Values mindful career balance'],
            sharedItems: ['Transparency', 'Long-term commitment'],
          ),
          'lifestyle': DimensionInsightModel(
            dimension: 'Lifestyle & Rhythms',
            score: 84,
            insight: 'Both prefer low-key quiet weekends over crowded nightlife.',
            contributingFactors: ['Early riser', 'Enjoys outdoor nature walks'],
            sharedItems: ['Slow mornings', 'Quiet spaces'],
          ),
          'communication': DimensionInsightModel(
            dimension: 'Communication Style',
            score: 79,
            insight: 'Both practice reflective responses rather than impulsive replies.',
            contributingFactors: ['Direct yet gentle with feedback', 'Values voice notes over text floods'],
            sharedItems: ['Voice check-ins', 'Deep questions'],
          ),
          'emotional_pace': DimensionInsightModel(
            dimension: 'Emotional Pace',
            score: 91,
            insight: 'Exceptional match on taking intentional time to build genuine trust.',
            contributingFactors: ['Believes in gradual identity reveal', 'Anti-streak mindset'],
            sharedItems: ['Patience', 'Intentionality'],
          ),
        },
        ethicalNotice:
            'These insights reflect self-reported preferences to foster understanding, not a psychological guarantee.',
      );

  static ConversationQuestModel mockDailyQuest() => const ConversationQuestModel(
        id: 'dev-quest-daily-001',
        category: 'Values & Reflections',
        promptText: 'What is a life belief or lesson you unlearned in the last three years?',
        followUpPrompt: 'What experience prompted that shift in perspective?',
        hasUserAnswered: true,
        hasPartnerAnswered: true,
        isUnlocked: true,
        myAnswer: QuestAnswerItem(
          id: 'dev-ans-001',
          answerText: 'I unlearned the idea that rest must always be earned through exhaustion. Rest is self-respect.',
          createdAt: '2026-10-19T10:00:00Z',
          reactions: ['🌿', '🤍'],
        ),
        partnerAnswer: QuestAnswerItem(
          id: 'dev-ans-002',
          answerText: 'I stopped believing that love requires losing your personal solitude.',
          createdAt: '2026-10-19T11:30:00Z',
          reactions: ['✨', '🙏'],
        ),
      );

  static ConversationQuestModel mockConnectionQuest(String connectionId) => ConversationQuestModel(
        id: 'dev-quest-conn-001',
        category: 'Shared Memories',
        promptText: 'What is a childhood memory that still brings an instant smile to your face?',
        followUpPrompt: 'Does that memory still influence how you spend your free time today?',
        hasUserAnswered: true,
        hasPartnerAnswered: false,
        isUnlocked: false,
        myAnswer: const QuestAnswerItem(
          id: 'dev-ans-conn-001',
          answerText: 'Stealing freshly fried kachoris from nani\'s kitchen with my cousins during Diwali holidays.',
          createdAt: '2026-10-19T14:00:00Z',
          reactions: [],
        ),
        partnerAnswer: null,
      );

  static GradualRevealModel mockRevealStatus(String connectionId) => GradualRevealModel(
        connectionId: connectionId,
        currentStage: 'connection',
        myConsent: const {'voice': true, 'connection': true, 'face': false},
        partnerConsent: const {'voice': true, 'connection': true, 'face': false},
        pendingRequestsFromPartner: const [],
        pendingRequestsFromMe: const ['face'],
        isVoiceUnlocked: true,
        isPhotoUnlocked: false,
        explanation: 'Stage 2 unlocked. Both members have exchanged voice notes and conversation quests. Face reveal is pending mutual consent.',
      );

  static ConnectionGardenModel mockConnectionGarden(String connectionId) => ConnectionGardenModel(
        connectionId: connectionId,
        stage: 'blooming',
        growthPoints: 180,
        stageDescription: 'Your garden is blooming with steady conversations and mindful quests.',
        isPaused: false,
        milestones: const [
          GardenMilestoneItem(
            milestoneType: 'voice_intro',
            title: 'First Voice Exchange',
            description: 'You listened to each other\'s voice reflections.',
            achievedAt: '2026-10-17T12:00:00Z',
          ),
          GardenMilestoneItem(
            milestoneType: 'quest_completed',
            title: 'First Quest Completed',
            description: 'Both shared answers to the Values & Reflections prompt.',
            achievedAt: '2026-10-18T16:30:00Z',
          ),
          GardenMilestoneItem(
            milestoneType: 'stage_upgrade',
            title: 'Reached Connection Stage',
            description: 'Gradual identity unlock stage 2 achieved.',
            achievedAt: '2026-10-19T09:15:00Z',
          ),
        ],
        antiStreakGuarantee:
            'No penalty for breaks. Connection health never decays if life takes you away for a few days.',
        nextMilestoneSuggestion: 'Send a voice note reflection or complete today\'s Conversation Quest.',
      );

  static List<Map<String, dynamic>> get mockConversations => [
        {
          'id': 'dev-conv-001',
          'conversation_id': 'dev-conv-001',
          'display_name': 'Mira',
          'profile_photo_url': 'assets/images/portrait_meera.jpg',
          'stage': 2,
          'last_message': 'Loved your reflection on The Overstory!',
          'trust_score': 88.0,
          'unread_count': 1,
        },
        {
          'id': 'dev-conv-002',
          'conversation_id': 'dev-conv-002',
          'display_name': 'Rohan',
          'profile_photo_url': 'assets/images/portrait_kabir.jpg',
          'stage': 1,
          'last_message': 'Hey! Hope you are having a serene evening.',
          'trust_score': 82.0,
          'unread_count': 0,
        },
      ];

  static List<MessageModel> get mockMessages => [
        MessageModel(
          id: 'dev-msg-001',
          conversationId: 'dev-conv-001',
          senderId: 'partner-uid',
          type: MessageType.text,
          content: 'Hello! Really liked your note about old Hindi music on your mystery profile.',
          isMine: false,
          isRead: true,
          isDelivered: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        MessageModel(
          id: 'dev-msg-002',
          conversationId: 'dev-conv-001',
          senderId: 'dev-preview-user-001',
          type: MessageType.text,
          content: 'Thank you! It is hard to find folks who appreciate slow melodies these days.',
          isMine: true,
          isRead: true,
          isDelivered: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 40)),
        ),
        MessageModel(
          id: 'dev-msg-003',
          conversationId: 'dev-conv-001',
          senderId: 'partner-uid',
          type: MessageType.text,
          content: 'Did you check today\'s Conversation Quest? The prompt is about unlearning beliefs.',
          isMine: false,
          isRead: true,
          isDelivered: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];
}

/// Offline implementation of SignatureFeaturesRepository for development preview.
/// Completely decoupled from network calls and backend servers.
class DevPreviewSignatureFeaturesRepository implements SignatureFeaturesRepository {
  @override
  Future<List<MysteryMatchModel>> getMysteryCandidates() async {
    return DevMockData.mockMysteryCandidates;
  }

  @override
  Future<Map<String, dynamic>> exploreCandidate(String targetUserId) async {
    return {
      'matched': true,
      'target_user_id': targetUserId,
      'message': 'Connected with candidate in preview mode!',
      'reveal_stage': 'mind',
    };
  }

  @override
  Future<bool> passCandidate(String targetUserId) async {
    return true;
  }

  @override
  Future<Map<String, dynamic>> getCompatibilityProfile() async {
    return {
      'dimensions_completed': 4,
      'status': 'complete',
    };
  }

  @override
  Future<bool> saveCompatibilityAnswers(Map<String, dynamic> answers) async {
    return true;
  }

  @override
  Future<CompatibilityDnaModel> compareCompatibility(String targetUserId) async {
    return DevMockData.mockCompatibilityDna(targetUserId);
  }

  @override
  Future<ConversationQuestModel> getDailyQuest() async {
    return DevMockData.mockDailyQuest();
  }

  @override
  Future<ConversationQuestModel> getConnectionQuest(String connectionId) async {
    return DevMockData.mockConnectionQuest(connectionId);
  }

  @override
  Future<Map<String, dynamic>> submitQuestAnswer(String questId, String connectionId, String answerText) async {
    return {
      'success': true,
      'garden_points_earned': 15,
      'message': 'Response shared! Both answers unlocked in preview mode.',
    };
  }

  @override
  Future<bool> reactToQuestAnswer(String questAnswerId, String reaction) async {
    return true;
  }

  @override
  Future<GradualRevealModel> getRevealStatus(String connectionId) async {
    return DevMockData.mockRevealStatus(connectionId);
  }

  @override
  Future<Map<String, dynamic>> requestRevealStage(String connectionId, String stage) async {
    return {
      'connection_id': connectionId,
      'stage': stage,
      'status': 'pending',
      'message': 'Reveal stage $stage requested in preview mode.',
    };
  }

  @override
  Future<Map<String, dynamic>> respondRevealStage(String connectionId, String stage, bool accept) async {
    return {
      'connection_id': connectionId,
      'stage': stage,
      'accepted': accept,
      'message': accept ? 'Stage $stage unlocked in preview!' : 'Stage $stage declined.',
    };
  }

  @override
  Future<Map<String, dynamic>> revokeRevealStage(String connectionId, String stage) async {
    return {
      'connection_id': connectionId,
      'stage': stage,
      'revoked': true,
      'message': 'Stage $stage revoked in preview.',
    };
  }

  @override
  Future<List<String>> getGatedPhotos(String connectionId) async {
    return [];
  }

  @override
  Future<ConnectionGardenModel> getConnectionGarden(String connectionId) async {
    return DevMockData.mockConnectionGarden(connectionId);
  }

  @override
  Future<Map<String, dynamic>> logGardenActivity(String connectionId, String activityType, {String? title, String? description}) async {
    return {
      'success': true,
      'growth_points': 190,
      'message': 'Activity recorded in preview garden.',
    };
  }

  @override
  Future<bool> toggleGardenPrivacy(String connectionId, bool pause) async {
    return true;
  }
}
