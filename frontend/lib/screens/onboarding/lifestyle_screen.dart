import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'goals_screen.dart';

class LifestyleScreen extends StatefulWidget {
  final Map<String, dynamic> onboardingData;
  const LifestyleScreen({super.key, required this.onboardingData});

  @override
  State<LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends State<LifestyleScreen> {
  String _activityLevel = 'MODERATELY_ACTIVE';
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 22, minute: 30);

  final List<Map<String, String>> _levels = [
    {
      'key': 'SEDENTARY',
      'title': 'Sedentary',
      'desc': 'Little to no structured exercise daily'
    },
    {
      'key': 'LIGHTLY_ACTIVE',
      'title': 'Lightly Active',
      'desc': 'Light movement or exercise 1-3 days/week'
    },
    {
      'key': 'MODERATELY_ACTIVE',
      'title': 'Moderately Active',
      'desc': 'Moderate exercise or brisk walking 3-5 days/week'
    },
    {
      'key': 'VERY_ACTIVE',
      'title': 'Very Active',
      'desc': 'Hard physical training or athletic routines 6-7 days/week'
    },
  ];

  Future<void> _pickWakeTime() async {
    final picked = await showTimePicker(context: context, initialTime: _wakeTime);
    if (picked != null) setState(() => _wakeTime = picked);
  }

  Future<void> _pickSleepTime() async {
    final picked = await showTimePicker(context: context, initialTime: _sleepTime);
    if (picked != null) setState(() => _sleepTime = picked);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  void _onNext() {
    final data = Map<String, dynamic>.from(widget.onboardingData);
    data['activity_level'] = _activityLevel;
    data['wake_time'] = _formatTime(_wakeTime);
    data['sleep_time'] = _formatTime(_sleepTime);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GoalsScreen(onboardingData: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lifestyle & Timings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LinearProgressIndicator(value: 2 / 6, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'Activity & Sleep Rhythm',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'HealthSync AI spaces your meals and exercises harmoniously between your waking and sleep hours.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              const Text('Typical Activity Level', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 12),
              ..._levels.map((lvl) {
                final isSelected = _activityLevel == lvl['key'];
                return GestureDetector(
                  onTap: () => setState(() => _activityLevel = lvl['key']!),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.divider,
                        width: isSelected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lvl['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(lvl['desc']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),

              const Text('Daily Timings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickWakeTime,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.wb_sunny_outlined, size: 18, color: AppColors.warning),
                                SizedBox(width: 6),
                                Text('Wake-Up', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _wakeTime.format(context),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickSleepTime,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.nightlight_round, size: 18, color: AppColors.sleep),
                                SizedBox(width: 6),
                                Text('Sleep Time', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _sleepTime.format(context),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _onNext,
                child: const Text('Next: Health Goals'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
