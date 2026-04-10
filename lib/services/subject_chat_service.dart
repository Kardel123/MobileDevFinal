import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student_app_context.dart';
import '../models/subject_chat_message.dart';

/// Per-subject chat for enrolled students and assigned faculty (see `subject_faculty`).
class SubjectChatService {
  SupabaseClient get _c => Supabase.instance.client;

  /// Subjects the current user can open a chat for (enrolled + assigned as faculty).
  Future<List<EnrolledSubjectRef>> fetchChatSubjects() async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return [];

    final fromEnroll = await _c
        .from('student_enrollments')
        .select('catalog_subject_id')
        .eq('user_id', uid);

    final fromFaculty = await _c
        .from('subject_faculty')
        .select('catalog_subject_id')
        .eq('faculty_user_id', uid);

    final ids = <String>{};
    for (final r in fromEnroll as List) {
      final id = (r as Map)['catalog_subject_id'] as String?;
      if (id != null) ids.add(id);
    }
    for (final r in fromFaculty as List) {
      final id = (r as Map)['catalog_subject_id'] as String?;
      if (id != null) ids.add(id);
    }

    if (ids.isEmpty) return [];

    final rows = await _c
        .from('catalog_subjects')
        .select('id, name, code')
        .inFilter('id', ids.toList());

    final out = <EnrolledSubjectRef>[];
    for (final r in rows as List) {
      final m = Map<String, dynamic>.from(r as Map);
      out.add(
        EnrolledSubjectRef(
          id: m['id'] as String,
          name: m['name'] as String,
          code: m['code'] as String,
        ),
      );
    }
    out.sort((a, b) => a.code.compareTo(b.code));
    return out;
  }

  /// Faculty user ids for this subject (for "Teacher" badge + delete rules in UI).
  Future<Set<String>> fetchFacultyIdsForSubject(String catalogSubjectId) async {
    final rows = await _c
        .from('subject_faculty')
        .select('faculty_user_id')
        .eq('catalog_subject_id', catalogSubjectId);
    final set = <String>{};
    for (final r in rows as List) {
      final id = (r as Map)['faculty_user_id'] as String?;
      if (id != null) set.add(id);
    }
    return set;
  }

  Future<bool> isCurrentUserFacultyForSubject(String catalogSubjectId) async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return false;
    final row = await _c
        .from('subject_faculty')
        .select('faculty_user_id')
        .eq('catalog_subject_id', catalogSubjectId)
        .eq('faculty_user_id', uid)
        .maybeSingle();
    return row != null;
  }

  Future<List<SubjectChatMessage>> fetchMessages(String catalogSubjectId,
      {int limit = 100}) async {
    final data = await _c
        .from('subject_chat_messages')
        .select()
        .eq('catalog_subject_id', catalogSubjectId)
        .order('created_at', ascending: true)
        .limit(limit);
    return [
      for (final r in data as List)
        SubjectChatMessage.fromMap(Map<String, dynamic>.from(r as Map)),
    ];
  }

  Future<void> sendMessage({
    required String catalogSubjectId,
    required String body,
  }) async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) throw StateError('Not signed in');
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    await _c.from('subject_chat_messages').insert({
      'catalog_subject_id': catalogSubjectId,
      'user_id': uid,
      'body': trimmed,
    });
  }

  Future<void> deleteMessage(String messageId) async {
    await _c.from('subject_chat_messages').delete().eq('id', messageId);
  }

  /// Postgres Realtime for this subject only. Unsubscribe with
  /// [SupabaseClient.removeChannel] when leaving the room.
  RealtimeChannel subscribeToMessages({
    required String catalogSubjectId,
    required void Function(PostgresChangePayload payload) onPayload,
    void Function(RealtimeSubscribeStatus status, Object? error)? onSubscribeStatus,
  }) {
    final channel = _c.channel('subject_chat:$catalogSubjectId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'subject_chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'catalog_subject_id',
            value: catalogSubjectId,
          ),
          callback: onPayload,
        )
        .subscribe(onSubscribeStatus);
    return channel;
  }

  /// Merge a Realtime payload into the current list (dedupes inserts, ordered by time).
  static List<SubjectChatMessage> applyRealtimePayload(
    List<SubjectChatMessage> current,
    PostgresChangePayload payload,
  ) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
      case PostgresChangeEvent.update:
        final m = _tryMessageFromRow(payload.newRecord);
        if (m == null) return current;
        if (payload.eventType == PostgresChangeEvent.insert &&
            current.any((x) => x.id == m.id)) {
          return current;
        }
        final without = current.where((x) => x.id != m.id).toList();
        final next = [...without, m];
        next.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return next;
      case PostgresChangeEvent.delete:
        final id = payload.oldRecord['id'] as String?;
        if (id == null) return current;
        return current.where((m) => m.id != id).toList();
      case PostgresChangeEvent.all:
        return current;
    }
  }

  static SubjectChatMessage? _tryMessageFromRow(Map<String, dynamic> row) {
    if (row.isEmpty) return null;
    try {
      return SubjectChatMessage.fromMap(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }
}
