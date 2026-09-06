import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/recommendation_provider.dart';
import '../../providers/health_provider.dart';

class FoodRecommendationsScreen extends StatefulWidget {
  const FoodRecommendationsScreen({super.key});

  @override
  State<FoodRecommendationsScreen> createState() => _FoodRecommendationsScreenState();
}

class _FoodRecommendationsScreenState extends State<FoodRecommendationsScreen> {
  String _selectedMealType = 'ANY';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFoods();
    });
  }

  void _loadFoods() {
    Provider.of<RecommendationProvider>(context, listen: false)
        .fetchFoodRecommendations(mealType: _selectedMealType);
  }

  @override
  Widget build(BuildContext context) {
    final recProvider = Provider.of<RecommendationProvider>(context);
    final healthProvider = Provider.of<HealthProvider>(context);
    final foods = recProvider.foodRecommendations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutritional Recommendations'),
      ),
      body: Column(
        children: [
          // Meal Type Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMealChip('ANY', 'All Meals'),
                  const SizedBox(width: 8),
                  _buildMealChip('BREAKFAST', 'Breakfast'),
                  const SizedBox(width: 8),
                  _buildMealChip('LUNCH', 'Lunch'),
                  const SizedBox(width: 8),
                  _buildMealChip('DINNER', 'Dinner'),
                  const SizedBox(width: 8),
                  _buildMealChip('SNACK', 'Snacks'),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Food List
          Expanded(
            child: recProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : foods.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.restaurant_rounded, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No meal recommendations found.',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadFoods,
                              child: const Text('Refresh Suggestions'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadFoods(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: foods.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final food = foods[index];
                            return _buildFoodCard(food, healthProvider);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealChip(String type, String label) {
    final isSelected = _selectedMealType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() => _selectedMealType = type);
          _loadFoods();
        }
      },
      selectedColor: AppColors.warning.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.warning : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.warning : AppColors.divider,
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> food, HealthProvider healthProvider) {
    final name = food['name'] ?? 'Nutritious Meal';
    final calories = (food['calories'] ?? 350).toString();
    final protein = (food['protein_g'] ?? 15).toString();
    final carbs = (food['carbs_g'] ?? 40).toString();
    final fats = (food['fat_g'] ?? 10).toString();
    final dietType = food['diet_type'] ?? 'Vegetarian';
    final cuisine = food['cuisine'] ?? 'Indian';
    final explanation = food['explanation'] ??
        'Matched to your profile via cosine similarity and macro balancing.';

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
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$calories kcal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                _buildTag(dietType, AppColors.success),
                _buildTag(cuisine, AppColors.primary),
              ],
            ),
            const SizedBox(height: 12),

            // Macros Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroCol('Protein', '${protein}g', AppColors.primary),
                _buildMacroCol('Carbs', '${carbs}g', AppColors.warning),
                _buildMacroCol('Fats', '${fats}g', AppColors.sleep),
              ],
            ),
            const SizedBox(height: 12),

            // Explainable AI (XAI) card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.psychology_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Why this recommendation?',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          explanation,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Log Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await healthProvider.logMeal(
                    mealType: _selectedMealType == 'ANY' ? 'LUNCH' : _selectedMealType,
                    food: name,
                    calories: double.tryParse(calories) ?? 300.0,
                  );
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logged "$name" to today\'s meals!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_task, size: 18),
                label: const Text('Log as Today\'s Meal'),
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

  Widget _buildMacroCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}
