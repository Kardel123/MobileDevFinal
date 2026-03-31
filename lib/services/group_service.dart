import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

const _joinCodeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

class GroupService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> listMyGroups() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client.from('groups').select().eq('user_id', uid);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Groups you own plus groups you joined via [joinGroupByCode].
  Future<List<Map<String, dynamic>>> listAccessibleGroups() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final owned = await _client
        .from('groups')
        .select('id, group_name, join_code, user_id')
        .eq('user_id', uid);
    final ownedList = List<Map<String, dynamic>>.from(owned as List);
    final byId = {for (final g in ownedList) g['id'] as String: g};

    final memberRows = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', uid);
    for (final r in memberRows as List) {
      final m = Map<String, dynamic>.from(r as Map);
      final gid = m['group_id'] as String?;
      if (gid == null || byId.containsKey(gid)) continue;
      final row = await _client
          .from('groups')
          .select('id, group_name, join_code, user_id')
          .eq('id', gid)
          .maybeSingle();
      if (row != null) {
        byId[gid] = Map<String, dynamic>.from(row);
      }
    }

    return byId.values.toList();
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
      final id = (existing.first as Map)['id'] as String;
      await ensureJoinCode(id);
      return id;
    }
    final inserted = await _client
        .from('groups')
        .insert({
          'group_name': 'My tasks',
          'user_id': uid,
        })
        .select('id')
        .single();
    final id = inserted['id'] as String;
    await ensureJoinCode(id);
    return id;
  }

  /// Creates a shareable code if the group has none (owner only).
  Future<String?> ensureJoinCode(String groupId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    final row = await _client
        .from('groups')
        .select('join_code, user_id')
        .eq('id', groupId)
        .maybeSingle();
    if (row == null) return null;
    final map = Map<String, dynamic>.from(row);
    if ((map['user_id'] as String?) != uid) {
      return map['join_code'] as String?;
    }

    final existing = map['join_code'] as String?;
    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }

    final rnd = Random.secure();
    String code;
    for (var attempt = 0; attempt < 12; attempt++) {
      final buf = StringBuffer();
      for (var i = 0; i < 8; i++) {
        buf.write(_joinCodeChars[rnd.nextInt(_joinCodeChars.length)]);
      }
      code = buf.toString();
      try {
        await _client.from('groups').update({'join_code': code}).eq('id', groupId);
        return code;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Future<String?> createGroup(String name) async {
    final uid = _client.auth.currentUser?.id;
    final payload = <String, dynamic>{
      'group_name': name,
      ...?uid != null ? {'user_id': uid} : null,
    };
    final response = await _client.from('groups').insert(payload).select();

    if (response.isNotEmpty) {
      final id = response[0]['id']?.toString();
      if (id != null) await ensureJoinCode(id);
      return id;
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

  /// Returns joined group id, or null on error.
  Future<String?> joinGroupByCode(String rawCode) async {
    final code = rawCode.trim();
    if (code.length < 4) return null;
    try {
      final res = await _client.rpc(
        'join_group_by_code',
        params: {'p_code': code},
      );
      if (res == null) return null;
      return res.toString();
    } catch (_) {
      return null;
    }
  }
}
