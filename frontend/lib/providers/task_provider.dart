import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

class TaskProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _tasks = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get tasks => _tasks;

  int get completedCount => _tasks.where((t) => t['status'] == 'COMPLETED').length;
  int get totalCount => _tasks.length;
  double get completionPercentage => totalCount > 0 ? (completedCount / totalCount) : 0.0;

  Map<String, dynamic>? get nextUpcomingTask {
    final pending = _tasks.where((t) => t['status'] == 'PENDING').toList();
    return pending.isNotEmpty ? pending.first : null;
  }

  Future<void> fetchTodaysTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.get(ApiConstants.todaysTasks);
      if (res is List) {
        _tasks = res;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> completeTask(int taskId) async {
    try {
      final res = await ApiService.put('${ApiConstants.tasks}$taskId/complete/');
      final updated = res['task'];
      final idx = _tasks.indexWhere((t) => t['id'] == taskId);
      if (idx != -1 && updated != null) {
        _tasks[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> skipTask(int taskId) async {
    try {
      final res = await ApiService.put('${ApiConstants.tasks}$taskId/skip/');
      final updated = res['task'];
      final idx = _tasks.indexWhere((t) => t['id'] == taskId);
      if (idx != -1 && updated != null) {
        _tasks[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> rescheduleTask(int taskId, {String? newTime, String? reason}) async {
    try {
      final body = <String, dynamic>{};
      if (newTime != null) body['new_time'] = newTime;
      if (reason != null) body['reason'] = reason;

      final res = await ApiService.put('${ApiConstants.tasks}$taskId/reschedule/', body: body);
      final updated = res['task'];
      final idx = _tasks.indexWhere((t) => t['id'] == taskId);
      if (idx != -1 && updated != null) {
        _tasks[idx] = updated;
        notifyListeners();
      }
      return res as Map<String, dynamic>;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> generateRoutine() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.post(ApiConstants.generateRoutine, body: {});
      if (res is Map && res.containsKey('tasks')) {
        _tasks = res['tasks'];
      }
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
