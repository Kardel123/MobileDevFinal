import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/task_service.dart';
import 'services/group_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tfbsttdoqxyszpmsnvve.supabase.co',
    anonKey: 'sb_publishable_TwGpM6tviOG4MsGQG8cM-w_a_IVGiq-',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final TaskService taskService = TaskService();
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

    await taskService.createTask(taskController.text, currentGroupId!);
    taskController.clear();
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
            // CREATE GROUP
            TextField(
              controller: groupController,
              decoration: const InputDecoration(
                labelText: "Enter Group Name",
              ),
            ),
            ElevatedButton(
              onPressed: createGroup,
              child: const Text("Create Group"),
            ),

            const SizedBox(height: 20),

            // TASK INPUT
            TextField(
              controller: taskController,
              decoration: const InputDecoration(
                labelText: "Enter Task",
              ),
            ),
            ElevatedButton(
              onPressed: addTask,
              child: const Text("Add Task"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loadTasks,
              child: const Text("Load Tasks"),
            ),

            const SizedBox(height: 20),

            // TASK LIST
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
    );
  }
}