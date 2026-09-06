import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'exercise_preferences_screen.dart';

class FoodPreferencesScreen extends StatefulWidget {
  final Map<String, dynamic> onboardingData;
  const FoodPreferencesScreen({super.key, required this.onboardingData});

  @override
  State<FoodPreferencesScreen> createState() => _FoodPreferencesScreenState();
}

class _FoodPreferencesScreenState extends State<FoodPreferencesScreen> {
  String _dietType = 'VEGETARIAN';
  String _cuisine = 'South Indian';
  final _allergiesController = TextEditingController(text: '');

  final List<String> _dietOptions = ['VEGETARIAN', 'VEGAN', 'EGGETARIAN', 'NON_VEGETARIAN'];
  final List<String> _cuisineOptions = ['South Indian', 'North Indian', 'Continental', 'Asian', 'Mediterranean'];

  @override
  void dispose() {
    _allergiesController.dispose();
    super.dispose();
  }

  void _onNext() {
    final data = Map<String, dynamic>.from(widget.onboardingData);
    data['diet_type'] = _dietType;
    data['cuisine'] = _cuisine;
    final allergyText = _allergiesController.text.trim();
    data['allergies'] = allergyText.isNotEmpty
        ? allergyText.split(',').map((e) => e.trim()).toList()
        : [];
    data['food_preferences'] = [_cuisine, _dietType];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExercisePreferencesScreen(onboardingData: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Preferences')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LinearProgressIndicator(value: 4 / 6, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'Dietary & Cuisine Preferences',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'HealthSync AI recommends meal ideas based on your culinary traditions and dietary requirements.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              const Text('Diet Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _dietOptions.map((d) {
                  final isSelected = _dietType == d;
                  return ChoiceChip(
                    label: Text(d.replaceAll('_', ' ').toLowerCase().replaceFirst(
                          d[0].toLowerCase(),
                          d[0],
                        )),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _dietType = d);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              const Text('Preferred Cuisine', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _cuisine,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.public_rounded),
                ),
                items: _cuisineOptions.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _cuisine = v);
                },
              ),
              const SizedBox(height: 24),

              const Text('Known Food Allergies (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Peanuts, Shellfish, Gluten (comma-separated)',
                  prefixIcon: Icon(Icons.no_food_outlined),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _onNext,
                child: const Text('Next: Exercise Preferences'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
