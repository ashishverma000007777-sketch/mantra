// lib/features/chat/data/models/message_model.dart

enum MessageType { text, voice, gif, system }

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final MessageType type;
  final String content;
  final bool isMine;
  final bool isRead;
  final bool isDelivered;
  final DateTime createdAt;
  final int? voiceDuration;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.isMine,
    required this.isRead,
    required this.isDelivered,
    required this.createdAt,
    this.voiceDuration,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String myUserId) =>
      MessageModel(
        id: json['_id'] ?? json['id'],
        conversationId: json['conversation_id'],
        senderId: json['sender_id'],
        type: MessageType.values.firstWhere(
          (t) => t.name == (json['type'] ?? 'text'),
          orElse: () => MessageType.text,
        ),
        content: json['content'] ?? '',
        isMine: json['sender_id'] == myUserId,
        isRead: json['read_at'] != null,
        isDelivered: json['delivered_at'] != null,
        createdAt: DateTime.parse(json['created_at']),
        voiceDuration: json['voice_duration'],
      );
}
