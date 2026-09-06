import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/recommendation_provider.dart';
import '../recommendations/food_recommendations_screen.dart';
import '../recommendations/exercise_recommendations_screen.dart';
import '../health/meditation_screen.dart';
import '../health/hydration_screen.dart';
import '../health/sleep_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);
    final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);

    await Future.wait([
      taskProvider.fetchTodaysTasks(),
      healthProvider.fetchHealthOverview(),
      analyticsProvider.fetchAllAnalytics(),
    ]);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final healthProvider = Provider.of<HealthProvider>(context);
    final analyticsProvider = Provider.of<AnalyticsProvider>(context);

    final userName = auth.user?['first_name'] ?? auth.user?['username'] ?? 'Friend';
    final todayStr = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final wellnessScore = analyticsProvider.wellnessScore;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Greeting & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()}, $userName 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      todayStr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => widget.onNavigateTab?.call(4),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Daily Wellness Score Card
            _buildWellnessScoreCard(wellnessScore, analyticsProvider),
            const SizedBox(height: 16),

            // Quick Actions Row
            _buildQuickActionsRow(),
            const SizedBox(height: 16),

            // Daily Task Completion Tracker
            _buildTaskProgressCard(taskProvider),
            const SizedBox(height: 16),

            // Next Upcoming Task Card
            if (taskProvider.nextUpcomingTask != null) ...[
              _buildUpcomingTaskCard(taskProvider.nextUpcomingTask!, taskProvider),
              const SizedBox(height: 16),
            ],

            // Health Snapshot Row: Hydration & Sleep
            Row(
              children: [
                Expanded(child: _buildHydrationCard(healthProvider)),
                const SizedBox(width: 12),
                Expanded(child: _buildSleepCard(healthProvider)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWellnessScoreCard(double score, AnalyticsProvider analytics) {
    Color ringColor;
    String scoreStatus;
    if (score >= 80) {
      ringColor = AppColors.success;
      scoreStatus = 'Optimal Balance';
    } else if (score >= 60) {
      ringColor = AppColors.primary;
      scoreStatus = 'Good Progress';
    } else {
      ringColor = AppColors.warning;
      scoreStatus = 'Building Momentum';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                // Score Ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(
                        value: (score / 100.0).clamp(0.0, 1.0),
                        strokeWidth: 7.5,
                        backgroundColor: ringColor.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${score.toInt()}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: ringColor,
                          ),
                        ),
                        const Text(
                          '/ 100',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Daily Wellness Score',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ringColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          scoreStatus,
                          style: TextStyle(
                            color: ringColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Holistic metric combining tasks, hydration, sleep, and activity.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.shield_outlined, size: 12, color: AppColors.textMuted),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Wellness optimization metric only — not for medical diagnosis.',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(
          icon: Icons.restaurant_menu_rounded,
          label: 'Meals',
          color: AppColors.warning,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FoodRecommendationsScreen()),
            );
          },
        ),
        _buildActionItem(
          icon: Icons.fitness_center_rounded,
          label: 'Workout',
          color: AppColors.secondary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExerciseRecommendationsScreen()),
            );
          },
        ),
        _buildActionItem(
          icon: Icons.self_improvement_rounded,
          label: 'Meditate',
          color: AppColors.accent,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MeditationScreen()),
            );
          },
        ),
        _buildActionItem(
          icon: Icons.bolt_rounded,
          label: '10m MVT',
          color: AppColors.primary,
          onTap: () => _triggerQuickMvt(),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskProgressCard(TaskProvider taskProvider) {
    final completed = taskProvider.completedCount;
    final total = taskProvider.totalCount;
    final pct = taskProvider.completionPercentage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Routine",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$completed / $total completed',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  total == 0
                      ? 'No tasks scheduled yet.'
                      : '${(pct * 100).toInt()}% of daily routine completed',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab?.call(1),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTaskCard(Map<String, dynamic> task, TaskProvider provider) {
    final title = task['title'] ?? 'Upcoming Task';
    final category = task['category'] ?? 'GENERAL';
    final startTime = task['scheduled_start'] != null
        ? task['scheduled_start'].toString().substring(0, 5)
        : 'Next';
    final duration = task['duration_minutes'] ?? 15;
    final id = task['id'] as int;

    return Card(
      color: AppColors.primary.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.alarm_on_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$startTime ($duration min)',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category,
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 28),
              tooltip: 'Complete',
              onPressed: () async {
                final ok = await provider.completeTask(id);
                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task marked completed!'),
                      backgroundColor: AppColors.success,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHydrationCard(HealthProvider provider) {
    final current = provider.waterCurrentMl;
    final target = provider.waterTargetMl;
    final pct = (current / (target > 0 ? target : 2500)).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HydrationScreen()),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.water_drop_rounded, color: AppColors.info, size: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.info, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Quick Add 250ml',
                    onPressed: () => provider.logWater(250),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$current ml',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Target: $target ml',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: AppColors.info.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.info),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSleepCard(HealthProvider provider) {
    final sleepDur = provider.sleepDuration;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SleepScreen()),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.sleep.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bedtime_rounded, color: AppColors.sleep, size: 20),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                sleepDur > 0 ? '${sleepDur.toStringAsFixed(1)} hrs' : 'Log Sleep',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'Target: 7.5 - 8.5 hrs',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (sleepDur / 8.0).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.sleep.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sleep),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _triggerQuickMvt() async {
    final recProvider = Provider.of<RecommendationProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final mvt = await recProvider.generateMvt(minutes: 10, activity: 'Stretching & Mobility');
    if (mounted) Navigator.of(context).pop(); // dismiss loading

    if (!mounted) return;
    if (mvt != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    '10-Minute Minimum Viable Task',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                mvt['title'] ?? '10-Min Micro Habit',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                mvt['description'] ?? 'A quick routine designed to preserve your habit streak even on busy days.',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '💡 AI Strategy: ${mvt['explanation'] ?? 'Lower barrier to action ensures consistency over intensity.'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.primaryDark),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Great job completing your 10-minute micro habit!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: const Text('Mark MVT Completed'),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to generate MVT. Please try again.')),
      );
    }
  }
}
