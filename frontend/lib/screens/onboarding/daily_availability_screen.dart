import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/task_provider.dart';
import '../main/main_navigation_screen.dart';

class DailyAvailabilityScreen extends StatefulWidget {
  final Map<String, dynamic> onboardingData;
  const DailyAvailabilityScreen({super.key, required this.onboardingData});

  @override
  State<DailyAvailabilityScreen> createState() => _DailyAvailabilityScreenState();
}

class _DailyAvailabilityScreenState extends State<DailyAvailabilityScreen> {
  final List<Map<String, String>> _unavailablePeriods = [
    {'start': '09:00', 'end': '16:00', 'label': 'College / Classes'},
    {'start': '16:00', 'end': '17:00', 'label': 'Commute / Travel'},
  ];

  final _labelController = TextEditingController();
  TimeOfDay _blockStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _blockEnd = const TimeOfDay(hour: 16, minute: 0);

  void _addPeriod() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Busy Period'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _labelController,
                decoration: const InputDecoration(labelText: 'Commitment Name (e.g. Work, Study)'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final t = await showTimePicker(context: context, initialTime: _blockStart);
                        if (t != null) setDialogState(() => _blockStart = t);
                      },
                      child: Text('Start: ${_blockStart.format(context)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final t = await showTimePicker(context: context, initialTime: _blockEnd);
                        if (t != null) setDialogState(() => _blockEnd = t);
                      },
                      child: Text('End: ${_blockEnd.format(context)}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final label = _labelController.text.trim();
                if (label.isNotEmpty) {
                  setState(() {
                    _unavailablePeriods.add({
                      'start': '${_blockStart.hour.toString().padLeft(2, '0')}:${_blockStart.minute.toString().padLeft(2, '0')}',
                      'end': '${_blockEnd.hour.toString().padLeft(2, '0')}:${_blockEnd.minute.toString().padLeft(2, '0')}',
                      'label': label,
                    });
                  });
                  _labelController.clear();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitOnboarding() async {
    final data = Map<String, dynamic>.from(widget.onboardingData);
    data['availability_start'] = '07:00:00';
    data['availability_end'] = '22:00:00';
    data['unavailable_periods'] = _unavailablePeriods;

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    final success = await profileProvider.submitCompleteOnboarding(data);
    if (!mounted) return;

    if (success) {
      await authProvider.setOnboardingComplete();
      // Trigger initial routine generation
      await taskProvider.fetchTodaysTasks();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileProvider.error ?? 'Failed to save profile.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Commitments')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LinearProgressIndicator(value: 6 / 6, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'Work & Study Schedule',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'HealthSync AI ensures wellness tasks and exercises never overlap with your classes or work commitments.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Blocked Periods', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton.icon(
                    onPressed: _addPeriod,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Block'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Expanded(
                child: ListView.builder(
                  itemCount: _unavailablePeriods.length,
                  itemBuilder: (ctx, i) {
                    final item = _unavailablePeriods[i];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.school_outlined, color: AppColors.primary, size: 20),
                        ),
                        title: Text(item['label']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${item['start']} – ${item['end']}', style: const TextStyle(color: AppColors.textSecondary)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
                          onPressed: () {
                            setState(() => _unavailablePeriods.removeAt(i));
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

              ElevatedButton(
                onPressed: profileProvider.isLoading ? null : _submitOnboarding,
                child: profileProvider.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Generate My Personalized Plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
