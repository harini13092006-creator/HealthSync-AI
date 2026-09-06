import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthState { initial, authenticated, unauthenticated, loading, error }

class AuthProvider with ChangeNotifier {
  AuthState _state = AuthState.initial;
  String? _errorMessage;
  String _userName = '';
  String _userEmail = '';
  bool _isOnboarded = false;

  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  String get userName => _userName;
  String get userEmail => _userEmail;
  bool get isOnboarded => _isOnboarded;
  bool get isAuthenticated => _state == AuthState.authenticated;
  Map<String, dynamic>? get user => {
    'name': _userName,
    'first_name': _userName,
    'username': _userName,
    'email': _userEmail,
  };

  Future<void> checkAuthStatus() async {
    _state = AuthState.loading;
    notifyListeners();

    final hasToken = await AuthService.isAuthenticated();
    if (hasToken) {
      final user = await StorageService.getUser();
      _userName = user['name'] ?? 'User';
      _userEmail = user['email'] ?? '';
      _isOnboarded = await StorageService.isOnboarded();
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await AuthService.login(email: email, password: password);
      final user = res['user'];
      _userName = user?['name'] ?? '';
      _userEmail = user?['email'] ?? email;
      _isOnboarded = await StorageService.isOnboarded();
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await AuthService.register(name: name, email: email, password: password);
      final user = res['user'];
      _userName = user?['name'] ?? name;
      _userEmail = user?['email'] ?? email;
      _isOnboarded = false;
      await StorageService.setOnboarded(false);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> setOnboardingComplete() async {
    _isOnboarded = true;
    await StorageService.setOnboarded(true);
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.logout();
    _userName = '';
    _userEmail = '';
    _isOnboarded = false;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}
