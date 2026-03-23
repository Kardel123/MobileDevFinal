import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../viewmodels/academics_view_model.dart';
import 'project_hub_view.dart';
import 'tasks_view.dart';

/// Academics: Tasks + Projects; tab index lives in [AcademicsViewModel] (MVVM).
class AcademicsView extends StatelessWidget {
  const AcademicsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AcademicsViewModel>();

    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              Expanded(
                child: _AcademicsTabButton(
                  label: 'Tasks',
                  selected: vm.tabIndex == 0,
                  onTap: vm.selectTasks,
                ),
              ),
              Expanded(
                child: _AcademicsTabButton(
                  label: 'Projects',
                  selected: vm.tabIndex == 1,
                  onTap: vm.selectProjects,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: IndexedStack(
            index: vm.tabIndex,
            children: const [
              TasksView(),
              ProjectHubView(),
            ],
          ),
        ),
      ],
    );
  }
}

class _AcademicsTabButton extends StatelessWidget {
  const _AcademicsTabButton({
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : const Color(0xFF9E9E9E),
          ),
        ),
      ),
    );
  }
}
