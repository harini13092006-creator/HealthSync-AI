import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../services/storage_service.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  bool _routineNotifs = true;
  bool _waterNotifs = true;
  bool _summaryNotifs = true;

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiConstants.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _saveBaseUrl() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isNotEmpty) {
      await StorageService.saveCustomBaseUrl(newUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API URL updated to: $newUrl'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out from HealthSync AI?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PROMINENT MEDICAL DISCLAIMER BANNER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.gavel_rounded, color: AppColors.warning, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Medical Safety Disclaimer',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'HealthSync AI is strictly a personal wellness and habit management tool. It does NOT provide medical diagnosis, clinical treatment, prescription advice, or emergency intervention. Always consult a qualified healthcare physician for medical guidance and clinical conditions.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Backend API Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backend Server Configuration',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Configure the API endpoint URL for your active environment:',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'API Base URL',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check, color: AppColors.primary),
                          onPressed: _saveBaseUrl,
                          tooltip: 'Apply URL',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            _urlController.text = 'http://127.0.0.1:8000';
                            _saveBaseUrl();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          child: const Text('127.0.0.1:8000 (Desktop)'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            _urlController.text = 'http://10.0.2.2:8000';
                            _saveBaseUrl();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          child: const Text('10.0.2.2:8000 (Android)'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notification Preferences
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Alerts',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Daily Routine Reminders', style: TextStyle(fontSize: 14)),
                      subtitle: const Text('Get notified before scheduled habit slots', style: TextStyle(fontSize: 12)),
                      value: _routineNotifs,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => setState(() => _routineNotifs = val),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hydration Prompts', style: TextStyle(fontSize: 14)),
                      subtitle: const Text('Interval reminders to drink water', style: TextStyle(fontSize: 12)),
                      value: _waterNotifs,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => setState(() => _waterNotifs = val),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Evening Reflection & Score', style: TextStyle(fontSize: 14)),
                      subtitle: const Text('Daily Wellness Score summary prompt', style: TextStyle(fontSize: 12)),
                      value: _summaryNotifs,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => setState(() => _summaryNotifs = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // App Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('App Version', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        Text('1.0.0+1 (Material 3)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.divider),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Architecture', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        Text('Flutter + DRF + MySQL 8.4', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.divider),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('AI Engine', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        Text('Adaptive Scheduler & ML Predictor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
