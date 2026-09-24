import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

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
  // The hosted service may take several seconds to wake after a period of
  // inactivity. Give the first login request enough time to complete.
  static const Duration _requestTimeout = Duration(seconds: 60);

  static Future<Map<String, String>> _getHeaders({
    bool requiresAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth) {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<dynamic> get(String url, {bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(_requestTimeout);
      return _handleResponse('GET', url, response);
    });
  }

  static Future<dynamic> post(
    String url, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    return _sendWithRetry(() async {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client
          .post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_requestTimeout);
      return _handleResponse('POST', url, response);
    });
  }

  static Future<dynamic> put(
    String url, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    return _sendWithRetry(() async {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client
          .put(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_requestTimeout);
      return _handleResponse('PUT', url, response);
    });
  }

  static Future<dynamic> delete(String url, {bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client
          .delete(Uri.parse(url), headers: headers)
          .timeout(_requestTimeout);
      return _handleResponse('DELETE', url, response);
    });
  }

  static dynamic _handleResponse(
    String method,
    String url,
    http.Response response,
  ) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      body = response.body;
    }
    _debugLog('$method $url -> ${response.statusCode}', body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    if (response.statusCode == 401) {
      throw ApiException(
        body is Map && body.containsKey('detail')
            ? body['detail']
            : 'Session expired. Please log in again.',
        statusCode: 401,
      );
    } else if (response.statusCode == 403) {
      throw ApiException(
        'Access forbidden. You do not have permission.',
        statusCode: 403,
      );
    } else if (response.statusCode == 404) {
      throw ApiException('Requested resource was not found.', statusCode: 404);
    } else if (response.statusCode == 400 || response.statusCode == 422) {
      String msg = 'Invalid request data.';
      if (body is Map) {
        final errors = body.entries
            .map((e) => "${e.key}: ${e.value}")
            .join("\n");
        if (errors.isNotEmpty) msg = errors;
      }
      throw ApiException(msg, statusCode: response.statusCode, details: body);
    } else if (response.statusCode >= 500) {
      throw ApiException(
        'Server error occurred. Please try again shortly.',
        statusCode: 500,
      );
    } else {
      throw ApiException(
        'Unexpected network error (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
  }

  static Future<dynamic> _sendWithRetry(
    Future<dynamic> Function() action,
  ) async {
    try {
      return await action();
    } on SocketException {
      throw ApiException(
        'Unable to reach HealthSync server. Check your connection or API base URL in Settings.',
      );
    } on TimeoutException {
      throw ApiException(
        'The HealthSync server took too long to respond. Please try again.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  static void _debugLog(String request, dynamic body) {
    if (kReleaseMode) return;
    debugPrint('[HealthSync API] $request');
    if (body != null) {
      debugPrint('[HealthSync API] response: ${_redact(body)}');
    }
  }

  static dynamic _redact(dynamic value) {
    const sensitiveKeys = {'password', 'token', 'access', 'refresh'};
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(
          key,
          sensitiveKeys.contains(key.toString().toLowerCase())
              ? '[REDACTED]'
              : _redact(item),
        ),
      );
    }
    if (value is List) return value.map(_redact).toList();
    return value;
  }
}
