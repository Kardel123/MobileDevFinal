class CourseSchedule {
  const CourseSchedule({
    required this.id,
    required this.catalogSubjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.sessionLabel,
  });

  final String id;
  final String catalogSubjectId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String room;
  final String sessionLabel;

  static const List<String> weekdayShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  String get dayLabel =>
      (dayOfWeek >= 1 && dayOfWeek <= 7)
          ? weekdayShort[dayOfWeek - 1]
          : '?';

  String get timeRange =>
      '${_hm(startTime)} – ${_hm(endTime)}';

  static String _hm(String t) {
    if (t.length >= 5) return t.substring(0, 5);
    return t;
  }

  factory CourseSchedule.fromMap(Map<String, dynamic> m) {
    return CourseSchedule(
      id: m['id'] as String,
      catalogSubjectId: m['catalog_subject_id'] as String,
      dayOfWeek: (m['day_of_week'] as num).toInt(),
      startTime: m['start_time'] as String,
      endTime: m['end_time'] as String,
      room: m['room'] as String? ?? '',
      sessionLabel: m['session_label'] as String? ?? 'Class',
    );
  }
}
