import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:campus_taskhub/services/group_service.dart';
import 'package:campus_taskhub/services/student_profile_service.dart';
import 'package:campus_taskhub/services/task_service.dart';
import 'package:campus_taskhub/viewmodels/academics_view_model.dart';
import 'package:campus_taskhub/viewmodels/calendar_view_model.dart';
import 'package:campus_taskhub/viewmodels/dashboard_view_model.dart';
import 'package:campus_taskhub/viewmodels/main_shell_view_model.dart';
import 'package:campus_taskhub/viewmodels/profile_view_model.dart';
import 'package:campus_taskhub/viewmodels/settings_view_model.dart';
import 'package:campus_taskhub/viewmodels/project_hub_view_model.dart';
import 'package:campus_taskhub/viewmodels/student_context_view_model.dart';
import 'package:campus_taskhub/viewmodels/tasks_view_model.dart';
import 'package:campus_taskhub/views/main_shell_view.dart';

void main() {
  testWidgets('Dashboard shows portal title', (WidgetTester tester) async {
    final taskService = TaskService();
    final groupService = GroupService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                StudentContextViewModel(StudentProfileService()),
          ),
          ChangeNotifierProvider(create: (_) => SettingsViewModel()),
          ChangeNotifierProvider(create: (_) => MainShellViewModel()),
          ChangeNotifierProvider(create: (_) => AcademicsViewModel()),
          ChangeNotifierProvider(
            create: (_) => TasksViewModel(taskService, groupService),
          ),
          ChangeNotifierProxyProvider<TasksViewModel, DashboardViewModel>(
            create: (_) => DashboardViewModel(),
            update: (_, tasks, dash) {
              dash!.syncDeadlinesFromTasks(tasks.allTasks);
              return dash;
            },
          ),
          ChangeNotifierProxyProvider<TasksViewModel, CalendarViewModel>(
            create: (_) => CalendarViewModel(),
            update: (_, tasks, cal) {
              cal!.syncTaskDeadlines(tasks.allTasks);
              return cal;
            },
          ),
          ChangeNotifierProvider(create: (_) => ProjectHubViewModel()),
          ChangeNotifierProvider(create: (_) => ProfileViewModel()),
          Provider<GroupService>.value(value: groupService),
          Provider<TaskService>.value(value: taskService),
        ],
        child: const MaterialApp(
          home: MainShellView(),
        ),
      ),
    );

    expect(find.text('USLS Portal'), findsOneWidget);
  });
}
