import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/academic_task.dart';
import '../theme/app_colors.dart';
import '../viewmodels/tasks_view_model.dart';

/// Analytics-style summary: counts, overdue, progress, upcoming window.
class InsightsView extends StatelessWidget {
  const InsightsView({super.key});

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TasksViewModel>();
    final tasks = vm.allTasks;
    final now = DateTime.now();
    final today = _dateOnly(now);

    final pending =
        tasks.where((t) => t.status != AcademicTaskStatus.done).toList();
    final done =
        tasks.where((t) => t.status == AcademicTaskStatus.done).length;
    final overdue = pending.where((t) => _dateOnly(t.dueDate).isBefore(today)).length;
    final pinned = pending.where((t) => t.isPinned).length;

    final upcoming = pending.where((t) {
      final d = _dateOnly(t.dueDate);
      final diff = d.difference(today).inDays;
      return diff >= 0 && diff <= 7;
    }).length;

    double avgProgress = 0;
    if (pending.isNotEmpty) {
      final sum = pending.fold<int>(0, (a, t) => a + t.progressPercent);
      avgProgress = sum / pending.length;
    }

    final completionRate = tasks.isEmpty ? 0.0 : done / tasks.length;

    final nextDeadlineTiles = <Widget>[];
    if (pending.isNotEmpty) {
      final next = List<AcademicTask>.from(pending)
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      for (final t in next.take(6)) {
        nextDeadlineTiles.add(
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                t.isPinned ? Icons.push_pin : Icons.task_alt_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                t.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${t.subject} • ${DateFormat.MMMd().format(t.dueDate)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                '${t.progressPercent}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        Text(
          'Insights',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.navyText,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Progress and workload for your active group',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
        _ProgressRing(
          label: 'Completion',
          value: completionRate,
          subtitle: '$done of ${tasks.length} tasks done',
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.pending_actions_rounded,
                label: 'Pending',
                value: '${pending.length}',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.warning_amber_rounded,
                label: 'Overdue',
                value: '$overdue',
                color: overdue > 0 ? Colors.orange.shade800 : AppColors.mint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.push_pin_rounded,
                label: 'Pinned',
                value: '$pinned',
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.date_range_rounded,
                label: 'Due (7d)',
                value: '$upcoming',
                color: AppColors.primaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Average progress (pending)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: avgProgress / 100.0,
            minHeight: 12,
            backgroundColor: AppColors.mintSoft,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${avgProgress.round()}%',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            fontSize: 16,
          ),
        ),
        if (nextDeadlineTiles.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(
            'Next deadlines',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          ...nextDeadlineTiles,
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      color: isDark
          ? Theme.of(context).colorScheme.surfaceContainerHigh
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final double value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round().clamp(0, 100);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: value.clamp(0.0, 1.0),
                    strokeWidth: 8,
                    backgroundColor: AppColors.mintSoft,
                    color: AppColors.primary,
                  ),
                  Center(
                    child: Text(
                      '$pct%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.navyText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
