import 'package:flutter/material.dart';

class DashboardScheduleSlot {
  const DashboardScheduleSlot({
    required this.timeLabel,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String timeLabel;
  final String title;
  final String subtitle;
  final Color accent;
}
