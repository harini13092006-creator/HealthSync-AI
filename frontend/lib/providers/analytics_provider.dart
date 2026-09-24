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

  /// Loads the only analytics value shown on the dashboard. The detailed
  /// analytics endpoints are deferred until the user opens Analytics.
  Future<void> fetchWellnessScore() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get(ApiConstants.wellnessScore);
      if (response is Map<String, dynamic>) {
        _wellnessScoreData = response;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // These independent endpoints should not make the Analytics screen wait
      // for one network round trip at a time.
      final responses = await Future.wait([
        ApiService.get(ApiConstants.wellnessScore),
        ApiService.get(ApiConstants.weeklyAnalytics),
        ApiService.get(ApiConstants.behaviorAnalytics),
      ]);

      final scoreRes = responses[0];
      if (scoreRes is Map<String, dynamic>) {
        _wellnessScoreData = scoreRes;
      }
      final weeklyRes = responses[1];
      if (weeklyRes is Map<String, dynamic>) {
        _weeklyData = weeklyRes;
      }
      final behavRes = responses[2];
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
