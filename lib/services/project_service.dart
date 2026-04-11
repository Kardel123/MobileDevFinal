import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectService {
  final supabase = Supabase.instance.client;

  // Project model fields in `projects` table:
  // Due date is embedded in `next_step` unless you use a legacy `due_date` column.

  /// Short title for list rows (DB still requires [title] on many schemas).
  static String shortTitleFromDetails(String details, DateTime dueDate) {
    final first = details.trim().split('\n').first.trim();
    if (first.isEmpty) {
      return 'Project · ${_ymd(dueDate)}';
    }
    return first.length > 90 ? '${first.substring(0, 87)}…' : first;
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const String _dueMagic = '__DUE__:';

  /// Packs due date + details into `next_step` (avoids needing a `due_date` DB column).
  static String packNextStep(DateTime due, String details) {
    final d = DateTime(due.year, due.month, due.day);
    return '$_dueMagic${_ymd(d)}\n${details.trim()}';
  }

  /// Parses [next_step] if it starts with [packNextStep] format.
  static ({DateTime due, String details})? tryUnpackNextStep(String raw) {
    if (!raw.startsWith(_dueMagic)) return null;
    final rest = raw.substring(_dueMagic.length);
    final nl = rest.indexOf('\n');
    if (nl < 0) return null;
    final dateStr = rest.substring(0, nl).trim();
    final body = rest.substring(nl + 1);
    try {
      final parsed = DateTime.parse(dateStr);
      final due = DateTime(parsed.year, parsed.month, parsed.day);
      return (due: due, details: body.trim());
    } catch (_) {
      return null;
    }
  }

  /// Resolves due date + details from a `projects` row (packed, legacy column, or plain text).
  static ({DateTime due, String details}) parseProjectContent(
    Map<String, dynamic> row,
  ) {
    final rawNext = (row['next_step'] as String?) ?? '';
    final unpacked = tryUnpackNextStep(rawNext);
    if (unpacked != null) return unpacked;

    final desc = row['description'];
    String details;
    if (desc is String && desc.trim().isNotEmpty) {
      details = desc.trim();
    } else {
      details = rawNext.trim();
    }

    DateTime due;
    final dr = row['due_date'];
    if (dr != null) {
      try {
        final parsed = DateTime.parse(dr.toString());
        due = DateTime(parsed.year, parsed.month, parsed.day);
      } catch (_) {
        due = DateTime.now();
      }
    } else {
      due = DateTime.now();
    }

    return (due: due, details: details);
  }

  Future<String?> createProject({
    required String groupId,
    required DateTime dueDate,
    required String details,
    String status = 'Active',
    List<String>? members,
  }) async {
    final d = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final response = await supabase.from('projects').insert({
      'group_id': groupId,
      'title': shortTitleFromDetails(details, d),
      'category': 'Project',
      'status': status,
      'completion': 0,
      'next_step': packNextStep(d, details.trim()),
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
    String? description,
    DateTime? dueDate,
    List<String>? members,
  }) async {
    final payload = <String, dynamic>{};

    if (title != null) payload['title'] = title;
    if (category != null) payload['category'] = category;
    if (status != null) payload['status'] = status;
    if (completion != null) payload['completion'] = completion;
    if (description != null) payload['description'] = description;
    if (dueDate != null && nextStep != null) {
      payload['next_step'] = packNextStep(
        DateTime(dueDate.year, dueDate.month, dueDate.day),
        nextStep,
      );
    } else if (nextStep != null) {
      payload['next_step'] = nextStep;
    }
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
    final due = DateTime.now().add(const Duration(days: 14));
    final samples = [
      {
        'title': 'USLS Club Rebranding',
        'category': 'Branding',
        'status': 'Active',
        'completion': 75,
        'next_step': packNextStep(due, 'Finalize color palette'),
        'members': ['JD', 'AS', 'LM'],
      },
      {
        'title': '3D Game Conceptualization',
        'category': 'Dev',
        'status': 'Active',
        'completion': 32,
        'next_step': packNextStep(due, 'Database schema review'),
        'members': ['TD', 'PK'],
      },
      {
        'title': 'Advertisement Campaign',
        'category': 'Marketing',
        'status': 'Active',
        'completion': 90,
        'next_step': packNextStep(due, 'Copywriting sign-off'),
        'members': ['MB', 'JC'],
      },
    ];

    for (final p in samples) {
      await supabase.from('projects').insert({'group_id': groupId, ...p});
    }
  }
}
