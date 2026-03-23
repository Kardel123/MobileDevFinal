import 'package:supabase_flutter/supabase_flutter.dart';

class GroupService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> listMyGroups() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client.from('groups').select().eq('user_id', uid);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Ensures a personal default group exists for the signed-in user (RLS).
  Future<String> ensureDefaultGroup() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }
    final uid = user.id;
    final existing = await _client
        .from('groups')
        .select('id')
        .eq('user_id', uid)
        .limit(1);
    if (existing.isNotEmpty) {
      return (existing.first as Map)['id'] as String;
    }
    final inserted = await _client
        .from('groups')
        .insert({
          'group_name': 'My tasks',
          'user_id': uid,
        })
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  Future<String?> createGroup(String name) async {
    final uid = _client.auth.currentUser?.id;
    final payload = <String, dynamic>{
      'group_name': name,
      ...?uid != null ? {'user_id': uid} : null,
    };
    final response = await _client.from('groups').insert(payload).select();

    if (response.isNotEmpty) {
      return response[0]['id']?.toString();
    }
    return null;
  }

  Future<List<dynamic>> getGroups() async {
    final response = await _client
        .from('groups')
        .select()
        .order('created_at', ascending: false);
    return response;
  }
}
