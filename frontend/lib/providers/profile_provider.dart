import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

class ProfileProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _healthProfile;
  Map<String, dynamic>? _foodPreferences;
  Map<String, dynamic>? _exercisePreferences;
  List<dynamic> _goals = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get healthProfile => _healthProfile;
  Map<String, dynamic>? get foodPreferences => _foodPreferences;
  Map<String, dynamic>? get exercisePreferences => _exercisePreferences;
  List<dynamic> get goals => _goals;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.get(ApiConstants.profile);
      if (res is Map<String, dynamic>) {
        _healthProfile = res;
      }
      final goalsRes = await ApiService.get(ApiConstants.goals);
      if (goalsRes is List) {
        _goals = goalsRes;
      }
      final foodRes = await ApiService.get(ApiConstants.foodPreferences);
      if (foodRes is Map<String, dynamic>) {
        _foodPreferences = foodRes;
      }
      final exRes = await ApiService.get(ApiConstants.exercisePreferences);
      if (exRes is Map<String, dynamic>) {
        _exercisePreferences = exRes;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitCompleteOnboarding(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.post(ApiConstants.completeOnboarding, body: data);
      await fetchProfile();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateHealthProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.put(ApiConstants.profile, body: data);
      _healthProfile = res;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
