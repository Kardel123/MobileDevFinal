/// Origin of a block on the weekly calendar (for delete / suppress behavior).
enum CalendarEventKind {
  /// Added via the + dialog.
  userAdded,

  /// Derived from a task due date.
  taskDue,

  /// From enrollment weekly slots.
  enrollment,
}

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.occurrenceDate,
    required this.startHour,
    required this.endHour,
    this.mint = false,
    required this.kind,
    this.taskId,
  });

  final String id;
  final DateTime occurrenceDate;
  final String title;
  final String subtitle;
  final double startHour;
  final double endHour;
  final bool mint;
  final CalendarEventKind kind;

  /// When [kind] is [CalendarEventKind.taskDue], the Supabase task id.
  final String? taskId;
}
