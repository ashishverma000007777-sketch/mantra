import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/preview/dev_preview.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

// Firebase Auth stream
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Current Firebase user stream
final firebaseUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Our app user model (from backend)
final authStateProvider = StreamProvider<UserModel?>((ref) async* {
  final isPreview = ref.watch(devPreviewProvider);
  if (!kReleaseMode && isPreview) {
    yield DevMockData.previewUser;
    return;
  }

  final firebaseUser = ref.watch(firebaseUserProvider);

  yield* firebaseUser.when(
    data: (user) async* {
      if (user == null) {
        yield null;
        return;
      }
      final repo = ref.read(authRepositoryProvider);
      yield await repo.getCurrentUser();
    },
    loading: () async* {
      yield null;
    },
    error: (_, __) async* {
      yield null;
    },
  );
});

// Auth actions
final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.read(authRepositoryProvider), ref);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<String?> sendOtp(String phoneNumber) async {
    state = const AsyncValue.loading();
    try {
      final verificationId = await _repository.sendOtp(phoneNumber);
      state = const AsyncValue.data(null);
      return verificationId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> verifyOtp(String verificationId, String otp) async {
    state = const AsyncValue.loading();
    try {
      final success = await _repository.verifyOtp(verificationId, otp);
      state = const AsyncValue.data(null);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> logout() async {
    _ref.read(devPreviewProvider.notifier).exitPreview();
    await _repository.logout();
  }
}

// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    firebaseAuth: ref.read(firebaseAuthProvider),
    secureStorage: const FlutterSecureStorage(),
  );
});
