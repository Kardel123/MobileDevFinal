import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task_priority.dart';

class TaskService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Legacy shape used by the dev screen: title + group only.
  Future<void> createTask(String title, String groupId) async {
    await createTaskDetailed(
      groupId: groupId,
      title: title,
    );
  }

  /// Full insert matching [supabase/schema.sql].
  Future<void> createTaskDetailed({
    required String groupId,
    required String title,
    String subject = 'GENERAL',
    TaskPriority priority = TaskPriority.med,
    DateTime? dueDate,
    String status = 'pending',
  }) async {
    final uid = _client.auth.currentUser?.id;
    final row = <String, dynamic>{
      'group_id': groupId,
      'title': title.trim(),
      'subject': subject.trim().isEmpty ? 'GENERAL' : subject.trim().toUpperCase(),
      'priority': _priorityToDb(priority),
      'status': status,
      if (dueDate != null) 'due_date': _formatDate(dueDate),
    };
    if (uid != null) {
      row['user_id'] = uid;
    }
    await _client.from('tasks').insert(row);
  }

  Future<List<dynamic>> getTasks(String groupId) async {
    final response = await _client
        .from('tasks')
        .select()
        .eq('group_id', groupId)
        .order('created_at', ascending: false);

    return response;
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await _client.from('tasks').update({'status': status}).eq('id', taskId);
  }

  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String _priorityToDb(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return 'high';
      case TaskPriority.med:
        return 'med';
      case TaskPriority.low:
        return 'low';
    }
  }
}
