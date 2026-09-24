import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/api_constants.dart';

class StorageService {
  static const String _accessTokenKey = 'healthsync_access_token';
  static const String _refreshTokenKey = 'healthsync_refresh_token';
  static const String _userEmailKey = 'healthsync_user_email';
  static const String _userNameKey = 'healthsync_user_name';
  static const String _onboardedKey = 'healthsync_is_onboarded';
  static const String _customBaseUrlKey = 'healthsync_base_url';

  static Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, access);
    await prefs.setString(_refreshTokenKey, refresh);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<void> saveUser({
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userEmailKey, email);
  }

  static Future<Map<String, String?>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_userNameKey),
      'email': prefs.getString(_userEmailKey),
    };
  }

  static Future<void> setOnboarded(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, value);
  }

  static Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardedKey) ?? false;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_onboardedKey);
  }

  static Future<void> clearLegacyTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  static Future<void> loadCustomBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();

    // Production APKs and web builds always use the deployed backend. This
    // prevents a saved localhost/LAN address from breaking the app off the
    // development network.
    if (kReleaseMode) {
      await prefs.remove(_customBaseUrlKey);
      ApiConstants.updateBaseUrl('https://healthsync-ai-2.onrender.com');
      return;
    }

    final url = prefs.getString(_customBaseUrlKey);
    if (url != null && url.isNotEmpty) {
      final host = Uri.tryParse(url)?.host.toLowerCase();
      final isLoopback =
          host == 'localhost' ||
          host == '127.0.0.1' ||
          host == '10.0.2.2' ||
          host == '::1';

      // These addresses only work on the development computer/emulator. A
      // previously saved value would make login fail on a physical phone.
      if (isLoopback) {
        await prefs.remove(_customBaseUrlKey);
        return;
      }

      ApiConstants.updateBaseUrl(url);
    }
  }

  static Future<void> saveCustomBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customBaseUrlKey, url);
    ApiConstants.updateBaseUrl(url);
  }
}
