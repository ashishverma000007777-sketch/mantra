import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/preview/dev_preview.dart';
import '../data/models/message_model.dart';
import '../data/models/conversation_state.dart';
import '../../auth/providers/auth_provider.dart';

final chatProvider = AsyncNotifierProviderFamily<ChatNotifier,
    ConversationState?, String>(
  ChatNotifier.new,
);

class ChatNotifier
    extends FamilyAsyncNotifier<ConversationState?, String> {
  late String _conversationId;
  final _firestore = FirebaseFirestore.instance;

  @override
  Future<ConversationState?> build(String arg) async {
    _conversationId = arg;
    final isPreview = !kReleaseMode && ref.watch(devPreviewProvider);
    if (isPreview) {
      return ConversationState(
        conversationId: _conversationId,
        messages: DevMockData.mockMessages,
        stage: 2,
        aiSuggestion: 'How about we answer today\'s Conversation Quest together?',
        isTyping: false,
      );
    }
    _listenToMessages();
    return _fetchInitialState();
  }

  Future<ConversationState?> _fetchInitialState() async {
    try {
      final convDoc = await _firestore
          .collection('conversations')
          .doc(_conversationId)
          .get();

      if (!convDoc.exists) return null;

      final data = convDoc.data()!;
      final messagesSnap = await _firestore
          .collection('messages')
          .where('conversation_id', isEqualTo: _conversationId)
          .orderBy('created_at', descending: false)
          .limit(50)
          .get();

      final messages = messagesSnap.docs
          .map((d) => MessageModel.fromJson(d.data(), _myUserId()))
          .toList();

      return ConversationState(
        conversationId: _conversationId,
        messages: messages,
        stage: data['stage'] ?? 1,
        aiSuggestion: data['ai_suggestion'],
        isTyping: false,
      );
    } catch (e) {
      return null;
    }
  }

  void _listenToMessages() {
    _firestore
        .collection('messages')
        .where('conversation_id', isEqualTo: _conversationId)
        .orderBy('created_at', descending: false)
        .snapshots()
        .listen((snap) {
      final current = state.value;
      if (current == null) return;

      final messages = snap.docs
          .map((d) => MessageModel.fromJson(d.data(), _myUserId()))
          .toList();

      state = AsyncData(current.copyWith(messages: messages));
    });

    // Typing indicator
    _firestore
        .collection('typing')
        .doc(_conversationId)
        .snapshots()
        .listen((snap) {
      final current = state.value;
      if (current == null) return;
      final data = snap.data();
      final isTyping = data != null &&
          data.keys.any((k) => k != _myUserId() && (data[k] == true));
      state = AsyncData(current.copyWith(isTyping: isTyping));
    });
  }

  Future<void> sendText(String content) async {
    final isPreview = !kReleaseMode && ref.read(devPreviewProvider);
    if (isPreview) {
      final current = state.value;
      if (current != null) {
        final newMsg = MessageModel(
          id: 'dev-msg-${DateTime.now().millisecondsSinceEpoch}',
          conversationId: _conversationId,
          senderId: _myUserId(),
          type: MessageType.text,
          content: content,
          isMine: true,
          isRead: false,
          isDelivered: true,
          createdAt: DateTime.now(),
        );
        state = AsyncData(current.copyWith(
          messages: [...current.messages, newMsg],
        ));
      }
      return;
    }

    final msg = {
      'conversation_id': _conversationId,
      'sender_id': _myUserId(),
      'type': 'text',
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
      'is_deleted': false,
    };
    await _firestore.collection('messages').add(msg);
    await _firestore
        .collection('conversations')
        .doc(_conversationId)
        .update({'last_message_at': FieldValue.serverTimestamp()});
  }

  Future<void> sendVoice(String localPath) async {
    final isPreview = !kReleaseMode && ref.read(devPreviewProvider);
    if (isPreview) {
      final current = state.value;
      if (current != null) {
        final newMsg = MessageModel(
          id: 'dev-msg-${DateTime.now().millisecondsSinceEpoch}',
          conversationId: _conversationId,
          senderId: _myUserId(),
          type: MessageType.voice,
          content: localPath,
          voiceDuration: 18,
          isMine: true,
          isRead: false,
          isDelivered: true,
          createdAt: DateTime.now(),
        );
        state = AsyncData(current.copyWith(
          messages: [...current.messages, newMsg],
        ));
      }
      return;
    }

    // Upload to Firebase Storage then create message
    // Simplified here — in production, upload then create doc
    final msg = {
      'conversation_id': _conversationId,
      'sender_id': _myUserId(),
      'type': 'voice',
      'content': localPath, // replace with Storage URL after upload
      'created_at': DateTime.now().toIso8601String(),
      'voice_duration': 30,
      'is_deleted': false,
    };
    await _firestore.collection('messages').add(msg);
  }

  Future<void> setTyping(bool isTyping) async {
    final isPreview = !kReleaseMode && ref.read(devPreviewProvider);
    if (isPreview) return;

    await _firestore.collection('typing').doc(_conversationId).set({
      _myUserId(): isTyping,
    }, SetOptions(merge: true));
  }

  String _myUserId() {
    return ref.read(authStateProvider).value?.id ?? 'anonymous';
  }
}
