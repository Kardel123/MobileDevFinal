import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../viewmodels/academics_view_model.dart';
import '../viewmodels/student_context_view_model.dart';
import 'insights_view.dart';
import 'project_hub_view.dart';
import 'tasks_view.dart';
import 'team_view.dart';

/// Academics: Tasks, Projects, Insights, Team — [AcademicsViewModel] (MVVM).
class AcademicsView extends StatelessWidget {
  const AcademicsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AcademicsViewModel>();
    final stud = context.watch<StudentContextViewModel>().context;

    return Column(
      children: [
        if (stud != null)
          Material(
            color: stud.primaryColor.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Icon(Icons.school_outlined, color: stud.primaryColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stud.programLine,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: stud.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stud.enrolledSubjectsSummary,
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
                ],
              ),
            ),
          ),
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _AcademicsTabButton(
                  label: 'Tasks',
                  selected: vm.tabIndex == 0,
                  onTap: vm.selectTasks,
                ),
                _AcademicsTabButton(
                  label: 'Projects',
                  selected: vm.tabIndex == 1,
                  onTap: vm.selectProjects,
                ),
                _AcademicsTabButton(
                  label: 'Insights',
                  selected: vm.tabIndex == 2,
                  onTap: vm.selectInsights,
                ),
                _AcademicsTabButton(
                  label: 'Team',
                  selected: vm.tabIndex == 3,
                  onTap: vm.selectTeam,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: IndexedStack(
            index: vm.tabIndex,
            children: const [
              TasksView(),
              ProjectHubView(),
              InsightsView(),
              TeamView(),
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
        constraints: const BoxConstraints(minWidth: 96),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
