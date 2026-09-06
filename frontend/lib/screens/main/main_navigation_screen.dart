import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../tasks/tasks_screen.dart';
import '../health/health_monitoring_screen.dart';
import '../analytics/analytics_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'HealthSync AI';
      case 1:
        return 'Daily Schedule';
      case 2:
        return 'Health Monitoring';
      case 3:
        return 'Progress & Analytics';
      case 4:
        return 'Profile';
      default:
        return 'HealthSync AI';
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificationProvider>(context);
    final unreadCount = notifProvider.unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_currentIndex == 0) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.spa_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              _getAppBarTitle(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // Notification Bell with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$unreadCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(onNavigateTab: _onTabTapped),
          const TasksScreen(),
          const HealthMonitoringScreen(),
          const AnalyticsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt_outlined),
            activeIcon: Icon(Icons.task_alt_rounded),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline_rounded),
            activeIcon: Icon(Icons.favorite_rounded),
            label: 'Health',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights_rounded),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
