// test/signature_features_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:mantra/features/matching/data/models/mystery_match_model.dart';
import 'package:mantra/features/matching/data/models/compatibility_dna_model.dart';
import 'package:mantra/features/chat/data/models/conversation_quest_model.dart';
import 'package:mantra/features/chat/data/models/gradual_reveal_model.dart';
import 'package:mantra/features/chat/data/models/connection_garden_model.dart';

void main() {
  group('MysteryMatchModel Unit Tests', () {
    test('Correctly parses personality-first card without exposed photos or real name', () {
      final json = {
        'candidate_id': 'cand-uuid-1',
        'pseudonym': 'Soulful Thinker',
        'age': 27,
        'city': 'Bengaluru',
        'intent': 'Long-term partnership',
        'personality_tags': ['Authenticity', 'Mindfulness', 'Kindness'],
        'shared_interests': ['Reading', 'Stargazing', 'Vinyl Records'],
        'prompt_responses': [
          {'question': 'A weekend well spent?', 'answer': 'Books and filter coffee.'},
          {'question': 'Life philosophy?', 'answer': 'Slow and intentional.'},
        ],
        'trust_score': 88.0,
        'has_voice_intro': true,
        'photos_hidden': true,
      };

      final match = MysteryMatchModel.fromJson(json);
      expect(match.candidateId, 'cand-uuid-1');
      expect(match.pseudonym, 'Soulful Thinker');
      expect(match.age, 27);
      expect(match.city, 'Bengaluru');
      expect(match.intent, 'Long-term partnership');
      expect(match.personalityTags, contains('Mindfulness'));
      expect(match.sharedInterests, contains('Stargazing'));
      expect(match.promptResponses.length, 2);
      expect(match.promptResponses.first.question, 'A weekend well spent?');
      expect(match.trustScore, 88.0);
      expect(match.photosHidden, true);
      expect(match.hasVoiceIntro, true);
    });

    test('Handles fallback fields gracefully', () {
      final json = {
        'candidate_id': 'cand-uuid-2',
      };

      final match = MysteryMatchModel.fromJson(json);
      expect(match.candidateId, 'cand-uuid-2');
      expect(match.pseudonym, 'Thoughtful Soul');
      expect(match.age, 25);
      expect(match.city, 'Nearby');
      expect(match.promptResponses, isEmpty);
      expect(match.personalityTags, isEmpty);
      expect(match.sharedInterests, isEmpty);
      expect(match.photosHidden, true);
    });
  });

  group('CompatibilityDnaModel Unit Tests', () {
    test('Correctly parses all 7 Slow-Dating dimensions and ethical disclaimer', () {
      final json = {
        'target_user_id': 'user-target-1',
        'overall_alignment': 84,
        'evaluated_dimensions_count': 7,
        'ethical_notice': 'Self-reported preferences for understanding, not a psychological guarantee.',
        'dimensions': {
          'communication': {
            'dimension': 'communication',
            'score': 88,
            'insight': 'Both value deep, reflective dialogue.',
            'contributing_factors': ['High prompt engagement', 'Consistent communication style'],
          },
          'relationship_intentions': {
            'dimension': 'relationship_intentions',
            'score': 90,
            'insight': 'Aligned on long-term commitment.',
            'contributing_factors': ['Both seeking life partner'],
          },
          'core_values': {
            'dimension': 'core_values',
            'score': 82,
            'insight': 'Shared grounding in empathy and growth.',
            'contributing_factors': ['Empathy', 'Mindfulness'],
          },
          'lifestyle': {
            'dimension': 'lifestyle',
            'score': 78,
            'insight': 'Complementary daily rhythms.',
            'contributing_factors': ['Early bird balance'],
          },
          'emotional_readiness': {
            'dimension': 'emotional_readiness',
            'score': 85,
            'insight': 'Both seek emotionally mature connection.',
            'contributing_factors': ['High self-awareness'],
          },
          'conflict_resolution': {
            'dimension': 'conflict_resolution',
            'score': 80,
            'insight': 'Calm, communicative approach.',
            'contributing_factors': ['Discussion over escalation'],
          },
          'shared_interests': {
            'dimension': 'shared_interests',
            'score': 75,
            'insight': 'Overlapping love for arts and culture.',
            'contributing_factors': ['Literature', 'Coffee'],
          },
        },
      };

      final dna = CompatibilityDnaModel.fromJson(json);
      expect(dna.targetUserId, 'user-target-1');
      expect(dna.overallAlignment, 84);
      expect(dna.evaluatedDimensionsCount, 7);
      expect(dna.dimensions.length, 7);
      expect(dna.dimensions['communication']?.score, 88);
      expect(dna.dimensions['communication']?.insight, 'Both value deep, reflective dialogue.');
      expect(dna.dimensions['core_values']?.contributingFactors, contains('Empathy'));
      expect(dna.ethicalNotice, contains('psychological guarantee'));
    });
  });

  group('ConversationQuestModel Unit Tests', () {
    test('Parses daily prompt and handles mutual unlock and reactions', () {
      final json = {
        'id': 'quest-42',
        'category': 'values',
        'prompt_text': 'What value do you cherish most?',
        'follow_up_prompt': 'When was this value tested recently?',
        'has_user_answered': true,
        'has_partner_answered': true,
        'is_unlocked': true,
        'my_answer': {
          'id': 'ans-1',
          'answer_text': 'Honesty, even when uncomfortable.',
          'created_at': '2026-10-19T10:00:00Z',
          'reactions': ['❤️', '✨'],
        },
        'partner_answer': {
          'id': 'ans-2',
          'answer_text': 'Vulnerability and trust.',
          'created_at': '2026-10-19T10:05:00Z',
          'reactions': ['☕'],
        },
      };

      final quest = ConversationQuestModel.fromJson(json);
      expect(quest.id, 'quest-42');
      expect(quest.category, 'values');
      expect(quest.promptText, 'What value do you cherish most?');
      expect(quest.followUpPrompt, 'When was this value tested recently?');
      expect(quest.hasUserAnswered, true);
      expect(quest.hasPartnerAnswered, true);
      expect(quest.isUnlocked, true);
      expect(quest.myAnswer?.answerText, 'Honesty, even when uncomfortable.');
      expect(quest.partnerAnswer?.answerText, 'Vulnerability and trust.');
      expect(quest.myAnswer?.reactions.length, 2);
      expect(quest.partnerAnswer?.reactions.first, '☕');
    });

    test('Hides partner answer when mutual unlock is not yet achieved', () {
      final json = {
        'id': 'quest-43',
        'category': 'lifestyle',
        'prompt_text': 'How do you unwind after a long week?',
        'has_user_answered': false,
        'has_partner_answered': true,
        'is_unlocked': false,
        'partner_answer': null,
      };

      final quest = ConversationQuestModel.fromJson(json);
      expect(quest.hasUserAnswered, false);
      expect(quest.hasPartnerAnswered, true);
      expect(quest.isUnlocked, false);
      expect(quest.partnerAnswer, isNull);
    });
  });

  group('GradualRevealModel Unit Tests', () {
    test('Validates stage progression and pending requests', () {
      final json = {
        'connection_id': 'conn-1',
        'current_stage': 'mind',
        'my_consent': {'voice': true, 'connection': false, 'face': false},
        'partner_consent': {'voice': false, 'connection': false, 'face': false},
        'pending_requests_from_partner': [],
        'pending_requests_from_me': ['voice'],
        'is_voice_unlocked': false,
        'is_photo_unlocked': false,
        'explanation': 'Voice reveal requires mutual consent.',
      };

      final reveal = GradualRevealModel.fromJson(json);
      expect(reveal.connectionId, 'conn-1');
      expect(reveal.currentStage, 'mind');
      expect(reveal.myConsent['voice'], true);
      expect(reveal.partnerConsent['voice'], false);
      expect(reveal.isVoiceUnlocked, false);
      expect(reveal.isPhotoUnlocked, false);
      expect(reveal.pendingRequestsFromMe, contains('voice'));
    });

    test('Validates full mutual face reveal stage', () {
      final json = {
        'connection_id': 'conn-1',
        'current_stage': 'face',
        'my_consent': {'voice': true, 'connection': true, 'face': true},
        'partner_consent': {'voice': true, 'connection': true, 'face': true},
        'pending_requests_from_partner': [],
        'pending_requests_from_me': [],
        'is_voice_unlocked': true,
        'is_photo_unlocked': true,
        'explanation': 'Full mutual identity reveal active.',
      };

      final reveal = GradualRevealModel.fromJson(json);
      expect(reveal.currentStage, 'face');
      expect(reveal.isVoiceUnlocked, true);
      expect(reveal.isPhotoUnlocked, true);
    });
  });

  group('ConnectionGardenModel Unit Tests', () {
    test('Calculates growth stage and milestones correctly', () {
      final json = {
        'connection_id': 'conn-1',
        'stage': 'sprout',
        'growth_points': 75,
        'stage_description': 'Roots have taken hold; shared thoughts are sprouting.',
        'is_paused': false,
        'milestones': [
          {
            'milestone_type': 'first_quest',
            'title': 'First Quest Completed',
            'description': 'Both answered your first conversation quest.',
            'achieved_at': '2026-10-19T12:00:00Z',
          },
        ],
        'anti_streak_guarantee': 'Connection Gardens reflect mutual milestones, not compulsive daily streaks.',
        'next_milestone_suggestion': 'Share a voice intro to water your garden.',
      };

      final garden = ConnectionGardenModel.fromJson(json);
      expect(garden.connectionId, 'conn-1');
      expect(garden.stage, 'sprout');
      expect(garden.growthPoints, 75);
      expect(garden.isPaused, false);
      expect(garden.milestones.length, 1);
      expect(garden.milestones.first.title, 'First Quest Completed');
      expect(garden.milestones.first.milestoneType, 'first_quest');
      expect(garden.antiStreakGuarantee, contains('compulsive daily streaks'));
    });
  });
}
