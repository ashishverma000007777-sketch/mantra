// lib/features/chat/data/models/conversation_quest_model.dart

class QuestAnswerItem {
  final String id;
  final String answerText;
  final String createdAt;
  final List<String> reactions;

  const QuestAnswerItem({
    required this.id,
    required this.answerText,
    required this.createdAt,
    this.reactions = const [],
  });

  factory QuestAnswerItem.fromJson(Map<String, dynamic> json) {
    List<String> reactionEmojis = [];
    final rawReactions = json['reactions'];
    if (rawReactions is List) {
      for (var r in rawReactions) {
        if (r is Map && r['reaction'] != null) {
          reactionEmojis.add(r['reaction'].toString());
        } else if (r is String) {
          reactionEmojis.add(r);
        }
      }
    }

    return QuestAnswerItem(
      id: json['id'] ?? '',
      answerText: json['answer_text'] ?? '',
      createdAt: json['created_at'] ?? '',
      reactions: reactionEmojis,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'answer_text': answerText,
        'created_at': createdAt,
        'reactions': reactions,
      };
}

class ConversationQuestModel {
  final String id;
  final String category;
  final String promptText;
  final String? followUpPrompt;
  final bool hasUserAnswered;
  final bool hasPartnerAnswered;
  final bool isUnlocked;
  final QuestAnswerItem? myAnswer;
  final QuestAnswerItem? partnerAnswer;

  const ConversationQuestModel({
    required this.id,
    required this.category,
    required this.promptText,
    this.followUpPrompt,
    required this.hasUserAnswered,
    required this.hasPartnerAnswered,
    required this.isUnlocked,
    this.myAnswer,
    this.partnerAnswer,
  });

  factory ConversationQuestModel.fromJson(Map<String, dynamic> json) {
    final questObj = json['quest'] is Map<String, dynamic> ? json['quest'] as Map<String, dynamic> : json;

    return ConversationQuestModel(
      id: questObj['id'] ?? '',
      category: questObj['category'] ?? 'values',
      promptText: questObj['prompt_text'] ?? '',
      followUpPrompt: json['follow_up_prompt'] ?? questObj['follow_up_prompt'],
      hasUserAnswered: json['has_user_answered'] ?? false,
      hasPartnerAnswered: json['has_partner_answered'] ?? false,
      isUnlocked: json['is_unlocked'] ?? false,
      myAnswer: json['my_answer'] != null ? QuestAnswerItem.fromJson(json['my_answer']) : null,
      partnerAnswer: json['partner_answer'] != null ? QuestAnswerItem.fromJson(json['partner_answer']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'prompt_text': promptText,
        'follow_up_prompt': followUpPrompt,
        'has_user_answered': hasUserAnswered,
        'has_partner_answered': hasPartnerAnswered,
        'is_unlocked': isUnlocked,
        'my_answer': myAnswer?.toJson(),
        'partner_answer': partnerAnswer?.toJson(),
      };
}
