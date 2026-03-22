import 'package:flutter/material.dart';
import '../services/task_service.dart';

class TaskScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const TaskScreen({super.key, required this.groupId, required this.groupName});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final TaskService taskService = TaskService();
  final TextEditingController controller = TextEditingController();

  List tasks = [];
  String filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    List<dynamic> data;
    if (filterStatus == 'All') {
      data = await taskService.getTasks(widget.groupId);
    } else {
      data = await taskService.getTasksByStatus(widget.groupId, filterStatus);
    }
    setState(() {
      tasks = data;
    });
  }

  Future<void> addTask() async {
    if (controller.text.isEmpty) return;

    await taskService.createTask(
      title: controller.text,
      groupId: widget.groupId,
    );
    controller.clear();
    await loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.groupName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: "Enter Task"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: addTask, child: const Text("Add Task")),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: filterStatus == 'All',
                  onSelected: (selected) {
                    setState(() => filterStatus = 'All');
                    loadTasks();
                  },
                ),
                FilterChip(
                  label: const Text('Pending'),
                  selected: filterStatus == 'Pending',
                  onSelected: (selected) {
                    setState(() => filterStatus = 'Pending');
                    loadTasks();
                  },
                ),
                FilterChip(
                  label: const Text('Done'),
                  selected: filterStatus == 'Done',
                  onSelected: (selected) {
                    setState(() => filterStatus = 'Done');
                    loadTasks();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Card(
                    child: ListTile(
                      title: Text(task['title'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Subject: ${task['subject'] ?? ''}'),
                          Text('Priority: ${task['priority'] ?? ''}'),
                          Text('Due: ${task['due_date'] ?? ''}'),
                          Text('Status: ${task['status'] ?? ''}'),
                        ],
                      ),
                    ),
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
