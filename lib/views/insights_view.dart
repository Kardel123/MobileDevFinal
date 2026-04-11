import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/academic_task.dart';
import '../services/group_service.dart';
import '../services/project_service.dart';
import '../theme/app_colors.dart';
import '../viewmodels/tasks_view_model.dart';

/// Analytics-style summary: tasks + projects in card sections.
class InsightsView extends StatefulWidget {
  const InsightsView({super.key});

  @override
  State<InsightsView> createState() => _InsightsViewState();
}

class _InsightsViewState extends State<InsightsView> {
  List<Map<String, dynamic>> _projectRows = [];
  bool _projectsLoading = true;
  String? _projectsError;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProjects();
    });
  }

  Future<void> _loadProjects() async {
    if (!mounted) return;
    setState(() {
      _projectsLoading = true;
      _projectsError = null;
    });
    try {
      final gs = context.read<GroupService>();
      final ps = context.read<ProjectService>();
      final groupId = await gs.ensureDefaultGroup();
      final raw = await ps.getProjects(groupId);
      if (!mounted) return;
      setState(() {
        _projectRows = [
          for (final r in raw) Map<String, dynamic>.from(r as Map),
        ];
        _projectsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _projectsError = e.toString();
        _projectRows = [];
        _projectsLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await context.read<TasksViewModel>().refresh();
    await _loadProjects();
  }

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
    final overdue =
        pending.where((t) => _dateOnly(t.dueDate).isBefore(today)).length;
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
          _InsetTile(
            leading: Icon(
              t.isPinned ? Icons.push_pin : Icons.task_alt_outlined,
              color: AppColors.primary,
              size: 22,
            ),
            title: t.title,
            subtitle: '${t.subject} · ${DateFormat.MMMd().format(t.dueDate)}',
            trailing: Text(
              '${t.progressPercent}%',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      }
    }

    final activeP = _projectRows.where((r) => r['status'] == 'Active').length;
    final completedP =
        _projectRows.where((r) => r['status'] == 'Completed').length;
    final requestP =
        _projectRows.where((r) => r['status'] == 'Request').length;

    final projectPreview = <Widget>[];
    final sorted = List<Map<String, dynamic>>.from(_projectRows)
      ..sort((a, b) {
        final ca = ProjectService.parseProjectContent(a);
        final cb = ProjectService.parseProjectContent(b);
        return ca.due.compareTo(cb.due);
      });
    for (final row in sorted.take(5)) {
      final c = ProjectService.parseProjectContent(row);
      final status = (row['status'] as String?) ?? '';
      var comp = 0;
      final cp = row['completion'];
      if (cp is int) {
        comp = cp.clamp(0, 100);
      } else if (cp is num) {
        comp = cp.round().clamp(0, 100);
      }
      final title = ProjectService.shortTitleFromDetails(c.details, c.due);
      projectPreview.add(
        _InsetTile(
          leading: Icon(
            Icons.folder_outlined,
            color: AppColors.primaryDark,
            size: 22,
          ),
          title: title,
          subtitle:
              '$status · due ${DateFormat.yMMMd().format(c.due)}',
          trailing: Text(
            '$comp%',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          bottom: Padding(
            padding: const EdgeInsets.only(left: 40, top: 8, right: 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: comp / 100.0,
                minHeight: 6,
                backgroundColor: AppColors.mintSoft,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        physics: const AlwaysScrollableScrollPhysics(),
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
            'Tasks and projects for your group',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          _InsightSectionCard(
            isDark: isDark,
            title: 'Tasks',
            subtitle: 'Progress and workload',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProgressRing(
                  label: 'Completion',
                  value: completionRate,
                  subtitle: '$done of ${tasks.length} tasks done',
                ),
                const SizedBox(height: 16),
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
                        color: overdue > 0
                            ? Colors.orange.shade800
                            : AppColors.mint,
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
                const SizedBox(height: 20),
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
                  const SizedBox(height: 20),
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
            ),
          ),
          const SizedBox(height: 16),
          _InsightSectionCard(
            isDark: isDark,
            title: 'Projects',
            subtitle: 'Hub snapshot (all statuses)',
            child: _projectsLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _projectsError != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _projectsError!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.play_circle_outline_rounded,
                                  label: 'Active',
                                  value: '$activeP',
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.check_circle_outline_rounded,
                                  label: 'Done',
                                  value: '$completedP',
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.mail_outline_rounded,
                                  label: 'Requests',
                                  value: '$requestP',
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.folder_open_rounded,
                                  label: 'Total',
                                  value: '${_projectRows.length}',
                                  color: AppColors.mint,
                                ),
                              ),
                            ],
                          ),
                          if (projectPreview.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Text(
                              'Upcoming by due date',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            ...projectPreview,
                          ] else ...[
                            const SizedBox(height: 16),
                            Text(
                              'No projects yet. Add some in Project hub.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

/// Rounded “page box” container for a section of Insights.
class _InsightSectionCard extends StatelessWidget {
  const _InsightSectionCard({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final bool isDark;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: isDark ? 0 : 2,
      shadowColor: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(22),
      color: isDark
          ? Theme.of(context).colorScheme.surfaceContainerHigh
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.mintSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    title == 'Tasks'
                        ? Icons.task_alt_rounded
                        : Icons.folder_special_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _InsetTile extends StatelessWidget {
  const _InsetTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.bottom,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.mintSoft.withValues(alpha: 0.65),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading,
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  trailing,
                ],
              ),
              bottom ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
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
      borderRadius: BorderRadius.circular(16),
      color: isDark
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : AppColors.mintSoft.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
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
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: AppColors.mintSoft.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(width: 16),
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
