import 'package:flutter/material.dart';

import '../services/group_service.dart';
import 'legacy_main_app.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final GroupService groupService = GroupService();
  final TextEditingController controller = TextEditingController();

  List groups = [];

  @override
  void initState() {
    super.initState();
    loadGroups();
  }

  Future<void> loadGroups() async {
    final data = await groupService.getGroups();
    setState(() {
      groups = data;
    });
  }

  Future<void> createGroup() async {
    if (controller.text.isEmpty) return;

    await groupService.createGroup(controller.text);
    controller.clear();
    await loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Groups")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: "Enter Group Name"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: createGroup,
              child: const Text("Create Group"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return ListTile(
                    title: Text(group['group_name'] ?? ''),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MainApp(
                            groupId: group['id'],
                            groupName: group['group_name'],
                          ),
                        ),
                      );
                    },
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
