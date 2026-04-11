import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/project_model.dart';
import '../theme/app_colors.dart';
import '../viewmodels/project_hub_view_model.dart';
import '../viewmodels/student_context_view_model.dart';

class ProjectHubView extends StatefulWidget {
  const ProjectHubView({super.key});

  @override
  State<ProjectHubView> createState() => _ProjectHubViewState();
}

class _ProjectHubViewState extends State<ProjectHubView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProjectHubViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProjectHubViewModel>();
    final stud = context.watch<StudentContextViewModel>().context;
    final primary = stud?.primaryColor ?? AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary,
                  Color.lerp(primary, Colors.black, 0.22)!,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top > 0 ? 8 : 16,
              16,
              22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project hub',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            stud != null
                                ? 'Samples framed for ${stud.collegeName}'
                                : 'Team work aligned to your program after registration',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _showAddProjectDialog(context, vm),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.add_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _HubTab(
                      label: 'Active (${vm.countFor(ProjectHubTab.active)})',
                      selected: vm.tab == ProjectHubTab.active,
                      primary: primary,
                      onTap: () => vm.setTab(ProjectHubTab.active),
                    ),
                    const SizedBox(width: 18),
                    _HubTab(
                      label:
                          'Completed (${vm.countFor(ProjectHubTab.completed)})',
                      selected: vm.tab == ProjectHubTab.completed,
                      primary: primary,
                      onTap: () => vm.setTab(ProjectHubTab.completed),
                    ),
                    const SizedBox(width: 18),
                    _HubTab(
                      label:
                          'Requests (${vm.countFor(ProjectHubTab.requests)})',
                      selected: vm.tab == ProjectHubTab.requests,
                      primary: primary,
                      onTap: () => vm.setTab(ProjectHubTab.requests),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (vm.errorMessage != null)
            Material(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade800),
                title: Text(
                  vm.errorMessage!,
                  style:
                      TextStyle(fontSize: 13, color: Colors.orange.shade900),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => vm.clearError(),
                ),
              ),
            ),
          Expanded(
            child: vm.loading && vm.projects.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : vm.projects.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder_open_rounded,
                                size: 48,
                                color: primary.withValues(alpha: 0.35),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Nothing here yet',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                stud == null
                                    ? 'Sign in and complete registration to manage projects.'
                                    : 'Tap + to add a project for ${stud.collegeName}.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: vm.projects.length,
                        itemBuilder: (context, i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _ProjectCard(
                              project: vm.projects[i],
                              viewModel: vm,
                              hubTab: vm.tab,
                              primary: primary,
                              isDark: isDark,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _HubTab extends StatelessWidget {
  const _HubTab({
    required this.label,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: 64,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.viewModel,
    required this.hubTab,
    required this.primary,
    required this.isDark,
  });

  final ProjectItem project;
  final ProjectHubViewModel viewModel;
  final ProjectHubTab hubTab;
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dueLabel = DateFormat.yMMMd().format(project.dueDate);
    return Material(
      elevation: 2,
      shadowColor: primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      color: isDark
          ? Theme.of(context).colorScheme.surfaceContainerHigh
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.event_outlined, size: 20, color: primary),
                      const SizedBox(width: 8),
                      Text(
                        'Due $dueLabel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_ProjectCardMenuAction>(
                  tooltip: 'More',
                  icon: Icon(Icons.more_vert_rounded,
                      color: Colors.grey.shade600),
                  onSelected: (action) => _handleMenuAction(
                    context,
                    viewModel,
                    project,
                    action,
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: _ProjectCardMenuAction.edit,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined, size: 22),
                        title: Text('Edit'),
                      ),
                    ),
                    if (hubTab == ProjectHubTab.active)
                      const PopupMenuItem(
                        value: _ProjectCardMenuAction.markComplete,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              Icon(Icons.check_circle_outline, size: 22),
                          title: Text('Mark as complete'),
                        ),
                      ),
                    if (hubTab == ProjectHubTab.completed)
                      const PopupMenuItem(
                        value: _ProjectCardMenuAction.reopen,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.undo_rounded, size: 22),
                          title: Text('Move to active'),
                        ),
                      ),
                    const PopupMenuItem(
                      value: _ProjectCardMenuAction.remove,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline, size: 22),
                        title: Text('Remove'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Details',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              project.details.isEmpty ? 'No details yet.' : project.details,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w500,
                fontStyle:
                    project.details.isEmpty ? FontStyle.italic : FontStyle.normal,
                color: project.details.isEmpty
                    ? Colors.grey.shade600
                    : null,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Progress',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${project.completionPercent}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: project.completionPercent / 100.0,
                minHeight: 8,
                backgroundColor: primary.withValues(alpha: 0.12),
                color: primary,
              ),
            ),
            if (hubTab == ProjectHubTab.active) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Slider(
                  value: project.completionPercent.toDouble(),
                  max: 100,
                  divisions: 20,
                  label: '${project.completionPercent}%',
                  onChanged: (v) => viewModel.setProjectCompletion(
                    project.id,
                    v.round(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => _showMarkCompleteDialog(
                    context,
                    viewModel,
                    project,
                  ),
                  icon: const Icon(Icons.task_alt_rounded, size: 20),
                  label: const Text('Mark as complete'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _ProjectCardMenuAction { edit, markComplete, reopen, remove }

Future<void> _handleMenuAction(
  BuildContext context,
  ProjectHubViewModel vm,
  ProjectItem project,
  _ProjectCardMenuAction action,
) async {
  switch (action) {
    case _ProjectCardMenuAction.edit:
      await _showEditProjectDialog(context, vm, project);
      break;
    case _ProjectCardMenuAction.markComplete:
      await _showMarkCompleteDialog(context, vm, project);
      break;
    case _ProjectCardMenuAction.reopen:
      await _showReopenProjectDialog(context, vm, project);
      break;
    case _ProjectCardMenuAction.remove:
      await _showRemoveProjectDialog(context, vm, project);
      break;
  }
}

Future<void> _showMarkCompleteDialog(
  BuildContext context,
  ProjectHubViewModel vm,
  ProjectItem project,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Mark as complete?'),
      content: const Text(
        'This project will move to the Completed tab and progress will be set to 100%.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Complete'),
        ),
      ],
    ),
  );
  if (!context.mounted || ok != true) return;
  await vm.markProjectCompleted(project.id);
  if (!context.mounted) return;
  final err = vm.errorMessage;
  if (err != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }
}

Future<void> _showReopenProjectDialog(
  BuildContext context,
  ProjectHubViewModel vm,
  ProjectItem project,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Move to active?'),
      content: const Text(
        'This project will appear under Active again.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Move to active'),
        ),
      ],
    ),
  );
  if (!context.mounted || ok != true) return;
  await vm.markProjectActive(project.id);
  if (!context.mounted) return;
  final err = vm.errorMessage;
  if (err != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }
}

Future<void> _showEditProjectDialog(
  BuildContext context,
  ProjectHubViewModel vm,
  ProjectItem project,
) async {
  final detailsCtrl = TextEditingController(text: project.details);
  var dueDate = project.dueDate;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Edit project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (picked != null) {
                      setDialogState(() => dueDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: detailsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Details',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  minLines: 4,
                  maxLines: 10,
                  autofocus: true,
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
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );

  final details = detailsCtrl.text.trim();
  WidgetsBinding.instance.addPostFrameCallback((_) => detailsCtrl.dispose());

  if (!context.mounted || ok != true) return;
  await vm.updateProjectDetails(
    projectId: project.id,
    dueDate: dueDate,
    details: details,
  );
  if (!context.mounted) return;
  final err = vm.errorMessage;
  if (err != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }
}

Future<void> _showRemoveProjectDialog(
  BuildContext context,
  ProjectHubViewModel vm,
  ProjectItem project,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Remove project?'),
      content: Text(
        _removeProjectMessage(project),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade700,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );

  if (!context.mounted || confirmed != true) return;
  await vm.removeProject(project.id);
  if (!context.mounted) return;
  final err = vm.errorMessage;
  if (err != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }
}

String _removeProjectMessage(ProjectItem project) {
  final d = project.details;
  if (d.length <= 120) return 'Remove this project?\n\n$d';
  return 'Remove this project?\n\n${d.substring(0, 117)}…';
}

Future<void> _showAddProjectDialog(
  BuildContext context,
  ProjectHubViewModel vm,
) async {
  final detailsCtrl = TextEditingController();
  var dueDate = DateTime.now().add(const Duration(days: 14));

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('New project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 1)),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (picked != null) {
                      setDialogState(() => dueDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Details',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                    hintText: 'What is this project about?',
                  ),
                  minLines: 4,
                  maxLines: 10,
                  autofocus: true,
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
              child: const Text('Create'),
            ),
          ],
        );
      },
    ),
  );

  final details = detailsCtrl.text.trim();
  WidgetsBinding.instance.addPostFrameCallback((_) => detailsCtrl.dispose());

  if (!context.mounted || ok != true) return;
  final success = await vm.addProject(
    dueDate: dueDate,
    details: details,
  );
  if (!context.mounted) return;
  if (!success && vm.errorMessage != null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(vm.errorMessage!)));
  }
}
