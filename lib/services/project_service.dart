import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectService {
  final supabase = Supabase.instance.client;

  // Project model fields in 'projects' table:
  // id, title, category, status, completion, next_step, avatars (array), created_at

  Future<String?> createProject({
    required String title,
    required String category,
    required String status,
    required int completion,
    required String nextStep,
    required String groupId,
    List<String>? members,
  }) async {
    final response = await supabase.from('projects').insert({
      'title': title,
      'category': category,
      'status': status,
      'completion': completion,
      'next_step': nextStep,
      'group_id': groupId,
      'members': members ?? [],
    }).select();

    if (response.isNotEmpty) {
      return response[0]['id']?.toString();
    }
    return null;
  }

  Future<List<dynamic>> getProjects(String groupId) async {
    final data = await supabase
        .from('projects')
        .select()
        .eq('group_id', groupId)
        .order('created_at', ascending: false);

    return data;
  }

  Future<List<dynamic>> getProjectsByStatus(
    String groupId,
    String status,
  ) async {
    final data = await supabase
        .from('projects')
        .select()
        .eq('group_id', groupId)
        .eq('status', status)
        .order('created_at', ascending: false);

    return data;
  }

  Future<void> updateProject({
    required String projectId,
    String? title,
    String? category,
    String? status,
    int? completion,
    String? nextStep,
    List<String>? members,
  }) async {
    final payload = <String, dynamic>{};

    if (title != null) payload['title'] = title;
    if (category != null) payload['category'] = category;
    if (status != null) payload['status'] = status;
    if (completion != null) payload['completion'] = completion;
    if (nextStep != null) payload['next_step'] = nextStep;
    if (members != null) payload['members'] = members;

    if (payload.isEmpty) return;

    await supabase.from('projects').update(payload).eq('id', projectId);
  }

  Future<void> deleteProject(String projectId) async {
    await supabase.from('projects').delete().eq('id', projectId);
  }

  Future<Map<String, int>> getProjectCounts(String groupId) async {
    final all = await getProjects(groupId);
    final active = await getProjectsByStatus(groupId, 'Active');
    final completed = await getProjectsByStatus(groupId, 'Completed');
    final requests = await getProjectsByStatus(groupId, 'Request');

    return {
      'all': all.length,
      'active': active.length,
      'completed': completed.length,
      'requests': requests.length,
    };
  }

  Future<void> seedSampleProjects(String groupId) async {
    final samples = [
      {
        'title': 'USLS Club Rebranding',
        'category': 'Branding',
        'status': 'Active',
        'completion': 75,
        'next_step': 'Finalize color palette',
        'members': ['JD', 'AS', 'LM'],
      },
      {
        'title': '3D Game Conceptualization',
        'category': 'Dev',
        'status': 'Active',
        'completion': 32,
        'next_step': 'Database schema review',
        'members': ['TD', 'PK'],
      },
      {
        'title': 'Advertisement Campaign',
        'category': 'Marketing',
        'status': 'Active',
        'completion': 90,
        'next_step': 'Copywriting sign-off',
        'members': ['MB', 'JC'],
      },
    ];

    for (final p in samples) {
      await supabase.from('projects').insert({'group_id': groupId, ...p});
    }
  }
}
