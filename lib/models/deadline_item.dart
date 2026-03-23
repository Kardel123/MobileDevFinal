import 'package:flutter/material.dart';

enum DeadlineUrgency { soon, tomorrow, later }

class DeadlineItem {
  const DeadlineItem({
    required this.title,
    required this.subjectLabel,
    required this.dueLabel,
    required this.progress,
    required this.urgency,
  });

  final String title;
  final String subjectLabel;
  final String dueLabel;
  final double progress;
  final DeadlineUrgency urgency;

  Color dueColor(ColorScheme scheme) {
    switch (urgency) {
      case DeadlineUrgency.soon:
        return const Color(0xFF00695C);
      case DeadlineUrgency.tomorrow:
        return const Color(0xFFFF9800);
      case DeadlineUrgency.later:
        return const Color(0xFF757575);
    }
  }
}
