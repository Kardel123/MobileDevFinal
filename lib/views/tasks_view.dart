import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/academic_task.dart';
import '../models/task_filter.dart';
import '../models/task_priority.dart';
import '../theme/app_colors.dart';
import '../viewmodels/student_context_view_model.dart';
import '../viewmodels/tasks_view_model.dart';

class TasksView extends StatefulWidget {
  const TasksView({super.key});

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TasksViewModel>().refresh();
    });
  }

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController(text: 'General');

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('New task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(labelText: 'Subject / course'),
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

    final title = titleCtrl.text.trim();
    final subject = subjectCtrl.text;

    void disposeCtrls() {
      titleCtrl.dispose();
      subjectCtrl.dispose();
    }

    // Let the dialog route + IME finish unmounting before disposing controllers.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      disposeCtrls();
      if (!mounted) return;
      if (ok != true || title.isEmpty) return;

      final messenger = ScaffoldMessenger.of(context);
      final vm = context.read<TasksViewModel>();
      final success = await vm.addTask(
        title: title,
        subject: subject,
        priority: TaskPriority.med,
      );
      if (!mounted) return;
      if (!success && vm.errorMessage != null) {
        messenger.showSnackBar(SnackBar(content: Text(vm.errorMessage!)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TasksViewModel>();
    final stud = context.watch<StudentContextViewModel>().context;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TasksHeader(
            vm: vm,
            programLine: stud?.programLine,
            enrolledSummary: stud?.enrolledSubjectsSummary,
            headerColor: stud?.primaryColor,
            onAdd: () => _showAddTaskDialog(context),
          ),
          if (vm.loading && vm.visibleTasks.isEmpty)
            const LinearProgressIndicator(minHeight: 3),
          if (vm.errorMessage != null)
            Material(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade800),
                title: Text(
                  vm.errorMessage!,
                  style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => vm.clearError(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: vm.filter == TaskFilter.all,
                  onTap: () => vm.setFilter(TaskFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pending',
                  selected: vm.filter == TaskFilter.pending,
                  onTap: () => vm.setFilter(TaskFilter.pending),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Done',
                  selected: vm.filter == TaskFilter.done,
                  onTap: () => vm.setFilter(TaskFilter.done),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => vm.refresh(),
              child: vm.visibleTasks.isEmpty && !vm.loading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 48),
                        Center(
                          child: Text(
                            'No tasks yet.\nPull to refresh or tap + to add one.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: vm.visibleTasks.length,
                      itemBuilder: (context, i) {
                        final t = vm.visibleTasks[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TaskCard(
                            task: t,
                            onToggle: () => vm.toggleTaskDone(t),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TasksHeader extends StatelessWidget {
  const _TasksHeader({
    required this.vm,
    this.programLine,
    this.enrolledSummary,
    this.headerColor,
    required this.onAdd,
  });

  final TasksViewModel vm;
  final String? programLine;
  final String? enrolledSummary;
  final Color? headerColor;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final bg = headerColor ?? AppColors.primary;
    final sub = programLine ?? vm.semesterLabel;
    final extra = enrolledSummary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tasks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                if (extra != null && extra.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    extra,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Material(
            color: AppColors.primaryLight,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onAdd,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.primary : AppColors.mintSoft,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.primary,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onToggle,
  });

  final AcademicTask task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final due = DateFormat.MMMd().addPattern(', y').format(task.dueDate);
    final done = task.status == AcademicTaskStatus.done;

    return Card(
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    done ? Icons.check_circle : Icons.circle_outlined,
                    size: 22,
                    color: done ? AppColors.primary : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.subject,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  _PriorityBadge(priority: task.priority),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyText,
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: Color(0xFF9E9E9E)),
                  const SizedBox(width: 6),
                  Text(
                    'Due: $due',
                    style: TextStyle(
                      color: done ? Colors.grey : const Color(0xFF757575),
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    done ? 'Tap to mark pending' : 'Tap to mark done',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    late String label;
    late Color bg;
    late Color fg;

    switch (priority) {
      case TaskPriority.high:
        label = 'HIGH';
        bg = AppColors.primaryDark;
        fg = Colors.white;
        break;
      case TaskPriority.med:
        label = 'MED';
        bg = AppColors.primary;
        fg = Colors.white;
        break;
      case TaskPriority.low:
        label = 'LOW';
        bg = AppColors.mint;
        fg = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
