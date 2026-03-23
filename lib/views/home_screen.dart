import 'package:flutter/material.dart';
import '../services/task_service.dart';
import '../services/schedule_service.dart';

class HomeScreen extends StatefulWidget {
  final String groupId;

  const HomeScreen({super.key, required this.groupId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskService taskService = TaskService();
  final ScheduleService scheduleService = ScheduleService();

  List upcomingDeadlines = [];
  List todaysSchedule = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final deadlines = await taskService.getUpcomingDeadlines(widget.groupId);
    final schedule = await scheduleService.getDaySchedule(
      widget.groupId,
      DateTime.now(),
    );

    setState(() {
      upcomingDeadlines = deadlines;
      todaysSchedule = schedule;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus TaskHub')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Deadlines',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: upcomingDeadlines.length,
                itemBuilder: (context, index) {
                  final task = upcomingDeadlines[index];
                  return Card(
                    child: ListTile(
                      title: Text(task['title'] ?? ''),
                      subtitle: Text(
                        '${task['subject'] ?? ''} - Due: ${task['due_date'] ?? ''}',
                      ),
                      trailing: Text(task['priority'] ?? ''),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Today\'s Schedule',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: todaysSchedule.length,
                itemBuilder: (context, index) {
                  final event = todaysSchedule[index];
                  return Card(
                    child: ListTile(
                      title: Text(event['title'] ?? ''),
                      subtitle: Text(
                        '${event['course'] ?? ''} - ${event['location'] ?? ''}',
                      ),
                      trailing: Text(
                        '${event['start_time'] ?? ''} - ${event['end_time'] ?? ''}',
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
