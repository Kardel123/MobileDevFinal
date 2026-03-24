import 'package:flutter/foundation.dart';

import '../models/academic_task.dart';
import '../models/calendar_event.dart';
import '../models/student_app_context.dart';

/// Week range, selection, and events for the weekly calendar View.
class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel() {
    final now = DateTime.now();
    _weekStart = _dateOnly(_mondayOf(now));
    _selectedDay = _dateOnly(now);
  }

  late DateTime _weekStart;
  late DateTime _selectedDay;

  /// Events created via the calendar “Add” dialog (persists across week changes).
  final List<CalendarEvent> _userEvents = [];

  /// Last synced from [TasksViewModel]; due dates rendered as calendar blocks.
  List<AcademicTask> _syncedTasks = [];
  String _taskSyncSig = '';

  /// Recurring class meetings from enrollments (replaces demo blocks when non-empty).
  List<WeeklyClassSlot> _enrollmentWeeklySlots = [];

  DateTime get weekStart => _weekStart;
  DateTime get selectedDay => _selectedDay;

  /// Demo schedule for the **visible** week + user-added events + task due dates.
  List<CalendarEvent> get eventsForVisibleWeek {
    final end = _weekEnd;
    final userInWeek = _userEvents.where((e) {
      final d = _dateOnly(e.occurrenceDate);
      return !d.isBefore(_weekStart) && !d.isAfter(end);
    }).toList();
    final fromTasks = _calendarEventsFromTasks(_weekStart, end, _syncedTasks);
    if (_enrollmentWeeklySlots.isNotEmpty) {
      final fromEnroll =
          _eventsFromEnrollmentWeek(_weekStart, _enrollmentWeeklySlots);
      return [...fromEnroll, ...userInWeek, ...fromTasks];
    }
    final demo = _seedEventsForWeek(_weekStart);
    return [...demo, ...userInWeek, ...fromTasks];
  }

  void setEnrollmentWeeklySlots(List<WeeklyClassSlot> slots) {
    _enrollmentWeeklySlots = List<WeeklyClassSlot>.from(slots);
    notifyListeners();
  }

  void clearEnrollmentSlots() {
    _enrollmentWeeklySlots = [];
    notifyListeners();
  }

  /// Call when [TasksViewModel] finishes loading or mutating tasks.
  void syncTaskDeadlines(List<AcademicTask> tasks) {
    final sig = tasks
        .map((t) => '${t.id}|${t.dueDate.toIso8601String()}|${t.status}|${t.title}')
        .join('\u001e');
    if (sig == _taskSyncSig) return;
    _taskSyncSig = sig;
    _syncedTasks = List<AcademicTask>.from(tasks);
    notifyListeners();
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));

  /// Column 0–6 for the selected day within the visible week, or null if outside.
  int? get selectedColumnIndex {
    final idx = _dateOnly(_selectedDay).difference(_weekStart).inDays;
    if (idx < 0 || idx > 6) return null;
    return idx;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _mondayOf(DateTime d) {
    final weekday = d.weekday;
    return _dateOnly(d).subtract(Duration(days: weekday - 1));
  }

  /// Column index (0–6) for [event] in the current visible week.
  int columnForEvent(CalendarEvent event) {
    return _dateOnly(event.occurrenceDate).difference(_weekStart).inDays;
  }

  String get rangeLabel {
    final end = _weekEnd;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m1 = months[_weekStart.month - 1];
    final m2 = months[end.month - 1];
    return '$m1 ${_weekStart.day} - $m2 ${end.day}, ${_weekStart.year}';
  }

  List<DateTime> get weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  void selectDay(DateTime day) {
    final d = _dateOnly(day);
    if (d == _selectedDay) return;
    _selectedDay = d;
    notifyListeners();
  }

  void goToday() {
    final now = DateTime.now();
    _weekStart = _mondayOf(now);
    _selectedDay = _dateOnly(now);
    notifyListeners();
  }

  void previousWeek() {
    _weekStart = _weekStart.subtract(const Duration(days: 7));
    _selectedDay = _alignSelectedToVisibleWeek();
    notifyListeners();
  }

  void nextWeek() {
    _weekStart = _weekStart.add(const Duration(days: 7));
    _selectedDay = _alignSelectedToVisibleWeek();
    notifyListeners();
  }

  /// Keeps the same weekday (Mon–Sun) when changing weeks.
  DateTime _alignSelectedToVisibleWeek() {
    final wd = _selectedDay.weekday;
    return _weekStart.add(Duration(days: wd - 1));
  }

  void addEvent({
    required String title,
    required String subtitle,
    required DateTime day,
    required double startHour,
    required double endHour,
    bool mint = false,
  }) {
    final d = _dateOnly(day);
    _userEvents.add(
      CalendarEvent(
        title: title,
        subtitle: subtitle,
        occurrenceDate: d,
        startHour: startHour,
        endHour: endHour,
        mint: mint,
      ),
    );
    notifyListeners();
  }

  static List<CalendarEvent> _eventsFromEnrollmentWeek(
    DateTime monday,
    List<WeeklyClassSlot> slots,
  ) {
    return [
      for (final s in slots)
        CalendarEvent(
          title: s.title,
          subtitle: s.subtitle,
          occurrenceDate: monday.add(Duration(days: s.dayOfWeek - 1)),
          startHour: s.startHour,
          endHour: s.endHour,
          mint: false,
        ),
    ];
  }

  static List<CalendarEvent> _calendarEventsFromTasks(
    DateTime weekStart,
    DateTime weekEnd,
    List<AcademicTask> tasks,
  ) {
    final byDay = <DateTime, List<AcademicTask>>{};
    for (final t in tasks) {
      if (t.status == AcademicTaskStatus.done) continue;
      final d = _dateOnly(t.dueDate);
      if (d.isBefore(weekStart) || d.isAfter(weekEnd)) continue;
      byDay.putIfAbsent(d, () => []).add(t);
    }
    final out = <CalendarEvent>[];
    for (final entry in byDay.entries) {
      final list = [...entry.value]
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      for (var i = 0; i < list.length; i++) {
        final t = list[i];
        final start = (14.0 + i * 0.55).clamp(8.0, 16.2);
        final endH = (start + 0.85).clamp(start + 0.5, 17.0);
        out.add(
          CalendarEvent(
            title: t.title,
            subtitle: 'Due • ${t.subject}',
            occurrenceDate: entry.key,
            startHour: start,
            endHour: endH,
            mint: true,
          ),
        );
      }
    }
    return out;
  }

  static List<CalendarEvent> _seedEventsForWeek(DateTime monday) {
    DateTime d(int offset) => monday.add(Duration(days: offset));

    return [
      CalendarEvent(
        title: 'Data Science 101',
        subtitle: 'Rm 402 • 09:00',
        occurrenceDate: d(0),
        startHour: 9,
        endHour: 10.5,
      ),
      CalendarEvent(
        title: 'Library Session',
        subtitle: 'Calculus Review',
        occurrenceDate: d(0),
        startHour: 14,
        endHour: 15.5,
        mint: true,
      ),
      CalendarEvent(
        title: 'Economics II',
        subtitle: 'Lecture Hall A',
        occurrenceDate: d(1),
        startHour: 11,
        endHour: 12.5,
      ),
      CalendarEvent(
        title: 'Data Science 101',
        subtitle: 'Rm 402',
        occurrenceDate: d(2),
        startHour: 9,
        endHour: 10.5,
      ),
      CalendarEvent(
        title: 'Economics II',
        subtitle: 'Lecture Hall A',
        occurrenceDate: d(3),
        startHour: 11,
        endHour: 12.5,
      ),
      CalendarEvent(
        title: 'Computer Lab',
        subtitle: 'Bldg 5',
        occurrenceDate: d(3),
        startHour: 15,
        endHour: 16.5,
      ),
    ];
  }
}
