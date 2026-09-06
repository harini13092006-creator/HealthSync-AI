import '../core/constants/api_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post(
      ApiConstants.register,
      body: {
        'name': name,
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );

    if (response is Map<String, dynamic> && response.containsKey('tokens')) {
      final tokens = response['tokens'];
      await StorageService.saveTokens(
        access: tokens['access'],
        refresh: tokens['refresh'],
      );
      if (response.containsKey('user')) {
        final user = response['user'];
        await StorageService.saveUser(
          name: user['name'] ?? name,
          email: user['email'] ?? email,
        );
      }
    }
    return response as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post(
      ApiConstants.login,
      body: {
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );

    if (response is Map<String, dynamic> && response.containsKey('tokens')) {
      final tokens = response['tokens'];
      await StorageService.saveTokens(
        access: tokens['access'],
        refresh: tokens['refresh'],
      );
      if (response.containsKey('user')) {
        final user = response['user'];
        await StorageService.saveUser(
          name: user['name'] ?? '',
          email: user['email'] ?? email,
        );
      }
    }
    return response as Map<String, dynamic>;
  }

  static Future<void> logout() async {
    await StorageService.clearAll();
  }

  static Future<bool> isAuthenticated() async {
    final token = await StorageService.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
