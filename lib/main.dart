import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/group_screen.dart';
import 'views/home_screen.dart';
import 'views/project_hub_screen.dart';
import 'views/task_screen.dart';
import 'views/schedule_screen.dart';
import 'services/task_service.dart';
import 'services/project_service.dart';
import 'services/schedule_service.dart';
import 'services/group_service.dart';
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
import 'viewmodels/tasks_view_model.dart';
import 'views/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    return const MaterialApp(home: GroupScreen());
  }
}

// Keep TestScreen for quick backend testing if needed later.
class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final TaskService taskService = TaskService();
  final ProjectService projectService = ProjectService();
  final ScheduleService scheduleService = ScheduleService();
  final GroupService groupService = GroupService();

  final TextEditingController groupController = TextEditingController();
  final TextEditingController taskController = TextEditingController();

  List tasks = [];
  String? currentGroupId;

  Future<void> createGroup() async {
    if (groupController.text.isEmpty) return;

    final id = await groupService.createGroup(groupController.text);

    setState(() {
      currentGroupId = id;
    });

    groupController.clear();
  }

  Future<void> loadTasks() async {
    if (currentGroupId == null) return;

    final data = await taskService.getTasks(currentGroupId!);

    setState(() {
      tasks = data;
    });
  }

  Future<void> addTask() async {
    if (taskController.text.isEmpty || currentGroupId == null) return;

    await taskService.createTask(
      title: taskController.text,
      groupId: currentGroupId!,
    );

    taskController.clear();
    await loadTasks();
  }

  Future<void> seedAllSampleData() async {
    if (currentGroupId == null) return;

    await taskService.seedSampleTasks(currentGroupId!);
    await projectService.seedSampleProjects(currentGroupId!);
    await scheduleService.seedSampleSchedule(currentGroupId!);

    await loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Campus TaskHub")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: groupController,
              decoration: const InputDecoration(labelText: "Enter Group Name"),
            ),
            ElevatedButton(
              onPressed: createGroup,
              child: const Text("Create Group"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: taskController,
              decoration: const InputDecoration(labelText: "Enter Task"),
            ),
            ElevatedButton(onPressed: addTask, child: const Text("Add Task")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: seedAllSampleData,
              child: const Text("Seed Mockup Data"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: loadTasks,
              child: const Text("Load Tasks"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return ListTile(
                    title: Text(task['title'] ?? ''),
                    subtitle: Text(task['status'] ?? ''),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      themeMode: settings.themeMode,
      home: const AuthGate(),
    );
  }
}

class MainApp extends StatefulWidget {
  final String groupId;
  final String groupName;

  const MainApp({super.key, required this.groupId, required this.groupName});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(groupId: widget.groupId),
      ProjectHubScreen(groupId: widget.groupId),
      TaskScreen(groupId: widget.groupId, groupName: widget.groupName),
      ScheduleScreen(groupId: widget.groupId),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Projects'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Tasks'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
