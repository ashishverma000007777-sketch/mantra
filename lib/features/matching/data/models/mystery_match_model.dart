// lib/features/matching/data/models/mystery_match_model.dart

class MysteryPromptResponse {
  final String question;
  final String answer;

  const MysteryPromptResponse({required this.question, required this.answer});

  factory MysteryPromptResponse.fromJson(Map<String, dynamic> json) => MysteryPromptResponse(
        question: json['question'] ?? '',
        answer: json['answer'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
      };
}

class MysteryMatchModel {
  final String candidateId;
  final String pseudonym;
  final int age;
  final String city;
  final String intent;
  final List<String> personalityTags;
  final List<String> sharedInterests;
  final List<MysteryPromptResponse> promptResponses;
  final double trustScore;
  final bool hasVoiceIntro;
  final bool photosHidden;

  const MysteryMatchModel({
    required this.candidateId,
    required this.pseudonym,
    required this.age,
    required this.city,
    required this.intent,
    required this.personalityTags,
    required this.sharedInterests,
    required this.promptResponses,
    required this.trustScore,
    required this.hasVoiceIntro,
    this.photosHidden = true,
  });

  factory MysteryMatchModel.fromJson(Map<String, dynamic> json) {
    var rawPrompts = json['prompt_responses'];
    List<MysteryPromptResponse> prompts = [];
    if (rawPrompts is List) {
      prompts = rawPrompts
          .map((p) => p is Map<String, dynamic>
              ? MysteryPromptResponse.fromJson(p)
              : const MysteryPromptResponse(question: '', answer: ''))
          .where((p) => p.answer.isNotEmpty)
          .toList();
    }

    return MysteryMatchModel(
      candidateId: json['candidate_id'] ?? '',
      pseudonym: json['pseudonym'] ?? 'Thoughtful Soul',
      age: (json['age'] as num?)?.toInt() ?? 25,
      city: json['city'] ?? 'Nearby',
      intent: json['intent'] ?? 'Mindful slow dating',
      personalityTags: List<String>.from(json['personality_tags'] ?? []),
      sharedInterests: List<String>.from(json['shared_interests'] ?? []),
      promptResponses: prompts,
      trustScore: (json['trust_score'] as num?)?.toDouble() ?? 50.0,
      hasVoiceIntro: json['has_voice_intro'] ?? false,
      photosHidden: json['photos_hidden'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'candidate_id': candidateId,
        'pseudonym': pseudonym,
        'age': age,
        'city': city,
        'intent': intent,
        'personality_tags': personalityTags,
        'shared_interests': sharedInterests,
        'prompt_responses': promptResponses.map((p) => p.toJson()).toList(),
        'trust_score': trustScore,
        'has_voice_intro': hasVoiceIntro,
        'photos_hidden': photosHidden,
      };
}
