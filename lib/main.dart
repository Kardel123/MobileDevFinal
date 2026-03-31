import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/deadline_notification_service.dart';
import 'services/group_service.dart';
import 'services/student_profile_service.dart';
import 'services/task_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/academics_view_model.dart';
import 'viewmodels/settings_view_model.dart';
import 'viewmodels/calendar_view_model.dart';
import 'viewmodels/dashboard_view_model.dart';
import 'viewmodels/login_view_model.dart';
import 'viewmodels/main_shell_view_model.dart';
import 'viewmodels/profile_view_model.dart';
import 'viewmodels/project_hub_view_model.dart';
import 'viewmodels/student_context_view_model.dart';
import 'viewmodels/tasks_view_model.dart';
import 'app_keys.dart';
import 'views/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DeadlineNotificationService.instance.init();

  await Supabase.initialize(
    url: 'https://tfbsttdoqxyszpmsnvve.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmYnN0dGRvcXh5c3pwbXNudnZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3NTAzNjMsImV4cCI6MjA4OTMyNjM2M30.setejUvdcHYKBm0UQs7q-hhFHyybz3Yx6iaEsoLCOTk',
  );

  runApp(const CampusTaskHubApp());
}

/// Root widget: provides ViewModels (MVVM) and app-wide theming.
class CampusTaskHubApp extends StatelessWidget {
  const CampusTaskHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final taskService = TaskService();
    final groupService = GroupService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              StudentContextViewModel(StudentProfileService()),
        ),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
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
      child: const _ThemedApp(),
    );
  }
}

/// Rebuilds [MaterialApp] when [SettingsViewModel] changes (theme / background).
class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();

    return MaterialApp(
      title: 'Campus TaskHub',
      theme: buildAppTheme().copyWith(
        scaffoldBackgroundColor: settings.lightScaffoldBackground,
      ),
      darkTheme: buildDarkAppTheme().copyWith(
        scaffoldBackgroundColor: settings.darkScaffoldBackground,
      ),
      themeMode: settings.themeMode,
      home: AuthGate(key: authGateKey),
    );
  }
}
