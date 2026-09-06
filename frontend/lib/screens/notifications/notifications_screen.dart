import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toUpperCase()) {
      case 'HYDRATION':
        return Icons.water_drop_rounded;
      case 'TASK':
        return Icons.task_alt_rounded;
      case 'SLEEP':
        return Icons.bedtime_rounded;
      case 'MEAL':
        return Icons.restaurant_rounded;
      case 'ALERT':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toUpperCase()) {
      case 'HYDRATION':
        return AppColors.info;
      case 'TASK':
        return AppColors.primary;
      case 'SLEEP':
        return AppColors.sleep;
      case 'MEAL':
        return AppColors.warning;
      case 'ALERT':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final notifications = notificationProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => notificationProvider.markAllAsRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notificationProvider.fetchNotifications(),
        color: AppColors.primary,
        child: notificationProvider.isLoading && notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : notifications.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      final id = item['id'] as int;
                      final title = item['title'] ?? 'HealthSync Alert';
                      final message = item['message'] ?? '';
                      final isRead = item['is_read'] == true;
                      final type = item['notification_type'] ?? 'GENERAL';
                      final timeStr = item['created_at'] != null
                          ? item['created_at'].toString().substring(0, 10)
                          : 'Recent';

                      final iconColor = _getNotificationColor(type);

                      return InkWell(
                        onTap: () {
                          if (!isRead) notificationProvider.markAsRead(id);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isRead ? AppColors.divider : AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_getNotificationIcon(type), color: iconColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          timeStr,
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isRead) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.notifications_none_rounded, size: 54, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text(
              'No Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            SizedBox(height: 8),
            Text(
              'You\'re all caught up! Routine reminders and wellness updates will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
