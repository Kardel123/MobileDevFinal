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
    var dueDate = DateTime.now().add(const Duration(days: 7));

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
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
                    decoration:
                        const InputDecoration(labelText: 'Subject / course'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: const Text('Due date'),
                    subtitle: Text(DateFormat.yMMMd().format(dueDate)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: dueDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                      );
                      if (picked != null) {
                        setDialogState(() => dueDate = picked);
                      }
                    },
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
          );
        },
      ),
    );

    if (!context.mounted) return;
    final title = titleCtrl.text.trim();
    final subject = subjectCtrl.text;
    // Defer dispose until the dialog route has unmounted (avoids framework assertions).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      titleCtrl.dispose();
      subjectCtrl.dispose();
    });

    if (ok != true || title.isEmpty) return;

    final vm = context.read<TasksViewModel>();
    final success = await vm.addTask(
      title: title,
      subject: subject,
      priority: TaskPriority.med,
      dueDate: dueDate,
    );
    if (!context.mounted) return;
    if (!success && vm.errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(vm.errorMessage!)));
    }
  }

  Future<void> _pickDueDateForTask(
    BuildContext context,
    AcademicTask task,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: task.dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null || !context.mounted) return;
    final vm = context.read<TasksViewModel>();
    await vm.updateTaskDueDate(task, picked);
    if (!context.mounted) return;
    final err = vm.errorMessage;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
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
                            onToggleDone: () => vm.toggleTaskDone(t),
                            onTogglePin: () => vm.togglePin(t),
                            onProgress: (p) => vm.setProgressPercent(t, p),
                            onEditDueDate: () => _pickDueDateForTask(context, t),
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
    required this.onToggleDone,
    required this.onTogglePin,
    required this.onProgress,
    required this.onEditDueDate,
  });

  final AcademicTask task;
  final VoidCallback onToggleDone;
  final VoidCallback onTogglePin;
  final ValueChanged<int> onProgress;
  final VoidCallback onEditDueDate;

  @override
  Widget build(BuildContext context) {
    final due = DateFormat.MMMd().addPattern(', y').format(task.dueDate);
    final done = task.status == AcademicTaskStatus.done;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: done,
                  onChanged: (_) => onToggleDone(),
                  activeColor: AppColors.primary,
                ),
                IconButton(
                  tooltip: task.isPinned ? 'Unpin' : 'Pin',
                  onPressed: onTogglePin,
                  icon: Icon(
                    task.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: task.isPinned ? AppColors.primary : Colors.grey,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.subject,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.5,
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyText,
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                ),
                _PriorityBadge(priority: task.priority),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 48, right: 0, top: 4),
              child: InkWell(
                onTap: done ? null : onEditDueDate,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Due: $due · tap to change',
                          style: TextStyle(
                            color: done ? Colors.grey : const Color(0xFF757575),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (!done)
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (!done) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Row(
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${task.progressPercent}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 36, right: 0),
                child: Slider(
                  value: task.progressPercent.toDouble(),
                  max: 100,
                  divisions: 20,
                  label: '${task.progressPercent}%',
                  onChanged: (v) => onProgress(v.round()),
                ),
              ),
            ],
          ],
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
