import 'message_model.dart';

class ConversationState {
  final String conversationId;
  final List<MessageModel> messages;
  final int stage;
  final String? aiSuggestion;
  final bool isTyping;

  const ConversationState({
    required this.conversationId,
    required this.messages,
    required this.stage,
    this.aiSuggestion,
    required this.isTyping,
  });

  ConversationState copyWith({
    List<MessageModel>? messages,
    int? stage,
    String? aiSuggestion,
    bool? isTyping,
  }) {
    return ConversationState(
      conversationId: conversationId,
      messages: messages ?? this.messages,
      stage: stage ?? this.stage,
      aiSuggestion: aiSuggestion ?? this.aiSuggestion,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}
