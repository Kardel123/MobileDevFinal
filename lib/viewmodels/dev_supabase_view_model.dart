import 'package:flutter/foundation.dart';

import '../services/group_service.dart';
import '../services/task_service.dart';

/// MVVM-backed developer screen for Supabase group/task smoke tests.
class DevSupabaseViewModel extends ChangeNotifier {
  DevSupabaseViewModel(this._groupService, this._taskService);

  final GroupService _groupService;
  final TaskService _taskService;

  final List<Map<String, dynamic>> tasks = [];
  String? currentGroupId;
  String? errorMessage;
  bool loading = false;

  Future<void> createGroup(String name) async {
    if (name.trim().isEmpty) return;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final id = await _groupService.createGroup(name.trim());
      currentGroupId = id;
    } catch (e) {
      errorMessage = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> loadTasks() async {
    final gid = currentGroupId;
    if (gid == null) return;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final data = await _taskService.getTasks(gid);
      tasks.clear();
      for (final row in data) {
        tasks.add(Map<String, dynamic>.from(row as Map));
      }
    } catch (e) {
      errorMessage = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> addTask(String title) async {
    final gid = currentGroupId;
    if (gid == null || title.trim().isEmpty) return;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _taskService.createTask(
        title: title.trim(),
        groupId: gid,
      );
      await loadTasks();
    } catch (e) {
      errorMessage = e.toString();
    }
    loading = false;
    notifyListeners();
  }
}
