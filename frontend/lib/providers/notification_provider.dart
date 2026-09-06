import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

class NotificationProvider with ChangeNotifier {
  static const _pollingInterval = Duration(seconds: 30);

  bool _isLoading = false;
  bool _isPolling = false;
  String? _error;
  List<dynamic> _notifications = [];
  Timer? _pollingTimer;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => n['is_read'] == false).length;

  Future<void> fetchNotifications() async {
    await _loadNotifications(showLoading: true);
  }

  void startPolling() {
    if (_pollingTimer != null) return;

    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _pollNotifications();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollNotifications() async {
    if (_isPolling || _isLoading) return;
    _isPolling = true;
    try {
      await _loadNotifications(showLoading: false);
    } finally {
      _isPolling = false;
    }
  }

  Future<void> _loadNotifications({required bool showLoading}) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final res = await ApiService.get(ApiConstants.notifications);
      if (res is List) {
        _notifications = res;
        _error = null;
        if (!showLoading) notifyListeners();
      }
    } catch (e) {
      if (showLoading) {
        _error = e.toString();
      }
    } finally {
      if (showLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await ApiService.put('${ApiConstants.notifications}$notificationId/read/');
      final idx = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (idx != -1) {
        _notifications[idx]['is_read'] = true;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiService.put(ApiConstants.markAllRead);
      for (var n in _notifications) {
        n['is_read'] = true;
      }
      notifyListeners();
    } catch (_) {}
  }
}
