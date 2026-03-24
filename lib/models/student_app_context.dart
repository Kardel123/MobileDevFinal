import 'package:flutter/material.dart';

import 'college.dart';

/// One recurring class meeting (same every week) for calendar expansion.
class WeeklyClassSlot {
  const WeeklyClassSlot({
    required this.dayOfWeek,
    required this.startHour,
    required this.endHour,
    required this.title,
    required this.subtitle,
  });

  /// 1 = Monday … 7 = Sunday (matches [DateTime.weekday]).
  final int dayOfWeek;
  final double startHour;
  final double endHour;
  final String title;
  final String subtitle;
}

class EnrolledSubjectRef {
  const EnrolledSubjectRef({
    required this.id,
    required this.name,
    required this.code,
  });

  final String id;
  final String name;
  final String code;
}

/// Loaded from `student_profiles` + enrollments + catalog (for dashboard, calendar, profile).
class StudentAppContext {
  const StudentAppContext({
    required this.collegeId,
    required this.collegeName,
    required this.primaryHex,
    required this.accentHex,
    required this.yearLevel,
    this.fullName,
    required this.subjects,
    required this.weeklySlots,
  });

  final String collegeId;
  final String collegeName;
  final String primaryHex;
  final String accentHex;
  final String yearLevel;
  final String? fullName;
  final List<EnrolledSubjectRef> subjects;
  final List<WeeklyClassSlot> weeklySlots;

  Color get primaryColor => College.hexToColor(primaryHex);

  Color get accentColor => College.hexToColor(accentHex);

  /// Shown under the user name (e.g. college + year).
  String get programLine {
    final y = yearLevel.trim().isEmpty ? 'Year not set' : yearLevel.trim();
    return '$collegeName • $y';
  }

  String get enrolledSubjectsSummary {
    if (subjects.isEmpty) return 'No subjects selected';
    return subjects.map((s) => s.code).join(', ');
  }
}
