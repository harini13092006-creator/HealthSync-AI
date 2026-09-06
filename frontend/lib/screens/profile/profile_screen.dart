import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).fetchProfile();
    });
  }

  String _calculateBmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal Weight';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return AppColors.info;
    if (bmi < 25.0) return AppColors.success;
    if (bmi < 30.0) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);

    final user = authProvider.user ?? {};
    final health = profileProvider.healthProfile ?? {};
    final goals = profileProvider.goals;
    final foodPref = profileProvider.foodPreferences ?? {};
    final exPref = profileProvider.exercisePreferences ?? {};

    final fullName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final displayName = fullName.isNotEmpty ? fullName : (user['username'] ?? 'HealthSync User');
    final email = user['email'] ?? 'user@healthsync.ai';

    final age = health['age'] ?? 26;
    final height = (health['height_cm'] ?? 175.0).toDouble();
    final weight = (health['weight_kg'] ?? 70.0).toDouble();
    final bmi = (health['bmi'] ?? (weight / ((height / 100) * (height / 100)))).toDouble();
    final activityLevel = health['activity_level'] ?? 'MODERATELY_ACTIVE';

    final wakeTime = health['wake_up_time'] != null ? health['wake_up_time'].toString().substring(0, 5) : '07:00';
    final sleepTime = health['sleep_time'] != null ? health['sleep_time'].toString().substring(0, 5) : '23:00';
    final workStart = health['work_start_time'] != null ? health['work_start_time'].toString().substring(0, 5) : '09:00';
    final workEnd = health['work_end_time'] != null ? health['work_end_time'].toString().substring(0, 5) : '17:00';

    final dietType = foodPref['diet_type'] ?? 'Vegetarian';
    final allergies = foodPref['allergies'] ?? 'None';
    final preferredDuration = exPref['preferred_duration_minutes'] ?? 30;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => profileProvider.fetchProfile(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Avatar & Name Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'HealthSync AI Member',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Physical Health Metrics (Age, Height, Weight, BMI)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Biometric Baseline',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildBiometricCol('Age', '$age yrs'),
                          _buildBiometricCol('Height', '${height.toInt()} cm'),
                          _buildBiometricCol('Weight', '${weight.toInt()} kg'),
                          Column(
                            children: [
                              Text(
                                bmi.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _getBmiColor(bmi),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getBmiColor(bmi).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _calculateBmiCategory(bmi),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: _getBmiColor(bmi),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Lifestyle Schedule
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Schedule & Availability',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 14),
                      _buildScheduleRow(Icons.wb_sunny_outlined, 'Wake Up Time', wakeTime, AppColors.warning),
                      const Divider(height: 16, color: AppColors.divider),
                      _buildScheduleRow(Icons.work_outline_rounded, 'Work / Focus Block', '$workStart - $workEnd', AppColors.primary),
                      const Divider(height: 16, color: AppColors.divider),
                      _buildScheduleRow(Icons.bedtime_outlined, 'Bedtime', sleepTime, AppColors.sleep),
                      const Divider(height: 16, color: AppColors.divider),
                      _buildScheduleRow(Icons.directions_run_rounded, 'Activity Level', activityLevel.replaceAll('_', ' '), AppColors.secondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Preferences Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preferences & Customization',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPrefBadge('Diet: $dietType', AppColors.warning),
                          _buildPrefBadge('Allergies: $allergies', AppColors.error),
                          _buildPrefBadge('Session: $preferredDuration min', AppColors.secondary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Active Goals
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Active Health Goals',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Text(
                            '${goals.length} Goals',
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (goals.isEmpty)
                        const Text(
                          'Consistent Routine, Hydration, Sleep Optimization, Mindful Breathing.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        )
                      else
                        ...goals.map((g) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      g['title'] ?? g['goal_type'] ?? 'Health Goal',
                                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricCol(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildScheduleRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildPrefBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
