import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static bool _notificationsEnabled = true;

  static bool get areNotificationsEnabled => _notificationsEnabled;

  static void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
  }

  static Future<void> initialize() async {
    // Placeholder initialization for local and FCM push notification capabilities
    if (kDebugMode) {
      print('HealthSync AI NotificationService initialized.');
    }
  }

  static Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_notificationsEnabled) return;
    if (kDebugMode) {
      print('Scheduled notification [$id] "$title" for $scheduledTime');
    }
  }

  static Future<void> showInstantAlert({
    required String title,
    required String body,
  }) async {
    if (!_notificationsEnabled) return;
    if (kDebugMode) {
      print('Instant notification: $title - $body');
    }
  }
}
