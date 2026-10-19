// test/signature_features_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:mantra/features/matching/data/models/mystery_match_model.dart';
import 'package:mantra/features/matching/data/models/compatibility_dna_model.dart';
import 'package:mantra/features/chat/data/models/conversation_quest_model.dart';
import 'package:mantra/features/chat/data/models/gradual_reveal_model.dart';
import 'package:mantra/features/chat/data/models/connection_garden_model.dart';

void main() {
  group('Mystery Match Model Tests', () {
    test('Correctly parses personality-first discovery card without photos/name', () {
      final json = {
        'id': 'cand-uuid-1',
        'masked_name': 'Soulful Thinker',
        'age': 27,
        'city': 'Bengaluru',
        'prompts': [
          {'question': 'A weekend well spent?', 'answer': 'Books and filter coffee.'},
          {'question': 'Life philosophy?', 'answer': 'Slow and intentional.'},
        ],
        'values': ['Authenticity', 'Mindfulness', 'Kindness'],
        'interests': ['Reading', 'Stargazing', 'Vinyl Records'],
        'relationship_intention': 'Long-term partnership',
        'lifestyle': {'sleep': 'Early bird', 'social': 'Introverted'},
        'compatibility_score': 88,
      };

      final candidate = MysteryCandidateModel.fromJson(json);
      expect(candidate.id, 'cand-uuid-1');
      expect(candidate.maskedName, 'Soulful Thinker');
      expect(candidate.age, 27);
      expect(candidate.city, 'Bengaluru');
      expect(candidate.prompts.length, 2);
      expect(candidate.prompts.first.question, 'A weekend well spent?');
      expect(candidate.values, contains('Mindfulness'));
      expect(candidate.interests, contains('Stargazing'));
      expect(candidate.relationshipIntention, 'Long-term partnership');
      expect(candidate.lifestyle['sleep'], 'Early bird');
      expect(candidate.compatibilityScore, 88);
    });

    test('Handles empty and fallback fields gracefully', () {
      final json = {
        'id': 'cand-uuid-2',
      };

      final candidate = MysteryCandidateModel.fromJson(json);
      expect(candidate.id, 'cand-uuid-2');
      expect(candidate.maskedName, 'A Thoughtful Soul');
      expect(candidate.age, 25);
      expect(candidate.prompts, isEmpty);
      expect(candidate.values, isEmpty);
      expect(candidate.interests, isEmpty);
      expect(candidate.compatibilityScore, 75);
    });
  });

  group('Compatibility DNA Model Tests', () {
    test('Correctly parses all 7 Slow-Dating dimensions', () {
      final json = {
        'overall_score': 84,
        'summary': 'High intellectual and lifestyle synergy.',
        'dimensions': [
          {
            'dimension': 'communication',
            'score': 88,
            'summary': 'Both value deep, reflective dialogue.',
            'alignment': 'strong',
          },
          {
            'dimension': 'relationship_intentions',
            'score': 90,
            'summary': 'Aligned on long-term commitment.',
            'alignment': 'strong',
          },
          {
            'dimension': 'core_values',
            'score': 82,
            'summary': 'Shared grounding in empathy and growth.',
            'alignment': 'strong',
          },
          {
            'dimension': 'lifestyle',
            'score': 78,
            'summary': 'Complementary daily rhythms.',
            'alignment': 'moderate',
          },
          {
            'dimension': 'emotional_readiness',
            'score': 85,
            'summary': 'Both seek emotionally mature connection.',
            'alignment': 'strong',
          },
          {
            'dimension': 'conflict_resolution',
            'score': 80,
            'summary': 'Calm, communicative approach.',
            'alignment': 'strong',
          },
          {
            'dimension': 'shared_interests',
            'score': 75,
            'summary': 'Overlapping love for arts and culture.',
            'alignment': 'moderate',
          },
        ],
      };

      final dna = CompatibilityDnaModel.fromJson(json);
      expect(dna.overallScore, 84);
      expect(dna.summary, 'High intellectual and lifestyle synergy.');
      expect(dna.dimensions.length, 7);

      final comm = dna.dimensions.firstWhere((d) => d.dimension == 'communication');
      expect(comm.displayName, 'Communication');
      expect(comm.score, 88);
      expect(comm.alignment, 'strong');
      expect(comm.icon, isNotEmpty);
    });
  });

  group('Conversation Quest Model Tests', () {
    test('Parses daily prompt and handles mutual unlock state', () {
      final json = {
        'id': 'quest-42',
        'category': 'values',
        'prompt': 'What value do you cherish most?',
        'follow_up_prompt': 'When was this value tested recently?',
        'day_number': 4,
        'my_answer': 'Honesty, even when uncomfortable.',
        'partner_answer': 'Vulnerability and trust.',
        'partner_has_answered': true,
        'is_unlocked': true,
        'reactions': [
          {'user_id': 'u1', 'reaction': '❤️'},
          {'user_id': 'u2', 'reaction': '✨'},
        ],
      };

      final quest = ConversationQuestModel.fromJson(json);
      expect(quest.id, 'quest-42');
      expect(quest.category, 'values');
      expect(quest.categoryDisplayName, 'Core Values');
      expect(quest.isAnsweredByMe, true);
      expect(quest.partnerHasAnswered, true);
      expect(quest.isUnlocked, true);
      expect(quest.partnerAnswer, 'Vulnerability and trust.');
      expect(quest.reactions.length, 2);
    });

    test('Hides partner answer if not unlocked', () {
      final json = {
        'id': 'quest-43',
        'category': 'lifestyle',
        'prompt': 'How do you unwind after a long week?',
        'day_number': 5,
        'my_answer': null,
        'partner_has_answered': true,
        'is_unlocked': false,
      };

      final quest = ConversationQuestModel.fromJson(json);
      expect(quest.isAnsweredByMe, false);
      expect(quest.partnerHasAnswered, true);
      expect(quest.isUnlocked, false);
      expect(quest.partnerAnswer, isNull);
    });
  });

  group('Gradual Reveal Model Tests', () {
    test('Validates stage progression and mutual consent status', () {
      final json = {
        'current_stage': 'mind',
        'my_requested_stage': 'voice',
        'partner_requested_stage': null,
        'is_mutual_voice': false,
        'is_mutual_connection': false,
        'is_mutual_face': false,
      };

      final reveal = GradualRevealModel.fromJson(json);
      expect(reveal.currentStage, RevealStage.mind);
      expect(reveal.myRequestedStage, RevealStage.voice);
      expect(reveal.isPendingMyRequest, true);
      expect(reveal.nextStage, RevealStage.voice);
      expect(reveal.isFaceRevealed, false);
      expect(reveal.isVoiceRevealed, false);
    });

    test('Validates full mutual face reveal stage', () {
      final json = {
        'current_stage': 'face',
        'my_requested_stage': 'face',
        'partner_requested_stage': 'face',
        'is_mutual_voice': true,
        'is_mutual_connection': true,
        'is_mutual_face': true,
      };

      final reveal = GradualRevealModel.fromJson(json);
      expect(reveal.currentStage, RevealStage.face);
      expect(reveal.isFaceRevealed, true);
      expect(reveal.isVoiceRevealed, true);
      expect(reveal.nextStage, isNull);
      expect(reveal.isPendingMyRequest, false);
    });
  });

  group('Connection Garden Model Tests', () {
    test('Calculates growth stage correctly based on score', () {
      final seedGarden = ConnectionGardenModel.fromJson({
        'connection_id': 'conn-1',
        'growth_stage': 'seed',
        'growth_points': 20,
        'streak_days': 2,
        'milestones': [],
      });
      expect(seedGarden.stage, GardenStage.seed);
      expect(seedGarden.stageName, 'Seed');
      expect(seedGarden.nextStageThreshold, 50);

      final sproutGarden = ConnectionGardenModel.fromJson({
        'connection_id': 'conn-2',
        'growth_stage': 'sprout',
        'growth_points': 65,
        'streak_days': 4,
        'milestones': ['first_quest'],
      });
      expect(sproutGarden.stage, GardenStage.sprout);
      expect(sproutGarden.stageName, 'Sprout');
      expect(sproutGarden.nextStageThreshold, 150);

      final bloomGarden = ConnectionGardenModel.fromJson({
        'connection_id': 'conn-3',
        'growth_stage': 'bloom',
        'growth_points': 320,
        'streak_days': 15,
        'milestones': ['first_quest', 'voice_shared', 'full_bloom'],
      });
      expect(bloomGarden.stage, GardenStage.bloom);
      expect(bloomGarden.stageName, 'Full Bloom');
      expect(bloomGarden.progressPercent, 1.0);
    });
  });
}
