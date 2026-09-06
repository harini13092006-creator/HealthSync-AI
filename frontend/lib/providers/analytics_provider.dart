import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

class AnalyticsProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _wellnessScoreData = {};
  Map<String, dynamic> _dailyData = {};
  Map<String, dynamic> _weeklyData = {};
  Map<String, dynamic> _behaviorData = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get wellnessScoreData => _wellnessScoreData;
  Map<String, dynamic> get dailyData => _dailyData;
  Map<String, dynamic> get weeklyData => _weeklyData;
  Map<String, dynamic> get behaviorData => _behaviorData;

  double get wellnessScore => (_wellnessScoreData['score'] ?? 75.0).toDouble();

  Future<void> fetchAllAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final scoreRes = await ApiService.get(ApiConstants.wellnessScore);
      if (scoreRes is Map<String, dynamic>) {
        _wellnessScoreData = scoreRes;
      }
      final dailyRes = await ApiService.get(ApiConstants.dailyAnalytics);
      if (dailyRes is Map<String, dynamic>) {
        _dailyData = dailyRes;
      }
      final weeklyRes = await ApiService.get(ApiConstants.weeklyAnalytics);
      if (weeklyRes is Map<String, dynamic>) {
        _weeklyData = weeklyRes;
      }
      final behavRes = await ApiService.get(ApiConstants.behaviorAnalytics);
      if (behavRes is Map<String, dynamic>) {
        _behaviorData = behavRes;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
