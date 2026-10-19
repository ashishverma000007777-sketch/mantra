// lib/core/constants/api_constants.dart

class ApiConstants {
  ApiConstants._();

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.mantraapp.in/api/v1',
  );
  static const String _envWsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://ws.mantraapp.in',
  );

  static String _customBaseUrl = _envBaseUrl;
  static String _customWsUrl = _envWsUrl;

  static String get baseUrl => _customBaseUrl;
  static String get wsUrl => _customWsUrl;

  static void setBaseUrl(String url) {
    _customBaseUrl = url;
  }

  static void setWsUrl(String url) {
    _customWsUrl = url;
  }

  static void reset() {
    _customBaseUrl = _envBaseUrl;
    _customWsUrl = _envWsUrl;
  }

  // Auth
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';

  // Profile
  static const String profile = '/profile';
  static const String updateProfile = '/profile/update';
  static const String uploadVoice = '/profile/voice';
  static const String uploadPhoto = '/profile/photo';

  // Matching
  static const String dailySparks = '/match/sparks';
  static const String connect = '/match/connect';
  static const String pass = '/match/pass';
  static const String save = '/match/save';

  // Chat
  static const String conversations = '/conversations';
  static const String messages = '/messages';

  // Community
  static const String rooms = '/rooms';
  static const String joinRoom = '/rooms/join';
  static const String roomPosts = '/rooms/posts';

  // Safety
  static const String reportUser = '/safety/report';
  static const String blockUser = '/safety/block';
  static const String trustedContacts = '/safety/trusted-contacts';
  static const String sosAlert = '/safety/sos';

  // Premium
  static const String createOrder = '/payment/order';
  static const String verifyPayment = '/payment/verify';

  // Signature Features
  // 1. Mystery Match
  static const String mysteryMatch = '/match/mystery';
  static const String mysteryExplore = '/match/mystery/explore';
  static const String mysteryPass = '/match/mystery/pass';

  // 2. Compatibility DNA
  static const String compatibilityProfile = '/compatibility';
  static const String compatibilityAnswers = '/compatibility/answers';
  static const String compatibilityCompare = '/compatibility/compare';

  // 3. Conversation Quest
  static const String questDaily = '/quests/daily';
  static const String questConnection = '/quests/connection';
  static const String questAnswer = '/quests/answer';
  static const String questReact = '/quests/react';

  // 4. Gradual Identity Reveal
  static const String reveal = '/reveal';

  // 5. Connection Garden
  static const String garden = '/garden';

  // Timeouts
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 30000;
}
