import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/api_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static User? get currentUser => _firebaseAuth.currentUser;

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    ApiException? backendError;

    // 1. Primary: Register directly on Django backend
    try {
      final res = await ApiService.post(
        ApiConstants.register,
        body: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        },
        requiresAuth: false,
      );

      if (res is Map<String, dynamic> && res.containsKey('tokens')) {
        final tokens = res['tokens'] as Map<String, dynamic>;
        await StorageService.saveTokens(
          access: tokens['access']?.toString() ?? '',
          refresh: tokens['refresh']?.toString() ?? '',
        );

        final userData = res['user'] as Map<String, dynamic>?;
        final savedName = userData?['name']?.toString() ?? name.trim();
        final savedEmail = userData?['email']?.toString() ?? email.trim();
        await StorageService.saveUser(name: savedName, email: savedEmail);

        // Attempt Firebase registration in background if available
        unawaited(_tryFirebaseRegister(name, email, password));

        return {
          'user': {
            'name': savedName,
            'email': savedEmail,
          },
        };
      }
    } on ApiException catch (e) {
      backendError = e;
      // If backend returned a definitive validation error (e.g. email exists), rethrow it
      if (e.statusCode != null && e.statusCode! < 500 && e.statusCode != 404) {
        throw e.message;
      }
    } catch (_) {}

    // 2. Fallback: Firebase Auth if backend wasn't reached
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());
      await credential.user?.reload();
      final user = _firebaseAuth.currentUser ?? credential.user!;
      await _finishSignIn(user, fallbackName: name.trim());
      return _userResponse(user, fallbackName: name.trim());
    } on FirebaseAuthException catch (error) {
      throw backendError?.message ?? _friendlyError(error);
    } catch (e) {
      throw backendError?.message ?? 'Registration failed. Check server connection.';
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    ApiException? backendError;

    // 1. Primary: Try Django backend login
    try {
      final res = await ApiService.post(
        ApiConstants.login,
        body: {
          'email': email.trim(),
          'password': password,
        },
        requiresAuth: false,
      );

      if (res is Map<String, dynamic> && res.containsKey('tokens')) {
        final tokens = res['tokens'] as Map<String, dynamic>;
        await StorageService.saveTokens(
          access: tokens['access']?.toString() ?? '',
          refresh: tokens['refresh']?.toString() ?? '',
        );

        final userData = res['user'] as Map<String, dynamic>?;
        final savedName = userData?['name']?.toString() ?? email.split('@').first;
        final savedEmail = userData?['email']?.toString() ?? email.trim();
        await StorageService.saveUser(name: savedName, email: savedEmail);

        // Attempt Firebase login in background
        unawaited(_tryFirebaseLogin(email, password));

        return {
          'user': {
            'name': savedName,
            'email': savedEmail,
          },
        };
      }
    } on ApiException catch (e) {
      backendError = e;
      // If backend specifically returned 401 / bad credentials, check Firebase before throwing
    } catch (_) {}

    // 2. Fallback: Try Firebase Auth
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await _finishSignIn(user);
      return _userResponse(user);
    } on FirebaseAuthException catch (error) {
      if (backendError != null) {
        throw backendError.message;
      }
      throw _friendlyError(error);
    } catch (e) {
      if (backendError != null) {
        throw backendError.message;
      }
      throw 'Login failed. Check server connection.';
    }
  }

  static Future<void> _tryFirebaseRegister(String name, String email, String password) async {
    try {
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(name.trim());
    } catch (_) {}
  }

  static Future<void> _tryFirebaseLogin(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (_) {}
  }

  static Future<void> _finishSignIn(
    User user, {
    String fallbackName = '',
  }) async {
    await StorageService.saveUser(
      name: user.displayName ?? fallbackName,
      email: user.email ?? '',
    );
    _syncBackendUser();
  }

  static Map<String, dynamic> _userResponse(
    User user, {
    String fallbackName = '',
  }) => {
    'user': {
      'name': user.displayName ?? fallbackName,
      'email': user.email ?? '',
      'firebase_uid': user.uid,
    },
  };

  static String _friendlyError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'user-not-found':
        return 'No account exists for this email. Create an account to get started.';
      case 'email-already-in-use':
        return 'An account already exists for this email. Try logging in.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Wait a few minutes and try again.';
      case 'network-request-failed':
        return 'Could not connect. Check your internet connection or server URL in Settings.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled. Using local backend instead.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  static void _syncBackendUser() {
    unawaited(_ensureBackendUser());
  }

  static Future<void> _ensureBackendUser() async {
    try {
      await ApiService.get(ApiConstants.me);
    } catch (_) {}
  }

  static Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    await StorageService.clearAll();
  }

  static Future<bool> isAuthenticated() async {
    if (_firebaseAuth.currentUser != null) return true;
    final token = await StorageService.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
