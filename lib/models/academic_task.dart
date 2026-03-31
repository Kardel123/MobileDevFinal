import 'task_priority.dart';

enum AcademicTaskStatus { pending, done }

class AcademicTask {
  const AcademicTask({
    required this.id,
    required this.subject,
    required this.title,
    required this.dueDate,
    required this.priority,
    required this.status,
    this.isPinned = false,
    this.progressPercent = 0,
  });

  final String id;
  final String subject;
  final String title;
  final DateTime dueDate;
  final TaskPriority priority;
  final AcademicTaskStatus status;
  final bool isPinned;
  /// 0–100; independent of done status (for in-progress work).
  final int progressPercent;
}
