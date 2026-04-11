enum ProjectHubTab { active, completed, requests }

/// One row in Project hub (backed by Supabase `projects`).
class ProjectItem {
  const ProjectItem({
    required this.id,
    required this.dueDate,
    required this.details,
  });

  final String id;
  final DateTime dueDate;
  final String details;
}
