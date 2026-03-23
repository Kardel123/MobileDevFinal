import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task_priority.dart';

class TaskService {
  SupabaseClient get _client => Supabase.instance.client;

  // Task model fields in 'tasks' table:
  // id, title, description, subject, priority, due_date, status, group_id, created_at

  Future<String?> createTask({
    required String title,
    required String groupId,
    String? description,
    String? subject,
    String priority = 'Medium',
    DateTime? dueDate,
    String status = 'Pending',
  }) async {
    final response = await supabase.from('tasks').insert({
      'title': title,
      'description': description,
      'subject': subject,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'status': status,
      'group_id': groupId,
    }).select();

    if (response.isNotEmpty) {
      return response[0]['id']?.toString();
    }
    return null;
  }

  Future<List<dynamic>> getTasks(String groupId) async {
    final data = await supabase
        .from('tasks')
        .select()
        .eq('group_id', groupId)
        .order('due_date', ascending: true);

    return data;
  }

  Future<List<dynamic>> getTasksByStatus(String groupId, String status) async {
    final data = await supabase
        .from('tasks')
        .select()
        .eq('group_id', groupId)
        .eq('status', status)
        .order('due_date', ascending: true);

    return data;
  }

  Future<List<dynamic>> getUpcomingDeadlines(
    String groupId, {
    int withinDays = 7,
  }) async {
    final now = DateTime.now().toUtc();
    final to = now.add(Duration(days: withinDays));

    final data = await supabase
        .from('tasks')
        .select()
        .eq('group_id', groupId)
        .gte('due_date', now.toIso8601String())
        .lte('due_date', to.toIso8601String())
        .order('due_date', ascending: true);

    return data;
  }

  Future<List<dynamic>> getSemesterTasks(
    String groupId,
    String semesterTag,
  ) async {
    // if semester is stored in subject or inside group details, this function can be adapted
    final data = await supabase
        .from('tasks')
        .select()
        .eq('group_id', groupId)
        .like('subject', '%$semesterTag%')
        .order('due_date', ascending: true);

    return data;
  }

  Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? subject,
    String? priority,
    DateTime? dueDate,
    String? status,
  }) async {
    final Map<String, dynamic> payload = {};

    if (title != null) payload['title'] = title;
    if (description != null) payload['description'] = description;
    if (subject != null) payload['subject'] = subject;
    if (priority != null) payload['priority'] = priority;
    if (dueDate != null) payload['due_date'] = dueDate.toIso8601String();
    if (status != null) payload['status'] = status;

    if (payload.isEmpty) return;

    await supabase.from('tasks').update(payload).eq('id', taskId);
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await supabase.from('tasks').update({'status': status}).eq('id', taskId);
  }

  Future<void> deleteTask(String taskId) async {
    await supabase.from('tasks').delete().eq('id', taskId);
  }

  Future<Map<String, int>> getTaskCounts(String groupId) async {
    final allTasks = await getTasks(groupId);
    final pending = await getTasksByStatus(groupId, 'Pending');
    final done = await getTasksByStatus(groupId, 'Done');

    return {
      'total': allTasks.length,
      'pending': pending.length,
      'done': done.length,
    };
  }

  Future<void> seedSampleTasks(String groupId) async {
    final now = DateTime.now().toUtc();
    final samples = [
      {
        'title': 'Final Project Proposal',
        'description': 'Mobile Computing final project proposal submission.',
        'subject': 'Mobile Computing',
        'priority': 'High',
        'due_date': now.add(const Duration(days: 2)).toIso8601String(),
        'status': 'Pending',
      },
      {
        'title': 'Database Schema Design',
        'description': 'Design schema for the course DB systems essay task.',
        'subject': 'Database Systems',
        'priority': 'Medium',
        'due_date': now.add(const Duration(days: 1)).toIso8601String(),
        'status': 'Pending',
      },
      {
        'title': 'Community Outreach Essay',
        'description': 'Write essay for religion class outreach.',
        'subject': 'Religion 3',
        'priority': 'Low',
        'due_date': now.add(const Duration(days: 5)).toIso8601String(),
        'status': 'Pending',
      },
      {
        'title': 'Problem Set 8: Integration',
        'description': 'Complete Calc III problem set.',
        'subject': 'Calculus III',
        'priority': 'Medium',
        'due_date': now.add(const Duration(days: 4)).toIso8601String(),
        'status': 'Pending',
      },
      {
        'title': 'Reading: "The Great Gatsby"',
        'description': 'Finish literature reading.',
        'subject': 'English Literature',
        'priority': 'Low',
        'due_date': now.add(const Duration(days: 7)).toIso8601String(),
        'status': 'Pending',
      },
    ];

    for (final t in samples) {
      await supabase.from('tasks').insert({'group_id': groupId, ...t});
    }
  }
}
