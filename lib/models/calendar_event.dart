class CalendarEvent {
  const CalendarEvent({
    required this.title,
    required this.subtitle,
    required this.occurrenceDate,
    required this.startHour,
    required this.endHour,
    this.mint = false,
  });

  /// Calendar day this block appears on (time-of-day ignored for placement).
  final DateTime occurrenceDate;
  final String title;
  final String subtitle;
  final double startHour;
  final double endHour;
  final bool mint;
}
