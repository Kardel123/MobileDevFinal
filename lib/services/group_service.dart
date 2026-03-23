import 'package:supabase_flutter/supabase_flutter.dart';

class GroupService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Lists groups owned by the signed-in user (empty if not signed in).
  Future<List<Map<String, dynamic>>> listMyGroups() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final response = await _client
        .from('groups')
        .select()
        .eq('user_id', uid)
        .order('created_at');

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Creates a group for the current user. Requires [AuthGate] session.
  Future<String> createGroup(String name) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Sign in to create a group.');
    }

    final response = await _client.from('groups').insert({
      'group_name': name.trim(),
      'user_id': uid,
    }).select('id').single();

    return response['id'] as String;
  }

  /// Ensures the user has at least one group; creates "My tasks" if needed.
  Future<String> ensureDefaultGroup() async {
    final existing = await listMyGroups();
    if (existing.isNotEmpty) {
      return existing.first['id'] as String;
    }
    return createGroup('My tasks');
  }
}
