import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course_schedule.dart';
import '../models/student_app_context.dart';

/// Persists student college + subject selections after auth.
class StudentProfileService {
  SupabaseClient get _c => Supabase.instance.client;

  Future<bool> hasCompletedRegistration() async {
    final user = _c.auth.currentUser;
    if (user == null) return false;
    final row = await _c
        .from('student_profiles')
        .select('user_id')
        .eq('user_id', user.id)
        .maybeSingle();
    return row != null;
  }

  Future<void> saveRegistration({
    required String collegeId,
    required List<String> subjectIds,
    required String yearLevel,
    String? fullName,
  }) async {
    final user = _c.auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    final uid = user.id;

    await _c.from('student_profiles').insert({
      'user_id': uid,
      'college_id': collegeId,
      'year_level': yearLevel.trim(),
      if (fullName != null && fullName.trim().isNotEmpty)
        'full_name': fullName.trim(),
    });

    if (subjectIds.isEmpty) return;

    await _c.from('student_enrollments').insert(
      [
        for (final sid in subjectIds)
          {
            'user_id': uid,
            'catalog_subject_id': sid,
          },
      ],
    );
  }

  /// Profile row + college + enrollments + weekly class rows for the calendar.
  Future<StudentAppContext?> fetchStudentAppContext() async {
    final user = _c.auth.currentUser;
    if (user == null) return null;

    final row = await _c
        .from('student_profiles')
        .select(
          'full_name, year_level, college_id, colleges(id, name, primary_hex, accent_hex)',
        )
        .eq('user_id', user.id)
        .maybeSingle();

    if (row == null) return null;

    final collegeRaw = row['colleges'];
    if (collegeRaw is! Map) return null;
    final collegeMap = Map<String, dynamic>.from(collegeRaw);

    final yearRaw = row['year_level'];
    final yearLevel = yearRaw is String ? yearRaw.trim() : '';

    final nameRaw = row['full_name'];
    final fullName = nameRaw is String && nameRaw.trim().isNotEmpty
        ? nameRaw.trim()
        : null;

    final enrRows = await _c
        .from('student_enrollments')
        .select('catalog_subject_id')
        .eq('user_id', user.id);

    final subjectIds = <String>[];
    for (final e in enrRows as List) {
      final m = Map<String, dynamic>.from(e as Map);
      final sid = m['catalog_subject_id'] as String?;
      if (sid != null) subjectIds.add(sid);
    }

    if (subjectIds.isEmpty) {
      return StudentAppContext(
        collegeId: collegeMap['id'] as String,
        collegeName: collegeMap['name'] as String,
        primaryHex: collegeMap['primary_hex'] as String,
        accentHex: collegeMap['accent_hex'] as String,
        yearLevel: yearLevel,
        fullName: fullName,
        subjects: const [],
        weeklySlots: const [],
      );
    }

    final subRows = await _c
        .from('catalog_subjects')
        .select('id, name, code')
        .inFilter('id', subjectIds);

    final subjects = <EnrolledSubjectRef>[];
    final codeById = <String, String>{};
    final nameById = <String, String>{};
    for (final r in subRows as List) {
      final m = Map<String, dynamic>.from(r as Map);
      final id = m['id'] as String;
      final code = m['code'] as String;
      final name = m['name'] as String;
      codeById[id] = code;
      nameById[id] = name;
      subjects.add(EnrolledSubjectRef(id: id, name: name, code: code));
    }

    final schedRows = await _c
        .from('course_schedules')
        .select()
        .inFilter('catalog_subject_id', subjectIds);

    final weeklySlots = <WeeklyClassSlot>[];
    for (final r in schedRows as List) {
      final m = Map<String, dynamic>.from(r as Map);
      final sid = m['catalog_subject_id'] as String;
      final code = codeById[sid] ?? '';
      final sname = nameById[sid] ?? '';
      final cs = CourseSchedule.fromMap(m);
      weeklySlots.add(
        WeeklyClassSlot(
          dayOfWeek: cs.dayOfWeek,
          startHour: _timeStringToFractionalHour(cs.startTime),
          endHour: _timeStringToFractionalHour(cs.endTime),
          title: '$code — $sname',
          subtitle: '${cs.sessionLabel} • ${cs.room}',
        ),
      );
    }

    return StudentAppContext(
      collegeId: collegeMap['id'] as String,
      collegeName: collegeMap['name'] as String,
      primaryHex: collegeMap['primary_hex'] as String,
      accentHex: collegeMap['accent_hex'] as String,
      yearLevel: yearLevel,
      fullName: fullName,
      subjects: subjects,
      weeklySlots: weeklySlots,
    );
  }
}

double _timeStringToFractionalHour(String t) {
  final parts = t.split(':');
  final h = int.tryParse(parts[0]) ?? 0;
  final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return h + m / 60.0;
}
