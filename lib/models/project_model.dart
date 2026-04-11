enum ProjectHubTab { active, completed, requests }

/// One row in Project hub (backed by Supabase `projects`).
class ProjectItem {
  const ProjectItem({
    required this.id,
    required this.dueDate,
    required this.details,
    this.completionPercent = 0,
  });

  final String id;
  final DateTime dueDate;
  final String details;
  /// 0–100, from Supabase `projects.completion`.
  final int completionPercent;
}
