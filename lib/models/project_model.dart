enum ProjectHubTab { active, completed, requests }

class ProjectItem {
  const ProjectItem({
    required this.id,
    required this.tag,
    required this.title,
    required this.completion,
    required this.nextStep,
    required this.avatarCount,
    required this.extraMembers,
  });

  final String id;
  final String tag;
  final String title;
  final double completion;
  final String nextStep;
  final int avatarCount;
  final int extraMembers;
}
