import 'package:flutter/material.dart';
import '../services/schedule_service.dart';

class ScheduleScreen extends StatefulWidget {
  final String groupId;

  const ScheduleScreen({super.key, required this.groupId});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ScheduleService scheduleService = ScheduleService();

  List scheduleEvents = [];
  DateTime selectedWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );

  @override
  void initState() {
    super.initState();
    loadSchedule();
  }

  Future<void> loadSchedule() async {
    final weekEnd = selectedWeekStart.add(const Duration(days: 6));
    final data = await scheduleService.getWeeklySchedule(
      widget.groupId,
      selectedWeekStart,
      weekEnd,
    );
    setState(() {
      scheduleEvents = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    selectedWeekStart = selectedWeekStart.subtract(
                      const Duration(days: 7),
                    );
                  });
                  loadSchedule();
                },
              ),
              Text(
                '${selectedWeekStart.month}/${selectedWeekStart.day} - ${selectedWeekStart.add(const Duration(days: 6)).month}/${selectedWeekStart.add(const Duration(days: 6)).day}',
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  setState(() {
                    selectedWeekStart = selectedWeekStart.add(
                      const Duration(days: 7),
                    );
                  });
                  loadSchedule();
                },
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 7,
              itemBuilder: (context, index) {
                final day = selectedWeekStart.add(Duration(days: index));
                final dayEvents = scheduleEvents.where((event) {
                  final eventDate = DateTime.parse(
                    event['start_time'],
                  ).toLocal();
                  return eventDate.year == day.year &&
                      eventDate.month == day.month &&
                      eventDate.day == day.day;
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${day.month}/${day.day} - ${['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index]}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...dayEvents.map(
                      (event) => Card(
                        child: ListTile(
                          title: Text(event['title'] ?? ''),
                          subtitle: Text(
                            '${event['course'] ?? ''} - ${event['location'] ?? ''}',
                          ),
                          trailing: Text(
                            '${DateTime.parse(event['start_time']).toLocal().hour}:${DateTime.parse(event['start_time']).toLocal().minute.toString().padLeft(2, '0')} - ${DateTime.parse(event['end_time']).toLocal().hour}:${DateTime.parse(event['end_time']).toLocal().minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
