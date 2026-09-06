import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

class NotificationProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _notifications = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => n['is_read'] == false).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.get(ApiConstants.notifications);
      if (res is List) {
        _notifications = res;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
