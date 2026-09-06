import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/task_provider.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchTodaysTasks();
    });
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

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'EXERCISE':
        return Icons.fitness_center_rounded;
      case 'MEAL':
        return Icons.restaurant_rounded;
      case 'SLEEP':
        return Icons.bedtime_rounded;
      case 'MEDITATION':
        return Icons.self_improvement_rounded;
      case 'HYDRATION':
        return Icons.water_drop_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return AppColors.error;
      case 'MEDIUM':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final allTasks = taskProvider.tasks;

    final filteredTasks = allTasks.where((t) {
      final status = (t['status'] ?? 'PENDING').toString().toUpperCase();
      if (_selectedFilter == 'ALL') return true;
      if (_selectedFilter == 'PENDING') return status == 'PENDING';
      if (_selectedFilter == 'COMPLETED') return status == 'COMPLETED';
      if (_selectedFilter == 'SKIPPED') return status == 'SKIPPED' || status == 'MISSED';
      return true;
    }).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => taskProvider.fetchTodaysTasks(),
        color: AppColors.primary,
        child: Column(
          children: [
            // Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All (${allTasks.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('PENDING', 'Pending (${allTasks.where((t) => t['status'] == 'PENDING').length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('COMPLETED', 'Completed (${taskProvider.completedCount})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('SKIPPED', 'Skipped'),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),

            // Task List / Empty State
            Expanded(
              child: taskProvider.isLoading && allTasks.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredTasks.isEmpty
                      ? _buildEmptyState(taskProvider)
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: filteredTasks.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            return _buildTaskCard(task, taskProvider);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleGenerateRoutine(taskProvider),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text('AI Routine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = value);
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.divider,
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildEmptyState(TaskProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Tasks Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have no scheduled tasks for today matching this filter. Generate an AI routine to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _handleGenerateRoutine(provider),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Generate Daily AI Routine'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, TaskProvider provider) {
    final id = task['id'] as int;
    final title = task['title'] ?? 'Task';
    final category = task['category'] ?? 'GENERAL';
    final priority = task['priority'] ?? 'MEDIUM';
    final status = (task['status'] ?? 'PENDING').toString().toUpperCase();
    final startTime = task['scheduled_start'] != null
        ? task['scheduled_start'].toString().substring(0, 5)
        : '--:--';
    final endTime = task['scheduled_end'] != null
        ? task['scheduled_end'].toString().substring(0, 5)
        : '';
    final duration = task['duration_minutes'] ?? 15;

    final isCompleted = status == 'COMPLETED';
    final isSkipped = status == 'SKIPPED' || status == 'MISSED';
    final catColor = _getCategoryColor(category);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Card(
        color: isCompleted ? Colors.grey.shade50 : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getCategoryIcon(category), color: catColor, size: 24),
              ),
              const SizedBox(width: 12),

              // Title, details, time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: catColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(priority).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            priority,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getPriorityColor(priority),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$startTime ${endTime.isNotEmpty ? "- $endTime" : ""}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$duration min duration',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              if (!isCompleted && !isSkipped) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 26),
                  tooltip: 'Mark Completed',
                  onPressed: () => provider.completeTask(id),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
                  onSelected: (val) async {
                    if (val == 'skip') {
                      await provider.skipTask(id);
                    } else if (val == 'reschedule') {
                      _showRescheduleDialog(task, provider);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'reschedule', child: Text('Reschedule')),
                    const PopupMenuItem(value: 'skip', child: Text('Skip Task')),
                  ],
                ),
              ] else if (isCompleted) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: AppColors.success, size: 24),
              ] else ...[
                const SizedBox(width: 8),
                const Icon(Icons.cancel_outlined, color: AppColors.error, size: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRescheduleDialog(Map<String, dynamic> task, TaskProvider provider) {
    final id = task['id'] as int;
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reschedule Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reschedule "${task['title']}" to an optimal time:'),
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
                if (picked != null) {
                  selectedTime = picked;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final formattedTime =
                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';
              final res = await provider.rescheduleTask(id, newTime: formattedTime, reason: 'User requested reschedule');
              if (mounted) {
                if (res != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task rescheduled successfully!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to reschedule task.')),
                  );
                }
              }
            },
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGenerateRoutine(TaskProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final success = await provider.generateRoutine();
    if (mounted) Navigator.of(context).pop();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personalized daily routine generated!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to generate routine. Check your availability settings.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
