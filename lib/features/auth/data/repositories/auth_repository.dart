import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

import '../models/user_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

abstract class AuthRepository {
  Future<String?> sendOtp(String phoneNumber);
  Future<bool> verifyOtp(String verificationId, String otp);
  Future<UserModel?> getCurrentUser();
  Future<void> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FlutterSecureStorage _secureStorage;

  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required FlutterSecureStorage secureStorage,
  })  : _firebaseAuth = firebaseAuth,
        _secureStorage = secureStorage;

  String? _verificationId;

  @override
  Future<String?> sendOtp(String phoneNumber) async {
    final completer = Completer<String?>();

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: '+91$phoneNumber',
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _firebaseAuth.signInWithCredential(credential);
        if (!completer.isCompleted) {
          completer.complete('AUTO_VERIFIED');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(Exception(e.message ?? 'Phone verification failed'));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      timeout: const Duration(seconds: 60),
    );

    return completer.future;
  }

  @override
  Future<bool> verifyOtp(String verificationId, String otp) async {
    // 1. Verify OTP with Firebase Authentication (isolated step)
    UserCredential? credentialResult;
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      credentialResult = await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-verification-code':
          throw Exception('The OTP code entered is incorrect. Please verify and try again.');
        case 'session-expired':
          throw Exception('The OTP session has expired. Please request a new code.');
        case 'invalid-verification-id':
          throw Exception('Verification session is invalid. Please request a new code.');
        default:
          throw Exception(e.message ?? 'OTP verification failed. Please try again.');
      }
    } catch (e) {
      throw Exception('OTP verification failed: ${e.toString().replaceAll("Exception: ", "")}');
    }

    final user = credentialResult.user ?? _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('Authentication failed: No user returned from provider.');
    }

    // Persist verified Firebase token
    final idToken = await user.getIdToken();
    if (idToken != null) {
      await _secureStorage.write(key: 'firebase_token', value: idToken);
    }

    // 2. Synchronize / register with backend API (separate step)
    try {
      await _registerWithBackend(idToken ?? '');
      return true;
    } on DioException catch (dioErr) {
      throw Exception(formatNetworkError(dioErr));
    } catch (e) {
      throw Exception('Backend synchronization failed: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  static String formatNetworkError(DioException dioErr) {
    final host = Uri.tryParse(ApiConstants.baseUrl)?.host ?? ApiConstants.baseUrl;
    final isDnsOrConnection = dioErr.type == DioExceptionType.connectionError ||
        dioErr.error is SocketException ||
        dioErr.message?.contains('Failed host lookup') == true ||
        dioErr.message?.contains('No address associated with hostname') == true;

    if (isDnsOrConnection) {
      return 'Network connection error: Unable to resolve or reach backend host ($host). '
          'The backend server is currently unreachable or not deployed.';
    } else if (dioErr.type == DioExceptionType.connectionTimeout ||
        dioErr.type == DioExceptionType.receiveTimeout) {
      return 'Network timeout: Connection to backend host ($host) timed out. '
          'Please check your internet connection.';
    } else if (dioErr.response != null) {
      final statusCode = dioErr.response?.statusCode;
      final errorMsg = dioErr.response?.data is Map
          ? (dioErr.response?.data['error'] ?? dioErr.response?.data['message'] ?? 'HTTP $statusCode')
          : 'HTTP $statusCode';
      return 'Backend service error ($statusCode): $errorMsg';
    } else {
      return 'Backend request failed: ${dioErr.message}';
    }
  }

  Future<void> _registerWithBackend(String firebaseToken) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    final response = await dio.post(
      '/auth/register',
      options: Options(
        headers: {'Authorization': 'Bearer $firebaseToken'},
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      if (data is Map && data['data'] != null) {
        final accessJwt = data['data']['access_token'];
        if (accessJwt != null) {
          await _secureStorage.write(key: 'jwt_token', value: accessJwt.toString());
        }
        final refreshJwt = data['data']['refresh_token'];
        if (refreshJwt != null) {
          await _secureStorage.write(key: 'refresh_token', value: refreshJwt.toString());
        }
      }
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final jwt = await _secureStorage.read(key: 'jwt_token');
      if (jwt == null) return null;

      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
          receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      final response = await dio.get(
        '/auth/me',
        options: Options(
          headers: {'Authorization': 'Bearer $jwt'},
        ),
      );
      if (response.data is Map && response.data['data'] != null) {
        return UserModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _secureStorage.deleteAll();
  }
}
