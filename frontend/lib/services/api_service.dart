import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;
}

class ApiService {
  static final http.Client _client = http.Client();

  static Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth) {
      final token = await StorageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<dynamic> get(String url, {bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.get(Uri.parse(url), headers: headers).timeout(
        const Duration(seconds: 15),
      );
      return _handleResponse(response);
    });
  }

  static Future<dynamic> post(String url, {dynamic body, bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    });
  }

  static Future<dynamic> put(String url, {dynamic body, bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.put(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    });
  }

  static Future<dynamic> delete(String url, {bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.delete(Uri.parse(url), headers: headers).timeout(
        const Duration(seconds: 15),
      );
      return _handleResponse(response);
    });
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      body = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    if (response.statusCode == 401) {
      throw ApiException(
        body is Map && body.containsKey('detail') ? body['detail'] : 'Session expired. Please log in again.',
        statusCode: 401,
      );
    } else if (response.statusCode == 403) {
      throw ApiException('Access forbidden. You do not have permission.', statusCode: 403);
    } else if (response.statusCode == 404) {
      throw ApiException('Requested resource was not found.', statusCode: 404);
    } else if (response.statusCode == 400 || response.statusCode == 422) {
      String msg = 'Invalid request data.';
      if (body is Map) {
        final errors = body.entries.map((e) => "${e.key}: ${e.value}").join("\n");
        if (errors.isNotEmpty) msg = errors;
      }
      throw ApiException(msg, statusCode: response.statusCode, details: body);
    } else if (response.statusCode >= 500) {
      throw ApiException('Server error occurred. Please try again shortly.', statusCode: 500);
    } else {
      throw ApiException('Unexpected network error (${response.statusCode})', statusCode: response.statusCode);
    }
  }

  static Future<dynamic> _sendWithRetry(Future<dynamic> Function() action) async {
    try {
      return await action();
    } on SocketException {
      throw ApiException('Unable to reach HealthSync server. Check your connection or API base URL in Settings.');
    } on http.ClientException {
      throw ApiException('Connection failed. Verify the backend server is running.');
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Attempt refresh
        final refreshed = await _refreshToken();
        if (refreshed) {
          try {
            return await action();
          } catch (_) {
            rethrow;
          }
        }
      }
      rethrow;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  static Future<bool> _refreshToken() async {
    final refresh = await StorageService.getRefreshToken();
    if (refresh == null) return false;

    try {
      final res = await _client.post(
        Uri.parse(ApiConstants.tokenRefresh),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final newAccess = data['access'];
        await StorageService.saveTokens(access: newAccess, refresh: refresh);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
