import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/academic_task.dart';
import '../models/task_filter.dart';
import '../models/task_priority.dart';
import '../services/group_service.dart';
import '../services/task_service.dart';

/// Tasks list backed by Supabase (`tasks` + `groups` for the current user).
class TasksViewModel extends ChangeNotifier {
  TasksViewModel(this._taskService, this._groupService);

  final TaskService _taskService;
  final GroupService _groupService;

  TaskFilter _filter = TaskFilter.all;
  String? _activeGroupId;
  List<AcademicTask> _tasks = [];
  bool _loading = false;
  String? _errorMessage;

  TaskFilter get filter => _filter;
  String get semesterLabel => 'Fall Semester 2026';

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  String? get activeGroupId => _activeGroupId;

  /// All loaded tasks (ignores list filter) — for calendar due dates, etc.
  List<AcademicTask> get allTasks => List.unmodifiable(_tasks);

  List<AcademicTask> get visibleTasks {
    switch (_filter) {
      case TaskFilter.all:
        return List.unmodifiable(_tasks);
      case TaskFilter.pending:
        return _tasks
            .where((t) => t.status == AcademicTaskStatus.pending)
            .toList();
      case TaskFilter.done:
        return _tasks.where((t) => t.status == AcademicTaskStatus.done).toList();
    }
  }

  void setFilter(TaskFilter value) {
    if (value == _filter) return;
    _filter = value;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Loads the default group and tasks from Supabase. Call after sign-in or pull-to-refresh.
  Future<void> refresh() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (Supabase.instance.client.auth.currentUser == null) {
        _tasks = [];
        _activeGroupId = null;
        return;
      }

      _activeGroupId = await _groupService.ensureDefaultGroup();
      final raw = await _taskService.getTasks(_activeGroupId!);
      _tasks = [
        for (var i = 0; i < raw.length; i++)
          _mapRow(Map<String, dynamic>.from(raw[i] as Map), i),
      ];
    } catch (e) {
      _errorMessage = e.toString();
      _tasks = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Inserts a row in Supabase and reloads the list.
  Future<bool> addTask({
    required String title,
    String subject = 'GENERAL',
    TaskPriority priority = TaskPriority.med,
    DateTime? dueDate,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return false;

    try {
      if (_activeGroupId == null) {
        await refresh();
      }
      if (_activeGroupId == null) {
        _errorMessage = 'Could not load your task group.';
        notifyListeners();
        return false;
      }

      await _taskService.createTaskDetailed(
        groupId: _activeGroupId!,
        title: trimmed,
        subject: subject,
        priority: priority,
        dueDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
        status: 'pending',
      );
      await refresh();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Toggles between pending and done in the database.
  Future<void> toggleTaskDone(AcademicTask task) async {
    final next = task.status == AcademicTaskStatus.done
        ? 'pending'
        : 'done';
    try {
      await _taskService.updateTaskStatus(task.id, next);
      _tasks = _tasks
          .map(
            (t) => t.id == task.id
                ? AcademicTask(
                    id: t.id,
                    subject: t.subject,
                    title: t.title,
                    dueDate: t.dueDate,
                    priority: t.priority,
                    status: next == 'done'
                        ? AcademicTaskStatus.done
                        : AcademicTaskStatus.pending,
                  )
                : t,
          )
          .toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Replace list from a specific group (dev / advanced use).
  Future<void> loadRemoteTasks(String groupId) async {
    _activeGroupId = groupId;
    final raw = await _taskService.getTasks(groupId);
    _tasks = [
      for (var i = 0; i < raw.length; i++)
        _mapRow(Map<String, dynamic>.from(raw[i] as Map), i),
    ];
    notifyListeners();
  }

  static AcademicTask _mapRow(Map<String, dynamic> row, int index) {
    final statusRaw = (row['status'] as String?)?.toLowerCase() ?? '';
    final done = statusRaw == 'done' ||
        statusRaw == 'completed' ||
        statusRaw == 'complete';
    final status =
        done ? AcademicTaskStatus.done : AcademicTaskStatus.pending;

    DateTime due = DateTime.now().add(Duration(days: index + 1));
    final dr = row['due_date'];
    if (dr != null) {
      try {
        due = DateTime.parse(dr.toString());
      } catch (_) {}
    }

    TaskPriority priority = TaskPriority.med;
    switch ((row['priority'] as String?)?.toLowerCase()) {
      case 'high':
        priority = TaskPriority.high;
        break;
      case 'low':
        priority = TaskPriority.low;
        break;
      default:
        priority = TaskPriority.med;
    }

    return AcademicTask(
      id: row['id']?.toString() ?? 'row_$index',
      subject: (row['subject'] as String?)?.isNotEmpty == true
          ? (row['subject'] as String)
          : 'GENERAL',
      title: row['title'] as String? ?? '',
      dueDate: due,
      priority: priority,
      status: status,
    );
  }
}
