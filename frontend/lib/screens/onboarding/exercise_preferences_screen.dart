import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'daily_availability_screen.dart';

class ExercisePreferencesScreen extends StatefulWidget {
  final Map<String, dynamic> onboardingData;
  const ExercisePreferencesScreen({super.key, required this.onboardingData});

  @override
  State<ExercisePreferencesScreen> createState() => _ExercisePreferencesScreenState();
}

class _ExercisePreferencesScreenState extends State<ExercisePreferencesScreen> {
  final Set<String> _selectedExercises = {'Walking', 'Yoga'};
  int _selectedDuration = 30;
  String _fitnessLevel = 'BEGINNER';

  final List<String> _exerciseTypes = ['Walking', 'Running', 'Yoga', 'Strength', 'Stretching', 'Mobility'];
  final List<int> _durations = [10, 20, 30, 45, 60];
  final List<String> _fitnessLevels = ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'];

  void _onNext() {
    final data = Map<String, dynamic>.from(widget.onboardingData);
    data['preferred_exercises'] = _selectedExercises.toList();
    data['preferred_duration'] = _selectedDuration;
    data['fitness_level'] = _fitnessLevel;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DailyAvailabilityScreen(onboardingData: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Preferences')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LinearProgressIndicator(value: 5 / 6, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'Movement & Fitness Habits',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose exercises that you enjoy and realistic durations that fit your day.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              const Text('Preferred Activities', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _exerciseTypes.map((ex) {
                  final isSelected = _selectedExercises.contains(ex);
                  return FilterChip(
                    label: Text(ex),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedExercises.add(ex);
                        } else {
                          if (_selectedExercises.length > 1) {
                            _selectedExercises.remove(ex);
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              const Text('Available Exercise Duration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _durations.map((d) {
                  final isSelected = _selectedDuration == d;
                  return ChoiceChip(
                    label: Text('$d min'),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedDuration = d);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              const Text('Fitness Level', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: _fitnessLevels.map((lvl) {
                  return ButtonSegment(
                    value: lvl,
                    label: Text(lvl[0] + lvl.substring(1).toLowerCase()),
                  );
                }).toList(),
                selected: {_fitnessLevel},
                onSelectionChanged: (newVal) {
                  setState(() => _fitnessLevel = newVal.first);
                },
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _onNext,
                child: const Text('Next: Daily Availability'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
