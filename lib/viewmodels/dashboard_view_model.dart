import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/academic_task.dart';
import '../models/dashboard_schedule_slot.dart';
import '../models/deadline_item.dart';
import '../models/student_app_context.dart';
import '../models/task_priority.dart';
import '../theme/app_colors.dart';
import '../utils/auth_user_display.dart';

/// State for the home dashboard (View: [DashboardView]).
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel() {
    _schedule = _seedSchedule();
    _deadlines = [];
  }

  String portalTitle = 'USLS Portal';
  String userName = 'Student';
  String userSubtitle = 'BS Information Technology • Year 3';
  String userInitials = '?';

  late List<DashboardScheduleSlot> _schedule;
  late List<DeadlineItem> _deadlines;

  List<DashboardScheduleSlot> get todaySchedule => List.unmodifiable(_schedule);
  List<DeadlineItem> get upcomingDeadlines => List.unmodifiable(_deadlines);
  int get activeDeadlineCount => _deadlines.length;

  void applyAuthUser(User? user) {
    final d = AuthUserDisplay.fromUser(user);
    userName = d.displayName;
    userInitials = d.initials;
    if (d.programLine != null && d.programLine!.isNotEmpty) {
      userSubtitle = d.programLine!;
    }
    notifyListeners();
  }

  void resetToGuest() {
    userName = 'Student';
    userSubtitle = 'BS Information Technology • Year 3';
    userInitials = '?';
    _schedule = _seedSchedule();
    _deadlines = [];
    notifyListeners();
  }

  /// After loading [StudentAppContext] from Supabase (college, year, today’s classes).
  void applyStudentContext(StudentAppContext ctx) {
    userSubtitle = ctx.programLine;
    if (ctx.fullName != null && ctx.fullName!.isNotEmpty) {
      userName = ctx.fullName!;
      userInitials = AuthUserDisplay.initialsFrom(ctx.fullName!, '');
    }
    final wd = DateTime.now().weekday;
    final todaySlots = ctx.weeklySlots
        .where((s) => s.dayOfWeek == wd)
        .toList()
      ..sort((a, b) => a.startHour.compareTo(b.startHour));
    if (todaySlots.isEmpty) {
      _schedule = [
        DashboardScheduleSlot(
          timeLabel: '—',
          title: ctx.subjects.isEmpty ? 'No enrollments' : 'No classes today',
          subtitle: ctx.subjects.isEmpty
              ? 'Add subjects during registration when your load is finalized.'
              : 'No catalog meetings fall on this weekday.',
          accent: ctx.primaryColor,
        ),
      ];
    } else {
      _schedule = [
        for (final s in todaySlots)
          DashboardScheduleSlot(
            timeLabel: _formatWeeklySlotTimeRange(s),
            title: s.title,
            subtitle: s.subtitle,
            accent: ctx.primaryColor,
          ),
      ];
    }
    notifyListeners();
  }

  /// Keeps the dashboard deadline list in sync with the task list.
  void syncDeadlinesFromTasks(List<AcademicTask> tasks) {
    final pending = tasks
        .where((t) => t.status != AcademicTaskStatus.done)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    if (pending.isEmpty) {
      _deadlines = [];
    } else {
      _deadlines = pending.take(6).map(_deadlineFromTask).toList();
    }
    notifyListeners();
  }

  static String _formatWeeklySlotTimeRange(WeeklyClassSlot s) {
    return '${_fmtHour(s.startHour)} – ${_fmtHour(s.endHour)}';
  }

  static String _fmtHour(double h) {
    final hh = h.floor().clamp(0, 23).toInt();
    final mm = ((h - h.floor()) * 60).round().clamp(0, 59).toInt();
    final t = TimeOfDay(hour: hh, minute: mm);
    final h12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h12:${mm.toString().padLeft(2, '0')} $period';
  }

  static DeadlineItem _deadlineFromTask(AcademicTask t) {
    final now = DateTime.now();
    final d = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = d.difference(today).inDays;
    late String dueLabel;
    late DeadlineUrgency urgency;
    if (diff < 0) {
      dueLabel = 'Overdue';
      urgency = DeadlineUrgency.tomorrow;
    } else if (diff == 0) {
      dueLabel = 'Due today';
      urgency = DeadlineUrgency.tomorrow;
    } else if (diff == 1) {
      dueLabel = 'Due tomorrow';
      urgency = DeadlineUrgency.tomorrow;
    } else {
      dueLabel = 'Due in $diff days';
      urgency = diff <= 3 ? DeadlineUrgency.soon : DeadlineUrgency.later;
    }
    return DeadlineItem(
      title: t.title,
      subjectLabel: 'Subject: ${t.subject}',
      dueLabel: dueLabel,
      progress: _progressForPriority(t.priority),
      urgency: urgency,
    );
  }

  static double _progressForPriority(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return 0.2;
      case TaskPriority.med:
        return 0.45;
      case TaskPriority.low:
        return 0.7;
    }
  }

  static List<DashboardScheduleSlot> _seedSchedule() {
    return [
      DashboardScheduleSlot(
        timeLabel: '08:30 AM',
        title: 'Web Development 2',
        subtitle: 'Room 302 • Lab',
        accent: AppColors.primary,
      ),
      DashboardScheduleSlot(
        timeLabel: '11:00 AM',
        title: 'Ethics in Computing',
        subtitle: 'Room 105 • Lecture',
        accent: const Color(0xFF42A5F5),
      ),
    ];
  }

}
