import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/task_provider.dart';
import '../../providers/recommendation_provider.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Map<String, dynamic> _task;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _task = Map<String, dynamic>.from(widget.task);
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'EXERCISE':
        return AppColors.secondary;
      case 'MEAL':
        return AppColors.warning;
      case 'SLEEP':
        return AppColors.sleep;
      case 'MEDITATION':
        return AppColors.accent;
      case 'HYDRATION':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final category = _task['category'] ?? 'GENERAL';
    final priority = _task['priority'] ?? 'MEDIUM';
    final status = (_task['status'] ?? 'PENDING').toString().toUpperCase();
    final title = _task['title'] ?? 'Task Details';
    final description = _task['description'] ?? 'No description provided.';
    final startTime = _task['scheduled_start'] != null
        ? _task['scheduled_start'].toString().substring(0, 5)
        : '--:--';
    final endTime = _task['scheduled_end'] != null
        ? _task['scheduled_end'].toString().substring(0, 5)
        : '--:--';
    final duration = _task['duration_minutes'] ?? 15;
    final id = _task['id'] as int;

    final catColor = _getCategoryColor(category);
    final isCompleted = status == 'COMPLETED';
    final isSkipped = status == 'SKIPPED';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.success.withValues(alpha: 0.12)
                          : isSkipped
                              ? AppColors.error.withValues(alpha: 0.12)
                              : catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.check_circle
                              : isSkipped
                                  ? Icons.cancel
                                  : Icons.schedule,
                          color: isCompleted
                              ? AppColors.success
                              : isSkipped
                                  ? AppColors.error
                                  : catColor,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Status: $status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? AppColors.success
                                : isSkipped
                                    ? AppColors.error
                                    : catColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Chips: Category, Priority, Duration
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: Icon(Icons.category, size: 16, color: catColor),
                        label: Text(category, style: TextStyle(color: catColor, fontWeight: FontWeight.w600)),
                        backgroundColor: catColor.withValues(alpha: 0.1),
                        side: BorderSide.none,
                      ),
                      Chip(
                        avatar: const Icon(Icons.flag, size: 16, color: AppColors.warning),
                        label: Text('Priority: $priority', style: const TextStyle(fontWeight: FontWeight.w600)),
                        backgroundColor: AppColors.chipBackground,
                        side: BorderSide.none,
                      ),
                      Chip(
                        avatar: const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondary),
                        label: Text('$duration min', style: const TextStyle(fontWeight: FontWeight.w600)),
                        backgroundColor: AppColors.chipBackground,
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Time Box
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('START TIME', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(startTime, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                          const Icon(Icons.arrow_forward, color: AppColors.divider),
                          Column(
                            children: [
                              const Text('END TIME', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(endTime, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description & Routine Notes',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Minimum Viable Task (MVT) Suggestion Card
                  _buildMvtCard(id),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (!isCompleted && !isSkipped) ...[
                    ElevatedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isLoading = true);
                        final ok = await taskProvider.completeTask(id);
                        if (!mounted) return;
                        setState(() => _isLoading = false);
                        if (ok) {
                          setState(() => _task['status'] = 'COMPLETED');
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Task marked completed!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Mark as Completed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showRescheduleDialog(id, taskProvider),
                            icon: const Icon(Icons.edit_calendar),
                            label: const Text('Reschedule'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showSkipDialog(id, taskProvider),
                            icon: const Icon(Icons.skip_next),
                            label: const Text('Skip'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildMvtCard(int taskId) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Short on time? Use Minimum Viable Task',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Convert this task into a 10-minute micro version to maintain your habit momentum without burnout.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _generateMvtForTask(),
                icon: const Icon(Icons.bolt, size: 18),
                label: const Text('Generate 10-Min Fallback MVT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateMvtForTask() async {
    final recProvider = Provider.of<RecommendationProvider>(context, listen: false);
    setState(() => _isLoading = true);
    final mvt = await recProvider.generateMvt(
      minutes: 10,
      activity: _task['category'] == 'EXERCISE' ? 'Walking & Mobility' : 'Mindful Reset',
    );
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (mvt != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.bolt_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Fallback MVT Created'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mvt['title'] ?? '10-Minute Micro Habit',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(mvt['description'] ?? 'Shortened habit session to maintain consistency.'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '💡 ${mvt['explanation'] ?? 'Maintaining the routine is more impactful than total duration.'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.primaryDark),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Dismiss')),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('MVT completed! Habit streak preserved.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Complete MVT Now'),
            ),
          ],
        ),
      );
    }
  }

  void _showRescheduleDialog(int taskId, TaskProvider provider) {
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reschedule Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a new start time for this task:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Pick New Time'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                );
                if (picked != null) selectedTime = picked;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final formattedTime =
                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';
              setState(() => _isLoading = true);
              final res = await provider.rescheduleTask(taskId, newTime: formattedTime, reason: 'Manual reschedule');
              setState(() => _isLoading = false);

              if (mounted) {
                if (res != null) {
                  setState(() {
                    _task['scheduled_start'] = formattedTime;
                    _task['status'] = 'RESCHEDULED';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task rescheduled successfully!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rescheduling failed.')),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSkipDialog(int taskId, TaskProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Skip Task?'),
        content: const Text(
          'Skipping will mark this task as skipped for today. Your Daily Wellness Score will adjust accordingly.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _isLoading = true);
              final ok = await provider.skipTask(taskId);
              setState(() => _isLoading = false);
              if (ok && mounted) {
                setState(() => _task['status'] = 'SKIPPED');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task marked as skipped.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Confirm Skip'),
          ),
        ],
      ),
    );
  }
}
