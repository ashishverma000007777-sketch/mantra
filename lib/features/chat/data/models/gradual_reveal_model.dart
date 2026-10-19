// lib/features/chat/data/models/gradual_reveal_model.dart

class GradualRevealModel {
  final String connectionId;
  final String currentStage;
  final Map<String, bool> myConsent;
  final Map<String, bool> partnerConsent;
  final List<String> pendingRequestsFromPartner;
  final List<String> pendingRequestsFromMe;
  final bool isVoiceUnlocked;
  final bool isPhotoUnlocked;
  final String explanation;

  const GradualRevealModel({
    required this.connectionId,
    required this.currentStage,
    required this.myConsent,
    required this.partnerConsent,
    required this.pendingRequestsFromPartner,
    required this.pendingRequestsFromMe,
    required this.isVoiceUnlocked,
    required this.isPhotoUnlocked,
    required this.explanation,
  });

  factory GradualRevealModel.fromJson(Map<String, dynamic> json) {
    Map<String, bool> parseConsent(dynamic raw) {
      if (raw is Map) {
        return {
          'voice': raw['voice'] == true,
          'connection': raw['connection'] == true,
          'face': raw['face'] == true,
        };
      }
      return {'voice': false, 'connection': false, 'face': false};
    }

    return GradualRevealModel(
      connectionId: json['connection_id'] ?? '',
      currentStage: json['current_stage'] ?? 'mind',
      myConsent: parseConsent(json['my_consent']),
      partnerConsent: parseConsent(json['partner_consent']),
      pendingRequestsFromPartner: List<String>.from(json['pending_requests_from_partner'] ?? []),
      pendingRequestsFromMe: List<String>.from(json['pending_requests_from_me'] ?? []),
      isVoiceUnlocked: json['is_voice_unlocked'] ?? false,
      isPhotoUnlocked: json['is_photo_unlocked'] ?? false,
      explanation: json['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'connection_id': connectionId,
        'current_stage': currentStage,
        'my_consent': myConsent,
        'partner_consent': partnerConsent,
        'pending_requests_from_partner': pendingRequestsFromPartner,
        'pending_requests_from_me': pendingRequestsFromMe,
        'is_voice_unlocked': isVoiceUnlocked,
        'is_photo_unlocked': isPhotoUnlocked,
        'explanation': explanation,
      };
}
