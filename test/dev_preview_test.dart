// test/dev_preview_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mantra/core/preview/dev_preview.dart';
import 'package:mantra/features/auth/data/models/user_model.dart';
import 'package:mantra/features/matching/data/repositories/signature_features_repository.dart';
import 'package:mantra/features/matching/providers/mystery_match_provider.dart';
import 'package:mantra/features/matching/providers/sparks_provider.dart';
import 'package:mantra/features/matching/providers/compatibility_provider.dart';
import 'package:mantra/features/chat/providers/quest_provider.dart';
import 'package:mantra/features/chat/providers/garden_provider.dart';

void main() {
  group('DevPreviewNotifier State Management', () {
    test('Defaults to false, enters and exits preview state accurately', () {
      final notifier = DevPreviewNotifier();
      expect(notifier.state, false);

      final entered = notifier.enterPreview();
      expect(entered, true);
      expect(notifier.state, true);

      notifier.exitPreview();
      expect(notifier.state, false);
    });

    test('isDevPreviewSupported compiles as boolean constant', () {
      expect(isDevPreviewSupported, isA<bool>());
    });
  });

  group('DevMockData Integrity Tests', () {
    test('previewUser has valid schema and roundtrips to JSON', () {
      final user = DevMockData.previewUser;
      expect(user.id, 'dev-preview-user-001');
      expect(user.phoneHash, 'dev_preview_phone_hash_only');
      expect(user.verificationLevel, 4);
      expect(user.accountStatus, 'active');
      expect(user.gender, 'woman');
      expect(user.age, 26);
      expect(user.city, 'Bengaluru');
      expect(user.isOnboarded, true);

      final json = user.toJson();
      final reconstituted = UserModel.fromJson(json);
      expect(reconstituted.id, user.id);
      expect(reconstituted.age, user.age);
      expect(reconstituted.isOnboarded, true);
    });

    test('mockSparks contains curated offline profiles with blurred photos', () {
      final sparks = DevMockData.mockSparks;
      expect(sparks.length, 3);

      for (final s in sparks) {
        expect(s.userId.startsWith('dev-spark-'), true);
        expect(s.displayName.isNotEmpty, true);
        expect(s.trustScore, greaterThan(80.0));
        expect(s.compatibilityScore, greaterThan(80));
        expect(s.photosBlurred, true);
        expect(s.interests.isNotEmpty, true);
      }
    });

    test('mockMysteryCandidates redacts names and photos for slow-dating discovery', () {
      final candidates = DevMockData.mockMysteryCandidates;
      expect(candidates.length, 2);

      for (final c in candidates) {
        expect(c.candidateId.startsWith('dev-mystery-'), true);
        expect(c.pseudonym.isNotEmpty, true);
        expect(c.photosHidden, true);
        expect(c.promptResponses.isNotEmpty, true);
        expect(c.trustScore, greaterThan(80.0));
      }
    });

    test('mockCompatibilityDna provides multidimensional insights and ethical notice', () {
      final dna = DevMockData.mockCompatibilityDna('target-user-abc');
      expect(dna.targetUserId, 'target-user-abc');
      expect(dna.overallAlignment, 88);
      expect(dna.evaluatedDimensionsCount, 4);
      expect(dna.dimensions.containsKey('values'), true);
      expect(dna.dimensions.containsKey('lifestyle'), true);
      expect(dna.dimensions.containsKey('communication'), true);
      expect(dna.dimensions.containsKey('emotional_pace'), true);
      expect(dna.ethicalNotice.isNotEmpty, true);
    });

    test('mockQuests, mockRevealStatus, and mockConnectionGarden structure', () {
      final dailyQuest = DevMockData.mockDailyQuest();
      expect(dailyQuest.id, 'dev-quest-daily-001');
      expect(dailyQuest.isUnlocked, true);
      expect(dailyQuest.myAnswer != null, true);
      expect(dailyQuest.partnerAnswer != null, true);

      final reveal = DevMockData.mockRevealStatus('conn-1');
      expect(reveal.currentStage, 'connection');
      expect(reveal.isVoiceUnlocked, true);
      expect(reveal.isPhotoUnlocked, false);

      final garden = DevMockData.mockConnectionGarden('conn-1');
      expect(garden.stage, 'blooming');
      expect(garden.growthPoints, 180);
      expect(garden.milestones.length, 3);
      expect(garden.antiStreakGuarantee.isNotEmpty, true);
    });

    test('mockConversations contains both id and conversation_id keys', () {
      final convs = DevMockData.mockConversations;
      expect(convs.length, 2);
      for (final c in convs) {
        expect(c['id'], isNotNull);
        expect(c['conversation_id'], isNotNull);
        expect(c['display_name'], isNotNull);
      }
    });

    test('mockMessages provides structured offline dialogues', () {
      final msgs = DevMockData.mockMessages;
      expect(msgs.length, 3);
      expect(msgs[0].isMine, false);
      expect(msgs[1].isMine, true);
    });
  });

  group('DevPreviewSignatureFeaturesRepository Unit Tests', () {
    late DevPreviewSignatureFeaturesRepository repo;

    setUp(() {
      repo = DevPreviewSignatureFeaturesRepository();
    });

    test('All repository methods execute offline successfully without network', () async {
      final candidates = await repo.getMysteryCandidates();
      expect(candidates.length, 2);

      final exploreRes = await repo.exploreCandidate('cand-1');
      expect(exploreRes['matched'], true);

      final passRes = await repo.passCandidate('cand-1');
      expect(passRes, true);

      final profile = await repo.getCompatibilityProfile();
      expect(profile['status'], 'complete');

      final saved = await repo.saveCompatibilityAnswers({'q1': 'ans1'});
      expect(saved, true);

      final dna = await repo.compareCompatibility('cand-1');
      expect(dna.overallAlignment, 88);

      final dailyQuest = await repo.getDailyQuest();
      expect(dailyQuest.isUnlocked, true);

      final connQuest = await repo.getConnectionQuest('conn-1');
      expect(connQuest.category, 'Shared Memories');

      final submitRes = await repo.submitQuestAnswer('q-1', 'conn-1', 'answer text');
      expect(submitRes['success'], true);
      expect(submitRes['garden_points_earned'], 15);

      final reactRes = await repo.reactToQuestAnswer('ans-1', '🌿');
      expect(reactRes, true);

      final reveal = await repo.getRevealStatus('conn-1');
      expect(reveal.currentStage, 'connection');

      final reqStage = await repo.requestRevealStage('conn-1', 'face');
      expect(reqStage['status'], 'pending');

      final respStage = await repo.respondRevealStage('conn-1', 'face', true);
      expect(respStage['accepted'], true);

      final revokeStage = await repo.revokeRevealStage('conn-1', 'face');
      expect(revokeStage['revoked'], true);

      final photos = await repo.getGatedPhotos('conn-1');
      expect(photos, isEmpty);

      final garden = await repo.getConnectionGarden('conn-1');
      expect(garden.stage, 'blooming');

      final gardenActivity = await repo.logGardenActivity('conn-1', 'voice_exchange');
      expect(gardenActivity['success'], true);

      final togglePrivacy = await repo.toggleGardenPrivacy('conn-1', true);
      expect(togglePrivacy, true);
    });
  });

  group('Riverpod Provider Switching in Preview Mode', () {
    test('signatureFeaturesRepoProvider yields DevPreviewSignatureFeaturesRepository in preview mode', () {
      final container = ProviderContainer(
        overrides: [
          devPreviewProvider.overrideWith((ref) {
            final notifier = DevPreviewNotifier();
            notifier.enterPreview();
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(signatureFeaturesRepoProvider);
      expect(repo is DevPreviewSignatureFeaturesRepository, true);
    });

    test('sparksProvider returns DevMockData.mockSparks in preview mode', () async {
      final container = ProviderContainer(
        overrides: [
          devPreviewProvider.overrideWith((ref) {
            final notifier = DevPreviewNotifier();
            notifier.enterPreview();
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      final sparks = await container.read(sparksProvider.future);
      expect(sparks.length, 3);
      expect(sparks.first.displayName, 'Aanya');
    });

    test('mysteryMatchProvider returns DevMockData.mockMysteryCandidates in preview mode', () async {
      final container = ProviderContainer(
        overrides: [
          devPreviewProvider.overrideWith((ref) {
            final notifier = DevPreviewNotifier();
            notifier.enterPreview();
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      final candidates = await container.read(mysteryMatchProvider.future);
      expect(candidates.length, 2);
      expect(candidates.first.pseudonym, 'Silent Reader');
    });

    test('dailyQuestProvider returns DevMockData.mockDailyQuest in preview mode', () async {
      final container = ProviderContainer(
        overrides: [
          devPreviewProvider.overrideWith((ref) {
            final notifier = DevPreviewNotifier();
            notifier.enterPreview();
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      final quest = await container.read(dailyQuestProvider.future);
      expect(quest.id, 'dev-quest-daily-001');
      expect(quest.isUnlocked, true);
    });

    test('connectionGardenFamily returns DevMockData.mockConnectionGarden in preview mode', () async {
      final container = ProviderContainer(
        overrides: [
          devPreviewProvider.overrideWith((ref) {
            final notifier = DevPreviewNotifier();
            notifier.enterPreview();
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      final garden = await container.read(connectionGardenFamily('test-conn-1').future);
      expect(garden.stage, 'blooming');
      expect(garden.growthPoints, 180);
    });
  });
}
