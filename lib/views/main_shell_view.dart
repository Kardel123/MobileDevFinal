import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../viewmodels/calendar_view_model.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../viewmodels/main_shell_view_model.dart';
import '../viewmodels/profile_view_model.dart';
import '../viewmodels/project_hub_view_model.dart';
import '../viewmodels/student_context_view_model.dart';
import '../viewmodels/tasks_view_model.dart';
import 'academics_view.dart';
import 'dashboard_view.dart';
import 'profile_view.dart';
import 'weekly_calendar_view.dart';

/// Shell with bottom navigation; loads Supabase student context once when opened.
class MainShellView extends StatefulWidget {
  const MainShellView({super.key});

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapStudentContext());
  }

  Future<void> _bootstrapStudentContext() async {
    if (!mounted) return;
    final studentCtx = context.read<StudentContextViewModel>();
    await studentCtx.load();
    if (!mounted) return;
    final c = studentCtx.context;
    if (c != null) {
      context.read<DashboardViewModel>().applyStudentContext(c);
      context.read<ProfileViewModel>().applyStudentContext(c);
      context.read<CalendarViewModel>().setEnrollmentWeeklySlots(c.weeklySlots);
      context.read<ProjectHubViewModel>().applyStudentContext(c);
    } else {
      context.read<ProjectHubViewModel>().applyStudentContext(null);
    }
    await context.read<TasksViewModel>().refresh();
    if (!mounted) return;
    context.read<DashboardViewModel>().syncDeadlinesFromTasks(
      context.read<TasksViewModel>().allTasks,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MainShellViewModel>();

    final pages = [
      const DashboardView(),
      const WeeklyCalendarView(),
      const AcademicsView(),
      const ProfileView(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: vm.selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: vm.selectedIndex,
        onTap: vm.selectTab,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_outlined),
            activeIcon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Academics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
