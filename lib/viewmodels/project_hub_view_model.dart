import 'package:flutter/foundation.dart';

import '../models/project_model.dart';

/// Project Hub tabs and list (View: [ProjectHubView]).
class ProjectHubViewModel extends ChangeNotifier {
  ProjectHubViewModel() {
    _tab = ProjectHubTab.active;
    _projects = _seed();
  }

  ProjectHubTab _tab = ProjectHubTab.active;
  late List<ProjectItem> _projects;

  ProjectHubTab get tab => _tab;
  List<ProjectItem> get projects => List.unmodifiable(_projects);

  int countFor(ProjectHubTab t) {
    switch (t) {
      case ProjectHubTab.active:
        return _projects.length;
      case ProjectHubTab.completed:
        return 0;
      case ProjectHubTab.requests:
        return 0;
    }
  }

  void setTab(ProjectHubTab value) {
    if (value == _tab) return;
    _tab = value;
    notifyListeners();
  }

  void updateNextStep(String projectId, String nextStep) {
    final trimmed = nextStep.trim();
    if (trimmed.isEmpty) return;
    _projects = _projects
        .map(
          (p) => p.id == projectId
              ? ProjectItem(
                  id: p.id,
                  tag: p.tag,
                  title: p.title,
                  completion: p.completion,
                  nextStep: trimmed,
                  avatarCount: p.avatarCount,
                  extraMembers: p.extraMembers,
                )
              : p,
        )
        .toList();
    notifyListeners();
  }

  void removeProject(String projectId) {
    _projects = _projects.where((p) => p.id != projectId).toList();
    notifyListeners();
  }

  static List<ProjectItem> _seed() {
    return const [
      ProjectItem(
        id: '1',
        tag: 'BRANDING',
        title: 'USLS Club Rebranding',
        completion: 0.75,
        nextStep: 'Finalize color palette',
        avatarCount: 3,
        extraMembers: 2,
      ),
      ProjectItem(
        id: '2',
        tag: 'DEV',
        title: '3D Game Conceptualization',
        completion: 0.32,
        nextStep: 'Database schema review',
        avatarCount: 2,
        extraMembers: 0,
      ),
      ProjectItem(
        id: '3',
        tag: 'MARKETING',
        title: 'Advertisement Campaign',
        completion: 0.9,
        nextStep: 'Copywriting sign-off',
        avatarCount: 3,
        extraMembers: 0,
      ),
    ];
  }
}
