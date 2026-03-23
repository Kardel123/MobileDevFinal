import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/project_model.dart';
import '../theme/app_colors.dart';
import '../viewmodels/project_hub_view_model.dart';

class ProjectHubView extends StatelessWidget {
  const ProjectHubView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProjectHubViewModel>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text(
                  'Project Hub',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyText,
                      ),
                ),
                const Spacer(),
                CircleAvatar(
                  backgroundColor: AppColors.mint,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _HubTab(
                  label: 'Active (${vm.countFor(ProjectHubTab.active)})',
                  selected: vm.tab == ProjectHubTab.active,
                  onTap: () => vm.setTab(ProjectHubTab.active),
                ),
                const SizedBox(width: 16),
                _HubTab(
                  label: 'Completed',
                  selected: vm.tab == ProjectHubTab.completed,
                  onTap: () => vm.setTab(ProjectHubTab.completed),
                ),
                const SizedBox(width: 16),
                _HubTab(
                  label: 'Requests',
                  selected: vm.tab == ProjectHubTab.requests,
                  onTap: () => vm.setTab(ProjectHubTab.requests),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: vm.tab != ProjectHubTab.active
                ? const Center(child: Text('No items'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: vm.projects.length,
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ProjectCard(
                          project: vm.projects[i],
                          viewModel: vm,
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
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primary : const Color(0xFF9E9E9E),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: 72,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
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
  });

  final ProjectItem project;
  final ProjectHubViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    project.tag,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<_ProjectCardMenuAction>(
                  tooltip: 'More',
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
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
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ...List.generate(
                  project.avatarCount,
                  (i) => Align(
                    widthFactor: 0.75,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Color.lerp(
                        AppColors.mint,
                        AppColors.primaryLight,
                        (i % 3) / 3,
                      )!,
                      child: Text(
                        String.fromCharCode(65 + i),
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ),
                ),
                if (project.extraMembers > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '+${project.extraMembers}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'Completion',
                  style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '${(project.completion * 100).round()}%',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: project.completion,
                minHeight: 8,
                backgroundColor: const Color(0xFFE0E0E0),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFBDBDBD), style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.chevron_right, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next Step',
                          style: TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          project.nextStep,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
