import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/health_provider.dart';
import 'hydration_screen.dart';
import 'sleep_screen.dart';
import 'meditation_screen.dart';
import '../recommendations/food_recommendations_screen.dart';
import '../recommendations/exercise_recommendations_screen.dart';

class HealthMonitoringScreen extends StatefulWidget {
  const HealthMonitoringScreen({super.key});

  @override
  State<HealthMonitoringScreen> createState() => _HealthMonitoringScreenState();
}

class _HealthMonitoringScreenState extends State<HealthMonitoringScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HealthProvider>(context, listen: false).fetchHealthOverview();
    });
  }

  void _showLogStepsDialog() {
    final controller = TextEditingController(text: '1000');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Daily Steps'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of steps',
            hintText: 'e.g. 5000',
            prefixIcon: Icon(Icons.directions_walk_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final steps = int.tryParse(controller.text.trim());
              if (steps != null && steps > 0) {
                Navigator.of(ctx).pop();
                final provider = Provider.of<HealthProvider>(context, listen: false);
                await provider.logActivity(
                  steps: steps,
                  activeMinutes: (steps / 100).round(),
                  exerciseMinutes: (steps / 200).round(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logged $steps steps! 🚶'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Steps'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final healthProvider = Provider.of<HealthProvider>(context);
    final steps = healthProvider.steps;
    final activeMinutes = healthProvider.activeMinutes;
    final waterCurrent = healthProvider.waterCurrentMl;
    final waterTarget = healthProvider.waterTargetMl;
    final sleepHours = healthProvider.sleepDuration;
    final meditationMins = healthProvider.meditationMinutes;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => healthProvider.fetchHealthOverview(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Activity & Steps Hero Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Daily Steps & Activity',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Target: 8,000 steps',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: _showLogStepsDialog,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Log Steps'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildActivityStat(
                            icon: Icons.directions_walk_rounded,
                            value: steps.toString(),
                            label: 'Steps',
                            color: AppColors.primary,
                          ),
                          Container(width: 1, height: 40, color: AppColors.divider),
                          _buildActivityStat(
                            icon: Icons.timer_outlined,
                            value: '$activeMinutes m',
                            label: 'Active Time',
                            color: AppColors.secondary,
                          ),
                          Container(width: 1, height: 40, color: AppColors.divider),
                          _buildActivityStat(
                            icon: Icons.local_fire_department_rounded,
                            value: '${(steps * 0.04).toInt()}',
                            label: 'Est. kcal',
                            color: AppColors.warning,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Wellness Pillars',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),

              // Hydration Card
              _buildMetricCard(
                title: 'Hydration',
                subtitle: '$waterCurrent / $waterTarget ml',
                progress: (waterCurrent / (waterTarget > 0 ? waterTarget : 2500)).clamp(0.0, 1.0),
                color: AppColors.info,
                icon: Icons.water_drop_rounded,
                actionLabel: 'Log Water',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HydrationScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Sleep Card
              _buildMetricCard(
                title: 'Sleep & Recovery',
                subtitle: sleepHours > 0 ? '${sleepHours.toStringAsFixed(1)} hours logged' : 'Not logged yet',
                progress: (sleepHours / 8.0).clamp(0.0, 1.0),
                color: AppColors.sleep,
                icon: Icons.bedtime_rounded,
                actionLabel: 'Log Sleep',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SleepScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Mindfulness Card
              _buildMetricCard(
                title: 'Mindfulness & Meditation',
                subtitle: '$meditationMins mindful minutes completed today',
                progress: (meditationMins / 15.0).clamp(0.0, 1.0),
                color: AppColors.accent,
                icon: Icons.self_improvement_rounded,
                actionLabel: 'Start Session',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MeditationScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Nutrition & Meals Card
              _buildMetricCard(
                title: 'Nutrition & Meals',
                subtitle: 'Explore personalized AI food recommendations',
                progress: 0.8,
                color: AppColors.warning,
                icon: Icons.restaurant_menu_rounded,
                actionLabel: 'Explore Meals',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FoodRecommendationsScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Workouts Card
              _buildMetricCard(
                title: 'Workout & Fitness',
                subtitle: 'Find exercises tailored to your schedule',
                progress: 0.7,
                color: AppColors.secondary,
                icon: Icons.fitness_center_rounded,
                actionLabel: 'View Workouts',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ExerciseRecommendationsScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String subtitle,
    required double progress,
    required Color color,
    required IconData icon,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
