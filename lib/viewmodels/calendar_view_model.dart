import 'package:flutter/foundation.dart';

import '../models/academic_task.dart';
import '../models/calendar_event.dart' show CalendarEvent, CalendarEventKind;
import '../models/student_app_context.dart';

/// Week grid vs focused day list (agenda).
enum CalendarLayoutMode { weekGrid, dayAgenda }

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

  /// Hidden tile ids (demo, task due, enrollment, or user — after removal).
  final Set<String> _hiddenEventIds = {};

  /// Last synced from [TasksViewModel]; due dates rendered as calendar blocks.
  List<AcademicTask> _syncedTasks = [];
  String _taskSyncSig = '';

  /// Recurring class meetings from enrollments (replaces demo blocks when non-empty).
  List<WeeklyClassSlot> _enrollmentWeeklySlots = [];

  CalendarLayoutMode _layoutMode = CalendarLayoutMode.weekGrid;

  DateTime get weekStart => _weekStart;
  DateTime get selectedDay => _selectedDay;

  CalendarLayoutMode get layoutMode => _layoutMode;

  void setLayoutMode(CalendarLayoutMode mode) {
    if (mode == _layoutMode) return;
    _layoutMode = mode;
    notifyListeners();
  }

  /// Demo schedule for the **visible** week + user-added events + task due dates.
  List<CalendarEvent> get eventsForVisibleWeek {
    final end = _weekEnd;
    final userInWeek = _userEvents.where((e) {
      final d = _dateOnly(e.occurrenceDate);
      return !d.isBefore(_weekStart) && !d.isAfter(end);
    }).toList();
    final fromTasks = _calendarEventsFromTasks(_weekStart, end, _syncedTasks);
    List<CalendarEvent> merged;
    if (_enrollmentWeeklySlots.isNotEmpty) {
      final fromEnroll =
          _eventsFromEnrollmentWeek(_weekStart, _enrollmentWeeklySlots);
      merged = [...fromEnroll, ...userInWeek, ...fromTasks];
    } else {
      // No fake "demo" blocks — they repeated every week with the same IDs and
      // looked static; hiding a demo also hid it forever on every week (bug).
      merged = [...userInWeek, ...fromTasks];
    }
    return merged.where((e) => !_hiddenEventIds.contains(e.id)).toList();
  }

  /// Events on [selectedDay] (classes, user events, task due times) within the visible week.
  List<CalendarEvent> get eventsForSelectedDay {
    final d = _dateOnly(_selectedDay);
    final list = eventsForVisibleWeek
        .where((e) => _dateOnly(e.occurrenceDate) == d)
        .toList();
    list.sort((a, b) {
      final c = a.startHour.compareTo(b.startHour);
      if (c != 0) return c;
      return a.title.compareTo(b.title);
    });
    return list;
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
        .map(
          (t) =>
              '${t.id}|${t.dueDate.toIso8601String()}|${t.status}|${t.title}|${t.isPinned}|${t.progressPercent}',
        )
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
    if (_weekStart.month == end.month && _weekStart.year == end.year) {
      return '$m1 ${_weekStart.day} – ${end.day}, ${_weekStart.year}';
    }
    if (_weekStart.year == end.year) {
      return '$m1 ${_weekStart.day} – $m2 ${end.day}, ${_weekStart.year}';
    }
    return '$m1 ${_weekStart.day}, ${_weekStart.year} – $m2 ${end.day}, ${end.year}';
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
    _pruneStaleHiddenEventIds();
    notifyListeners();
  }

  static String _weekKeyForMonday(DateTime monday) {
    final d = _dateOnly(monday);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Drops hidden ids from other weeks so demo/enrollment hides do not persist forever.
  void _pruneStaleHiddenEventIds() {
    final key = _weekKeyForMonday(_weekStart);
    _hiddenEventIds.removeWhere(
      (id) =>
          id.startsWith('demo-') ||
          (id.startsWith('enroll-') && !id.contains(key)),
    );
  }

  void previousWeek() {
    _weekStart = _weekStart.subtract(const Duration(days: 7));
    _selectedDay = _alignSelectedToVisibleWeek();
    _pruneStaleHiddenEventIds();
    notifyListeners();
  }

  void nextWeek() {
    _weekStart = _weekStart.add(const Duration(days: 7));
    _selectedDay = _alignSelectedToVisibleWeek();
    _pruneStaleHiddenEventIds();
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
    final id = 'user-${DateTime.now().microsecondsSinceEpoch}';
    _userEvents.add(
      CalendarEvent(
        id: id,
        title: title,
        subtitle: subtitle,
        occurrenceDate: d,
        startHour: startHour,
        endHour: endHour,
        mint: mint,
        kind: CalendarEventKind.userAdded,
      ),
    );
    notifyListeners();
  }

  /// Removes a tile from the calendar (user event or suppresses demo/task/enrollment).
  void removeEvent(String eventId) {
    _userEvents.removeWhere((e) => e.id == eventId);
    _hiddenEventIds.add(eventId);
    notifyListeners();
  }

  static List<CalendarEvent> _eventsFromEnrollmentWeek(
    DateTime monday,
    List<WeeklyClassSlot> slots,
  ) {
    final wk = _weekKeyForMonday(monday);
    return [
      for (var i = 0; i < slots.length; i++)
        CalendarEvent(
          id: 'enroll-$wk-$i-${slots[i].title.hashCode}',
          title: slots[i].title,
          subtitle: slots[i].subtitle,
          occurrenceDate: monday.add(Duration(days: slots[i].dayOfWeek - 1)),
          startHour: slots[i].startHour,
          endHour: slots[i].endHour,
          mint: false,
          kind: CalendarEventKind.enrollment,
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
            id: 'task-${t.id}',
            title: t.title,
            subtitle: 'Due • ${t.subject}',
            occurrenceDate: entry.key,
            startHour: start,
            endHour: endH,
            mint: true,
            kind: CalendarEventKind.taskDue,
            taskId: t.id,
          ),
        );
      }
    }
    return out;
  }

}
