import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/catalog_subject.dart';
import '../models/college.dart';
import '../models/course_schedule.dart';

/// Reads colleges, catalog subjects, and seeded class schedules from Supabase.
class AcademicCatalogService {
  SupabaseClient get _c => Supabase.instance.client;

  Future<List<College>> fetchColleges() async {
    final rows = await _c.from('colleges').select().order('sort_order');
    return [
      for (final r in rows as List)
        College.fromMap(Map<String, dynamic>.from(r as Map)),
    ];
  }

  Future<List<CatalogSubject>> fetchSubjects({required String collegeId}) async {
    final rows = await _c
        .from('catalog_subjects')
        .select()
        .eq('college_id', collegeId)
        .order('name');
    return [
      for (final r in rows as List)
        CatalogSubject.fromMap(Map<String, dynamic>.from(r as Map)),
    ];
  }

  Future<List<CourseSchedule>> fetchSchedulesForSubject(String subjectId) async {
    final rows = await _c
        .from('course_schedules')
        .select()
        .eq('catalog_subject_id', subjectId)
        .order('day_of_week')
        .order('start_time');
    return [
      for (final r in rows as List)
        CourseSchedule.fromMap(Map<String, dynamic>.from(r as Map)),
    ];
  }
}
