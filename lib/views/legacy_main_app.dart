import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'project_hub_screen.dart';
import 'schedule_screen.dart';
import 'task_screen.dart';

/// Alternate shell used from [GroupScreen] (pick a group → tabbed app).
class MainApp extends StatefulWidget {
  const MainApp({super.key, required this.groupId, required this.groupName});

  final String groupId;
  final String groupName;

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
