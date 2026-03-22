import 'package:supabase_flutter/supabase_flutter.dart';

class TaskService {
  final supabase = Supabase.instance.client;

  // CREATE TASK
  Future<void> createTask(String title, String groupId) async {
    await supabase.from('tasks').insert({
      'title': title,
      'group_id': groupId,
      'status': 'To Do',
    });
  }

  // GET TASKS
  Future<List<dynamic>> getTasks(String groupId) async {
    final response = await supabase
        .from('tasks')
        .select()
        .eq('group_id', groupId);

    return response;
  }

  // UPDATE TASK STATUS
  Future<void> updateTaskStatus(String taskId, String status) async {
    await supabase
        .from('tasks')
        .update({'status': status})
        .eq('id', taskId);
  }

  // DELETE TASK
  Future<void> deleteTask(String taskId) async {
    await supabase
        .from('tasks')
        .delete()
        .eq('id', taskId);
  }
}