import 'package:flutter/foundation.dart';

import '../models/project_model.dart';
import '../models/student_app_context.dart';

/// Project Hub tabs and list (View: [ProjectHubView]).
class ProjectHubViewModel extends ChangeNotifier {
  ProjectHubViewModel() {
    _tab = ProjectHubTab.active;
    _projects = _neutralPlaceholderProjects();
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

  /// Rebuilds sample projects so titles/tags reflect the student’s college and enrollments.
  void applyStudentContext(StudentAppContext? ctx) {
    _projects = ctx == null ? _neutralPlaceholderProjects() : _projectsForCollege(ctx);
    notifyListeners();
  }

  /// After sign-out, before the next session loads context.
  void resetForGuest() {
    _projects = _neutralPlaceholderProjects();
    _tab = ProjectHubTab.active;
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

  static List<ProjectItem> _neutralPlaceholderProjects() {
    return const [
      ProjectItem(
        id: 'g1',
        tag: 'GROUP',
        title: 'Group milestone — check with your adviser',
        completion: 0.4,
        nextStep: 'Confirm submission format and deadline',
        avatarCount: 2,
        extraMembers: 1,
      ),
      ProjectItem(
        id: 'g2',
        tag: 'RESEARCH',
        title: 'Literature / source packet',
        completion: 0.65,
        nextStep: 'Add two peer-reviewed references',
        avatarCount: 1,
        extraMembers: 0,
      ),
      ProjectItem(
        id: 'g3',
        tag: 'PORTFOLIO',
        title: 'Portfolio or reflection set',
        completion: 0.2,
        nextStep: 'Draft outline for faculty review',
        avatarCount: 3,
        extraMembers: 0,
      ),
    ];
  }

  static List<ProjectItem> _projectsForCollege(StudentAppContext ctx) {
    final words = ctx.collegeName.trim().split(RegExp(r'\s+'));
    final short = words.isNotEmpty ? words.first : 'College';
    final codes = ctx.subjects.map((s) => s.code.toUpperCase()).toList();
    String tagAt(int i) {
      if (codes.length > i) return codes[i];
      return ['CAPSTONE', 'SYMPOSIUM', 'INITIATIVE'][i % 3];
    }

    return [
      ProjectItem(
        id: 'p1',
        tag: tagAt(0),
        title: '$short — integrative output / capstone prep',
        completion: 0.72,
        nextStep: 'Submit draft for faculty or program head review',
        avatarCount: 3,
        extraMembers: 1,
      ),
      ProjectItem(
        id: 'p2',
        tag: tagAt(1),
        title: 'Cross-team deliverable (${ctx.collegeName})',
        completion: 0.38,
        nextStep: 'Align schedules and assign section owners',
        avatarCount: 2,
        extraMembers: 0,
      ),
      ProjectItem(
        id: 'p3',
        tag: tagAt(2),
        title: '${ctx.collegeName} showcase or practicum packet',
        completion: 0.55,
        nextStep: 'Finalize poster, deck, or clinical checklist',
        avatarCount: 4,
        extraMembers: 2,
      ),
    ];
  }
}
