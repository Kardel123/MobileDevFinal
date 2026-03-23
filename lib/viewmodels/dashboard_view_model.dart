import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dashboard_schedule_slot.dart';
import '../models/deadline_item.dart';
import '../theme/app_colors.dart';
import '../utils/auth_user_display.dart';

/// State for the home dashboard (View: [DashboardView]).
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel() {
    _schedule = _seedSchedule();
    _deadlines = _seedDeadlines();
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
    notifyListeners();
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

  static List<DeadlineItem> _seedDeadlines() {
    return const [
      DeadlineItem(
        title: 'Final Project Proposal',
        subjectLabel: 'Subject: Mobile Computing',
        dueLabel: 'Due in 2 days',
        progress: 0.8,
        urgency: DeadlineUrgency.soon,
      ),
      DeadlineItem(
        title: 'Database Schema Design',
        subjectLabel: 'Subject: Database Systems',
        dueLabel: 'Due Tomorrow',
        progress: 0.3,
        urgency: DeadlineUrgency.tomorrow,
      ),
      DeadlineItem(
        title: 'Community Outreach Essay',
        subjectLabel: 'Subject: Religion 3',
        dueLabel: 'Due in 5 days',
        progress: 0.1,
        urgency: DeadlineUrgency.later,
      ),
    ];
  }
}
