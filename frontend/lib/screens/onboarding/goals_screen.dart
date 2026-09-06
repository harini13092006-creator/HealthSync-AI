import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'food_preferences_screen.dart';

class GoalsScreen extends StatefulWidget {
  final Map<String, dynamic> onboardingData;
  const GoalsScreen({super.key, required this.onboardingData});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final Set<String> _selectedGoals = {'FITNESS', 'HEALTHY_EATING', 'HYDRATION'};

  final List<Map<String, dynamic>> _goalOptions = [
    {
      'key': 'FITNESS',
      'title': 'General Fitness',
      'desc': 'Build consistent movement and physical stamina',
      'icon': Icons.fitness_center_rounded,
      'color': AppColors.primary,
    },
    {
      'key': 'HEALTHY_EATING',
      'title': 'Healthy Eating',
      'desc': 'Nutritious, balanced meals timed around your day',
      'icon': Icons.restaurant_menu_rounded,
      'color': AppColors.warning,
    },
    {
      'key': 'HYDRATION',
      'title': 'Optimal Hydration',
      'desc': 'Stay energized with intelligent water intake reminders',
      'icon': Icons.water_drop_outlined,
      'color': AppColors.info,
    },
    {
      'key': 'BETTER_SLEEP',
      'title': 'Better Sleep Quality',
      'desc': 'Wind down smoothly and stabilize sleep schedule',
      'icon': Icons.bedtime_outlined,
      'color': AppColors.sleep,
    },
    {
      'key': 'MEDITATION',
      'title': 'Mindfulness & Meditation',
      'desc': 'Short breathing breaks to decompress cognitive stress',
      'icon': Icons.self_improvement_rounded,
      'color': AppColors.accent,
    },
  ];

  void _toggleGoal(String key) {
    setState(() {
      if (_selectedGoals.contains(key)) {
        if (_selectedGoals.length > 1) {
          _selectedGoals.remove(key);
        }
      } else {
        _selectedGoals.add(key);
      }
    });
  }

  void _onNext() {
    final data = Map<String, dynamic>.from(widget.onboardingData);
    data['goals'] = _selectedGoals.toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FoodPreferencesScreen(onboardingData: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wellness Goals')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LinearProgressIndicator(value: 3 / 6, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'What are your primary goals?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select the habit areas you wish to prioritize in your adaptive routine.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),

              ..._goalOptions.map((g) {
                final isSelected = _selectedGoals.contains(g['key']);
                return GestureDetector(
                  onTap: () => _toggleGoal(g['key']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.divider,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (g['color'] as Color).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(g['icon'], color: g['color'], size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(g['desc'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          color: isSelected ? AppColors.primary : AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _onNext,
                child: const Text('Next: Food Preferences'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
