// test/models_and_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:mantra/features/chat/data/models/message_model.dart';
import 'package:mantra/features/auth/data/models/user_model.dart';
import 'package:mantra/features/community/data/models/room_model.dart';
import 'package:mantra/firebase_options.dart';

void main() {
  group('Firebase Configuration Unit Tests', () {
    test('Android FirebaseOptions match Mantra package and raahi-a3194 project', () {
      final androidOptions = DefaultFirebaseOptions.android;
      expect(androidOptions.projectId, 'raahi-a3194');
      expect(androidOptions.appId, '1:607675067117:android:ec9590f6934cdd493cfae4');
      expect(androidOptions.messagingSenderId, '607675067117');
      expect(androidOptions.apiKey, 'AIzaSyCExXcyh-3IKQnpIskMOZkzfgbiJETJB9g');
      expect(androidOptions.storageBucket, 'raahi-a3194.firebasestorage.app');
    });
  });

  group('MessageModel Unit Tests', () {
    test('Correctly parses canonical sender_id and calculates isMine', () {
      final json = {
        'id': 'msg-12345',
        'conversation_id': 'conv-67890',
        'sender_id': 'user-alice-uid',
        'type': 'text',
        'content': 'Hello from Mantra!',
        'created_at': '2026-10-19T10:00:00.000Z',
        'read_at': '2026-10-19T10:05:00.000Z',
      };

      final msgAlice = MessageModel.fromJson(json, 'user-alice-uid');
      expect(msgAlice.id, 'msg-12345');
      expect(msgAlice.conversationId, 'conv-67890');
      expect(msgAlice.senderId, 'user-alice-uid');
      expect(msgAlice.isMine, true);
      expect(msgAlice.isRead, true);
      expect(msgAlice.content, 'Hello from Mantra!');

      final msgBob = MessageModel.fromJson(json, 'user-bob-uid');
      expect(msgBob.isMine, false);
    });

    test('Falls back gracefully for voice message and optional fields', () {
      final json = {
        'id': 'msg-voice-1',
        'conversation_id': 'conv-1',
        'sender_id': 'user-1',
        'type': 'voice',
        'content': 'https://storage.googleapis.com/voice.m4a',
        'voice_duration': 24,
      };

      final msg = MessageModel.fromJson(json, 'user-1');
      expect(msg.type, MessageType.voice);
      expect(msg.voiceDuration, 24);
      expect(msg.isRead, false);
      expect(msg.isDelivered, false);
    });
  });

  group('UserModel Unit Tests', () {
    test('Parses user JSON and handles nullables', () {
      final json = {
        'id': 'user-test-uuid',
        'phone_hash': 'sha256_mock_hash_value',
        'verification_level': 3,
        'account_status': 'active',
        'gender': 'woman',
        'age': 25,
        'city': 'Bengaluru',
        'is_premium': true,
        'premium_tier': 'platinum',
        'is_onboarded': true,
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 'user-test-uuid');
      expect(user.verificationLevel, 3);
      expect(user.isPremium, true);
      expect(user.premiumTier, 'platinum');
      expect(user.city, 'Bengaluru');
    });
  });

  group('RoomModel Unit Tests', () {
    test('Parses room colors and women_only flag accurately', () {
      final json = {
        'id': 'room-chai-lovers',
        'name': 'Chai & Deep Talks',
        'description': 'Slow conversations over tea',
        'emoji': '☕',
        'color': '#8B5E3C',
        'women_only': true,
        'member_count': 142,
      };

      final room = RoomModel.fromJson(json);
      expect(room.name, 'Chai & Deep Talks');
      expect(room.isWomenOnly, true);
      expect(room.color, const Color(0xFF8B5E3C));
      expect(room.memberCount, 142);
    });
  });
}
