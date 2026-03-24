import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/deadline_item.dart';
import '../models/student_app_context.dart';
import '../models/task_priority.dart';
import '../theme/app_colors.dart';
import '../viewmodels/academics_view_model.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../viewmodels/main_shell_view_model.dart';
import '../viewmodels/profile_view_model.dart';
import '../viewmodels/student_context_view_model.dart';
import '../viewmodels/tasks_view_model.dart';
import '../widgets/profile_avatar.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final profile = context.watch<ProfileViewModel>();
    final stud = context.watch<StudentContextViewModel>().context;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primary = stud?.primaryColor ?? AppColors.primary;
    final accent = stud?.accentColor ?? AppColors.primaryLight;
    final surfaceTint = Color.lerp(primary, isDark ? Colors.black : Colors.white, isDark ? 0.82 : 0.92)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                vm: vm,
                photoBytes: profile.profilePhotoBytes,
                initials: profile.initials,
                collegeName: stud?.collegeName,
                primary: primary,
                accent: accent,
              ),
              Transform.translate(
                offset: const Offset(0, -18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ScheduleCard(
                    vm: vm,
                    primary: primary,
                    accent: accent,
                    surfaceTint: surfaceTint,
                    onViewAll: () =>
                        context.read<MainShellViewModel>().selectTab(1),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionPill(
                        onPressed: () => _showAddTaskFlow(context),
                        icon: Icons.add_task_rounded,
                        label: 'Add task',
                        background: primary,
                        foreground: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionPill(
                        onPressed: () => _showGradesSheet(context, stud),
                        icon: Icons.assignment_turned_in_outlined,
                        label: 'Grades',
                        background: Colors.transparent,
                        foreground: primary,
                        borderColor: primary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Upcoming deadlines',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyText,
                            letterSpacing: -0.2,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.2 : 0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        vm.upcomingDeadlines.isEmpty
                            ? 'FROM TASKS'
                            : '${vm.activeDeadlineCount} active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (vm.upcomingDeadlines.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _DeadlinesEmptyState(
                    primary: primary,
                    accent: accent,
                    onAddTask: () => _showAddTaskFlow(context),
                  ),
                )
              else
                ...vm.upcomingDeadlines.map(
                  (d) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: _DeadlineTile(
                      deadline: d,
                      scheme: scheme,
                      accent: primary,
                    ),
                  ),
                ),
              const SizedBox(height: 88),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    this.borderColor,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      elevation: background == Colors.transparent ? 0 : 2,
      shadowColor: foreground.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: foreground,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeadlinesEmptyState extends StatelessWidget {
  const _DeadlinesEmptyState({
    required this.primary,
    required this.accent,
    required this.onAddTask,
  });

  final Color primary;
  final Color accent;
  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CustomPaint(
        painter: _SoftGridPainter(color: primary.withValues(alpha: 0.06)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withValues(alpha: 0.2)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.5),
              ],
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.event_note_rounded, size: 44, color: primary),
              const SizedBox(height: 12),
              Text(
                'No pending tasks on the radar',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyText,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Deadlines here mirror your Academics task list — not sample IT coursework.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAddTask,
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add a task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftGridPainter extends CustomPainter {
  _SoftGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 22.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> _showAddTaskFlow(BuildContext context) async {
  final titleCtrl = TextEditingController();
  final subjectCtrl = TextEditingController(text: 'General');

  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      title: const Text('Add task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Task title',
              ),
            ),
            TextField(
              controller: subjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Subject / course',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Add'),
        ),
      ],
    ),
  );

  final title = titleCtrl.text;
  final subject = subjectCtrl.text;

  void disposeCtrls() {
    titleCtrl.dispose();
    subjectCtrl.dispose();
  }

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    disposeCtrls();
    if (!context.mounted || ok != true) return;
    if (title.trim().isEmpty) return;

    final tasksVm = context.read<TasksViewModel>();
    await tasksVm.addTask(
      title: title,
      subject: subject,
      priority: TaskPriority.med,
    );
    if (!context.mounted) return;
    context.read<MainShellViewModel>().selectTab(2);
    context.read<AcademicsViewModel>().selectTasks();
    if (tasksVm.errorMessage != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tasksVm.errorMessage!)),
      );
    }
  });
}

void _showGradesSheet(BuildContext context, StudentAppContext? stud) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final primary = stud?.primaryColor ?? AppColors.primary;
      final subjects = stud?.subjects ?? const [];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.school_outlined, color: primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grades',
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.navyText,
                              ),
                        ),
                        Text(
                          stud != null
                              ? stud.collegeName
                              : 'Link your registration to see courses',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (subjects.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No enrolled subjects in your profile yet. Complete registration or refresh after your adviser updates your load.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.4,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.42,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      for (final s in subjects)
                        _GradeRow(
                          course: '${s.code} — ${s.name}',
                          grade: '—',
                          primary: primary,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Official grades come from your registrar. Placeholder “—” until you connect a grade source.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({
    required this.course,
    required this.grade,
    required this.primary,
  });

  final String course;
  final String grade;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              course,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primary.withValues(alpha: 0.25)),
            ),
            child: Text(
              grade,
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.vm,
    required this.photoBytes,
    required this.initials,
    this.collegeName,
    required this.primary,
    required this.accent,
  });

  final DashboardViewModel vm;
  final Uint8List? photoBytes;
  final String initials;
  final String? collegeName;
  final Color primary;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final deep = Color.lerp(primary, Colors.black, 0.28)!;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary, deep],
              ),
            ),
            child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 16, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vm.portalTitle,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              if (collegeName != null &&
                                  collegeName!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Text(
                                    collegeName!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ProfileAvatar(
                            radius: 26,
                            initials: initials,
                            photoBytes: photoBytes,
                            backgroundColor: accent.withValues(alpha: 0.5),
                            initialsStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vm.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vm.userSubtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 14,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.vm,
    required this.onViewAll,
    required this.primary,
    required this.accent,
    required this.surfaceTint,
  });

  final DashboardViewModel vm;
  final VoidCallback onViewAll;
  final Color primary;
  final Color accent;
  final Color surfaceTint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      elevation: 6,
      shadowColor: primary.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(22),
      color: isDark ? Theme.of(context).colorScheme.surfaceContainerHigh : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: surfaceTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.today_rounded, color: primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Today's schedule",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyText,
                          letterSpacing: -0.2,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(foregroundColor: primary),
                  child: const Text('Week view'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...vm.todaySchedule.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surfaceTint.withValues(alpha: isDark ? 0.5 : 1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 5,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [s.accent, s.accent.withValues(alpha: 0.55)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.timeLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: s.accent,
                                fontSize: 13,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.subtitle,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeadlineTile extends StatelessWidget {
  const _DeadlineTile({
    required this.deadline,
    required this.scheme,
    required this.accent,
  });

  final DeadlineItem deadline;
  final ColorScheme scheme;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      shadowColor: accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deadline.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deadline.subjectLabel,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: deadline.dueColor(scheme).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    deadline.dueLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: deadline.dueColor(scheme),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: deadline.progress,
                minHeight: 7,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
