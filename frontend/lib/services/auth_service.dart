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
      throw _friendlyError(error);
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await _finishSignIn(user);
      return _userResponse(user);
    } on FirebaseAuthException catch (error) {
      throw _friendlyError(error);
    }
  }

  static Future<void> _finishSignIn(
    User user, {
    String fallbackName = '',
  }) async {
    await StorageService.clearLegacyTokens();
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
        return 'No Firebase account exists for this email. Create an account to get started.';
      case 'email-already-in-use':
        return 'An account already exists for this email. Try logging in.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Wait a few minutes and try again.';
      case 'network-request-failed':
        return 'Could not connect to Firebase. Check your internet connection.';
      case 'operation-not-allowed':
        return 'Email and password sign-in is not enabled in the Firebase project yet.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  static void _syncBackendUser() {
    // The Django API verifies the Firebase ID token and links the account to
    // existing wellness records by email. Authentication itself stays usable
    // even when the API is waking up or temporarily unavailable.
    unawaited(_ensureBackendUser());
  }

  static Future<void> _ensureBackendUser() async {
    try {
      await ApiService.get(ApiConstants.me);
    } catch (_) {
      // Sign-in is managed by Firebase; backend availability must not block it.
    }
  }

  static Future<void> logout() async {
    await _firebaseAuth.signOut();
    await StorageService.clearAll();
  }

  static Future<bool> isAuthenticated() async => currentUser != null;
}
