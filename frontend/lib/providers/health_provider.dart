import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

class HealthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _healthOverview = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get healthOverview => _healthOverview;

  int get steps => _healthOverview['activity']?['steps'] ?? 0;
  int get activeMinutes => _healthOverview['activity']?['active_minutes'] ?? 0;
  double get sleepDuration => (_healthOverview['sleep']?['duration'] ?? 0.0).toDouble();
  int get waterCurrentMl => _healthOverview['hydration']?['current_ml'] ?? 0;
  int get waterTargetMl => _healthOverview['hydration']?['target_ml'] ?? 2500;
  double get waterPercentage => (_healthOverview['hydration']?['percentage'] ?? 0.0).toDouble();
  int get meditationMinutes => _healthOverview['meditation_minutes'] ?? 0;

  Future<void> fetchHealthOverview() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.get(ApiConstants.healthOverview);
      if (res is Map<String, dynamic>) {
        _healthOverview = res;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> logWater(int quantityMl) async {
    try {
      await ApiService.post(ApiConstants.logWater, body: {'quantity_ml': quantityMl});
      await fetchHealthOverview();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> logActivity({required int steps, required int activeMinutes, required int exerciseMinutes}) async {
    try {
      await ApiService.post(ApiConstants.logActivity, body: {
        'steps': steps,
        'active_minutes': activeMinutes,
        'exercise_minutes': exerciseMinutes,
      });
      await fetchHealthOverview();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> logSleep({required double duration, required int qualityRating}) async {
    try {
      await ApiService.post(ApiConstants.logSleep, body: {
        'duration': duration,
        'quality_rating': qualityRating,
      });
      await fetchHealthOverview();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> logMeal({required String mealType, required String food, double calories = 300.0, String notes = ''}) async {
    try {
      await ApiService.post(ApiConstants.logMeal, body: {
        'meal_type': mealType,
        'food': food,
        'calories': calories,
        'notes': notes,
      });
      await fetchHealthOverview();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> logMeditation({required String type, required int duration, String notes = ''}) async {
    try {
      await ApiService.post(ApiConstants.logMeditation, body: {
        'type': type,
        'duration': duration,
        'notes': notes,
      });
      await fetchHealthOverview();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
