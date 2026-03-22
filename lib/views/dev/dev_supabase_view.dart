import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/group_service.dart';
import '../../services/task_service.dart';
import '../../viewmodels/dev_supabase_view_model.dart';

/// Developer-only View; state is driven by [DevSupabaseViewModel].
class DevSupabaseView extends StatefulWidget {
  const DevSupabaseView({super.key});

  @override
  State<DevSupabaseView> createState() => _DevSupabaseViewState();
}

class _DevSupabaseViewState extends State<DevSupabaseView> {
  final _groupController = TextEditingController();
  final _taskController = TextEditingController();

  late final DevSupabaseViewModel _viewModel = DevSupabaseViewModel(
    GroupService(),
    TaskService(),
  );

  @override
  void dispose() {
    _viewModel.dispose();
    _groupController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Do not use `create:` here — each notifyListeners rebuild would replace the
    // provider and hit framework `_dependents.isEmpty` / wrong build scope.
    return ChangeNotifierProvider<DevSupabaseViewModel>.value(
      value: _viewModel,
      child: Consumer<DevSupabaseViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(title: const Text('Supabase test')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _groupController,
                    decoration: const InputDecoration(
                      labelText: 'Group name',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: vm.loading
                        ? null
                        : () async {
                            await vm.createGroup(_groupController.text);
                            _groupController.clear();
                          },
                    child: const Text('Create group'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      labelText: 'Task title',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: vm.loading
                        ? null
                        : () async {
                            await vm.addTask(_taskController.text);
                            _taskController.clear();
                          },
                    child: const Text('Add task'),
                  ),
                  ElevatedButton(
                    onPressed: vm.loading ? null : vm.loadTasks,
                    child: const Text('Load tasks'),
                  ),
                  if (vm.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        vm.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (vm.currentGroupId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Group id: ${vm.currentGroupId}'),
                    ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: vm.tasks.length,
                      itemBuilder: (context, index) {
                        final task = vm.tasks[index];
                        return ListTile(
                          title: Text(task['title']?.toString() ?? ''),
                          subtitle: Text(task['status']?.toString() ?? ''),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
