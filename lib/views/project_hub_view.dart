import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/project_model.dart';
import '../theme/app_colors.dart';
import '../viewmodels/project_hub_view_model.dart';
import '../viewmodels/student_context_view_model.dart';

class ProjectHubView extends StatelessWidget {
  const ProjectHubView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProjectHubViewModel>();
    final stud = context.watch<StudentContextViewModel>().context;
    final primary = stud?.primaryColor ?? AppColors.primary;
    final accent = stud?.accentColor ?? AppColors.mint;
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
                        onTap: () {},
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
                      label: 'Completed',
                      selected: vm.tab == ProjectHubTab.completed,
                      primary: primary,
                      onTap: () => vm.setTab(ProjectHubTab.completed),
                    ),
                    const SizedBox(width: 18),
                    _HubTab(
                      label: 'Requests',
                      selected: vm.tab == ProjectHubTab.requests,
                      primary: primary,
                      onTap: () => vm.setTab(ProjectHubTab.requests),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: vm.tab != ProjectHubTab.active
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
                            'When you track ${stud?.collegeName ?? 'program'} projects, they will appear in this tab.',
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: vm.projects.length,
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ProjectCard(
                          project: vm.projects[i],
                          viewModel: vm,
                          primary: primary,
                          accentSurface: isDark
                              ? primary.withValues(alpha: 0.18)
                              : accent.withValues(alpha: 0.45),
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
    required this.primary,
    required this.accentSurface,
    required this.isDark,
  });

  final ProjectItem project;
  final ProjectHubViewModel viewModel;
  final Color primary;
  final Color accentSurface;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
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
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    project.tag,
                    style: TextStyle(
                      color: primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const Spacer(),
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
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _ProjectCardMenuAction.editNextStep,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined, size: 22),
                        title: Text('Edit next step'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _ProjectCardMenuAction.remove,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline, size: 22),
                        title: Text('Remove project'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              project.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                ...List.generate(
                  project.avatarCount,
                  (i) => Align(
                    widthFactor: 0.75,
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: Color.lerp(
                        accentSurface,
                        primary.withValues(alpha: 0.25),
                        (i % 3) / 3,
                      )!,
                      child: Text(
                        String.fromCharCode(65 + i),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
                ),
                if (project.extraMembers > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '+${project.extraMembers}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Completion',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(project.completion * 100).round()}%',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: project.completion,
                minHeight: 9,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(primary),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isDark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 20, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next step',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          project.nextStep,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
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

enum _ProjectCardMenuAction { editNextStep, remove }

Future<void> _handleMenuAction(
  BuildContext context,
  ProjectHubViewModel vm,
  ProjectItem project,
  _ProjectCardMenuAction action,
) async {
  switch (action) {
    case _ProjectCardMenuAction.editNextStep:
      await _showEditNextStepDialog(context, vm, project);
    case _ProjectCardMenuAction.remove:
      await _showRemoveProjectDialog(context, vm, project);
  }
}

Future<void> _showEditNextStepDialog(
  BuildContext context,
  ProjectHubViewModel vm,
  ProjectItem project,
) async {
  final controller = TextEditingController(text: project.nextStep);

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Edit next step'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Next step',
          hintText: 'What should happen next?',
        ),
        maxLines: 2,
        autofocus: true,
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
    ),
  );

  final text = controller.text;
  WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());

  if (!context.mounted || ok != true) return;
  vm.updateNextStep(project.id, text);
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
        '“${project.title}” will be removed from your active list.',
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
  vm.removeProject(project.id);
}
