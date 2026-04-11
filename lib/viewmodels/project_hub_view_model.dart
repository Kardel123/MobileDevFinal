import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project_model.dart';
import '../models/student_app_context.dart';
import '../services/group_service.dart';
import '../services/project_service.dart';

/// Project Hub backed by Supabase `projects` (View: [ProjectHubView]).
class ProjectHubViewModel extends ChangeNotifier {
  ProjectHubViewModel(this._groupService, this._projectService);

  final GroupService _groupService;
  final ProjectService _projectService;

  ProjectHubTab _tab = ProjectHubTab.active;
  List<ProjectItem> _projects = [];
  Map<String, int> _statusCounts = {};
  bool _loading = false;
  String? _errorMessage;

  ProjectHubTab get tab => _tab;
  List<ProjectItem> get projects => List.unmodifiable(_projects);
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  static String _statusForTab(ProjectHubTab t) {
    switch (t) {
      case ProjectHubTab.active:
        return 'Active';
      case ProjectHubTab.completed:
        return 'Completed';
      case ProjectHubTab.requests:
        return 'Request';
    }
  }

  int countFor(ProjectHubTab t) {
    switch (t) {
      case ProjectHubTab.active:
        return _statusCounts['active'] ?? 0;
      case ProjectHubTab.completed:
        return _statusCounts['completed'] ?? 0;
      case ProjectHubTab.requests:
        return _statusCounts['requests'] ?? 0;
    }
  }

  void setTab(ProjectHubTab value) {
    if (value == _tab) return;
    _tab = value;
    notifyListeners();
    refresh();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Loads projects for the current tab from Supabase.
  Future<void> refresh() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      _projects = [];
      notifyListeners();
      return;
    }

    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final groupId = await _groupService.ensureDefaultGroup();
      _statusCounts = await _projectService.getProjectCounts(groupId);
      final status = _statusForTab(_tab);
      final raw = await _projectService.getProjectsByStatus(groupId, status);
      _projects = [
        for (var i = 0; i < raw.length; i++)
          _mapRow(Map<String, dynamic>.from(raw[i] as Map)),
      ];
    } catch (e) {
      _errorMessage = e.toString();
      _projects = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void applyStudentContext(StudentAppContext? ctx) {
    if (ctx == null) {
      resetForGuest();
      return;
    }
    refresh();
  }

  void resetForGuest() {
    _projects = [];
    _tab = ProjectHubTab.active;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> addProject({
    required DateTime dueDate,
    required String details,
  }) async {
    if (details.trim().isEmpty) return false;

    try {
      final groupId = await _groupService.ensureDefaultGroup();
      await _projectService.createProject(
        groupId: groupId,
        dueDate: dueDate,
        details: details.trim(),
      );
      if (_tab == ProjectHubTab.active) {
        await refresh();
      } else {
        _tab = ProjectHubTab.active;
        await refresh();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProjectDetails({
    required String projectId,
    required DateTime dueDate,
    required String details,
  }) async {
    if (details.trim().isEmpty) return;
    final d = DateTime(dueDate.year, dueDate.month, dueDate.day);
    try {
      await _projectService.updateProject(
        projectId: projectId,
        dueDate: d,
        nextStep: details.trim(),
        title: ProjectService.shortTitleFromDetails(details.trim(), d),
      );
      await refresh();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeProject(String projectId) async {
    try {
      await _projectService.deleteProject(projectId);
      await refresh();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  static ProjectItem _mapRow(Map<String, dynamic> row) {
    final c = ProjectService.parseProjectContent(row);
    return ProjectItem(
      id: row['id']?.toString() ?? '',
      dueDate: c.due,
      details: c.details,
    );
  }
}
