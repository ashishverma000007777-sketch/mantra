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

  factory MessageModel.fromJson(Map<String, dynamic> json, String myUserId) {
    final sender = (json['sender_id'] ?? json['senderId'] ?? '').toString();
    return MessageModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      conversationId: (json['conversation_id'] ?? json['conversationId'] ?? '').toString(),
      senderId: sender,
      type: MessageType.values.firstWhere(
        (t) => t.name == (json['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      content: (json['content'] ?? '').toString(),
      isMine: sender == myUserId,
      isRead: json['read_at'] != null || json['is_read'] == true,
      isDelivered: json['delivered_at'] != null,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      voiceDuration: json['voice_duration'] as int?,
    );
  }
}
