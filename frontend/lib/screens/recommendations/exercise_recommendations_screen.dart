import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/recommendation_provider.dart';
import '../../providers/health_provider.dart';

class ExerciseRecommendationsScreen extends StatefulWidget {
  const ExerciseRecommendationsScreen({super.key});

  @override
  State<ExerciseRecommendationsScreen> createState() => _ExerciseRecommendationsScreenState();
}

class _ExerciseRecommendationsScreenState extends State<ExerciseRecommendationsScreen> {
  int _selectedDuration = 30;
  final String _selectedCategory = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExercises();
    });
  }

  void _loadExercises() {
    Provider.of<RecommendationProvider>(context, listen: false)
        .fetchExerciseRecommendations(duration: _selectedDuration);
  }

  @override
  Widget build(BuildContext context) {
    final recProvider = Provider.of<RecommendationProvider>(context);
    final healthProvider = Provider.of<HealthProvider>(context);
    final exercises = recProvider.exerciseRecommendations;

    final filtered = exercises.where((ex) {
      if (_selectedCategory == 'ALL') return true;
      final cat = (ex['category'] ?? '').toString().toUpperCase();
      return cat == _selectedCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise & Activity Recommendations'),
      ),
      body: Column(
        children: [
          // Duration Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                const Text('Duration:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildDurationChip(10, '10 min (MVT)'),
                        const SizedBox(width: 6),
                        _buildDurationChip(20, '20 min'),
                        const SizedBox(width: 6),
                        _buildDurationChip(30, '30 min'),
                        const SizedBox(width: 6),
                        _buildDurationChip(45, '45 min'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Exercise List
          Expanded(
            child: recProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.fitness_center_rounded, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No exercises found for this filter.',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadExercises,
                              child: const Text('Reload Recommendations'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadExercises(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final ex = filtered[index];
                            return _buildExerciseCard(ex, healthProvider);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip(int minutes, String label) {
    final isSelected = _selectedDuration == minutes;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() => _selectedDuration = minutes);
          _loadExercises();
        }
      },
      selectedColor: AppColors.secondary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.secondary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 11,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.secondary : AppColors.divider,
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> ex, HealthProvider healthProvider) {
    final name = ex['name'] ?? 'Cardio & Mobility';
    final category = ex['category'] ?? 'General';
    final duration = ex['duration_minutes'] ?? _selectedDuration;
    final calories = (ex['calories_burned'] ?? (duration * 6)).toString();
    final intensity = ex['intensity'] ?? 'Moderate';
    final instructions = ex['instructions'] ??
        ex['description'] ??
        'Perform exercises at a comfortable pace with proper breathing and hydration.';
    final isMvt = ex['is_mvt'] == true || duration <= 10;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (isMvt) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'MVT',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '~$calories kcal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 6,
              children: [
                _buildTag('$duration min', AppColors.primary),
                _buildTag(category, AppColors.secondary),
                _buildTag('Intensity: $intensity', AppColors.accent),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              instructions,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),

            // Log Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final ok = await healthProvider.logActivity(
                    steps: duration * 100,
                    activeMinutes: duration,
                    exerciseMinutes: duration,
                  );
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logged $duration mins of "$name"!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Log as Completed Activity'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
