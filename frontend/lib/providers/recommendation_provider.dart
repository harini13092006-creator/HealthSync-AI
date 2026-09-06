import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

class RecommendationProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _foodRecommendations = [];
  List<dynamic> _exerciseRecommendations = [];
  Map<String, dynamic>? _currentMvt;
  List<dynamic> _history = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get foodRecommendations => _foodRecommendations;
  List<dynamic> get exerciseRecommendations => _exerciseRecommendations;
  Map<String, dynamic>? get currentMvt => _currentMvt;
  List<dynamic> get history => _history;

  Future<void> fetchFoodRecommendations({String mealType = 'ANY'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.get('${ApiConstants.foodRecommendations}?meal_type=$mealType');
      if (res is Map && res.containsKey('recommendations')) {
        _foodRecommendations = res['recommendations'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchExerciseRecommendations({int duration = 30}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.get('${ApiConstants.exerciseRecommendations}?duration=$duration');
      if (res is Map && res.containsKey('recommendations')) {
        _exerciseRecommendations = res['recommendations'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> generateMvt({int minutes = 10, String activity = 'Walking'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.post(ApiConstants.minimumViableTask, body: {
        'minutes': minutes,
        'activity': activity,
      });
      if (res is Map<String, dynamic>) {
        _currentMvt = res;
      }
      _isLoading = false;
      notifyListeners();
      return res as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchHistory() async {
    try {
      final res = await ApiService.get(ApiConstants.recommendationsHistory);
      if (res is List) {
        _history = res;
        notifyListeners();
      }
    } catch (_) {}
  }
}
