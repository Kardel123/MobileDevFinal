import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduleService {
  final supabase = Supabase.instance.client;

  // Schedule model fields in 'schedule_events' table:
  // id, title, course, location, event_type, start_time, end_time, group_id, created_at

  Future<String?> createScheduleEvent({
    required String title,
    required String course,
    required String location,
    required String eventType,
    required DateTime startTime,
    required DateTime endTime,
    required String groupId,
  }) async {
    final response = await supabase.from('schedule_events').insert({
      'title': title,
      'course': course,
      'location': location,
      'event_type': eventType,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'group_id': groupId,
    }).select();

    if (response.isNotEmpty) {
      return response[0]['id']?.toString();
    }
    return null;
  }

  Future<List<dynamic>> getWeeklySchedule(
    String groupId,
    DateTime weekStart,
    DateTime weekEnd,
  ) async {
    final data = await supabase
        .from('schedule_events')
        .select()
        .eq('group_id', groupId)
        .gte('start_time', weekStart.toIso8601String())
        .lte('end_time', weekEnd.toIso8601String())
        .order('start_time', ascending: true);

    return data;
  }

  Future<List<dynamic>> getDaySchedule(String groupId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day).toUtc();
    final end = start.add(const Duration(days: 1));

    final data = await supabase
        .from('schedule_events')
        .select()
        .eq('group_id', groupId)
        .gte('start_time', start.toIso8601String())
        .lt('start_time', end.toIso8601String())
        .order('start_time', ascending: true);

    return data;
  }

  Future<void> updateScheduleEvent({
    required String eventId,
    String? title,
    String? course,
    String? location,
    String? eventType,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final payload = <String, dynamic>{};

    if (title != null) payload['title'] = title;
    if (course != null) payload['course'] = course;
    if (location != null) payload['location'] = location;
    if (eventType != null) payload['event_type'] = eventType;
    if (startTime != null) payload['start_time'] = startTime.toIso8601String();
    if (endTime != null) payload['end_time'] = endTime.toIso8601String();

    if (payload.isEmpty) return;

    await supabase.from('schedule_events').update(payload).eq('id', eventId);
  }

  Future<void> deleteScheduleEvent(String eventId) async {
    await supabase.from('schedule_events').delete().eq('id', eventId);
  }

  Future<void> seedSampleSchedule(String groupId) async {
    final now = DateTime.now().toUtc();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final samples = [
      {
        'title': 'Data Science 101',
        'course': 'Data Science 101',
        'location': 'Rm 402',
        'event_type': 'Lecture',
        'start_time': monday.add(const Duration(days: 1, hours: 8)),
        'end_time': monday.add(const Duration(days: 1, hours: 9)),
      },
      {
        'title': 'Data Science 101',
        'course': 'Data Science 101',
        'location': 'Rm 402',
        'event_type': 'Lecture',
        'start_time': monday.add(const Duration(days: 2, hours: 8)),
        'end_time': monday.add(const Duration(days: 2, hours: 9)),
      },
      {
        'title': 'Economics II',
        'course': 'Economics II',
        'location': 'Lecture Hall A',
        'event_type': 'Lecture',
        'start_time': monday.add(const Duration(days: 1, hours: 11)),
        'end_time': monday.add(const Duration(days: 1, hours: 12)),
      },
      {
        'title': 'Economics II',
        'course': 'Economics II',
        'location': 'Lecture Hall A',
        'event_type': 'Lecture',
        'start_time': monday.add(const Duration(days: 2, hours: 11)),
        'end_time': monday.add(const Duration(days: 2, hours: 12)),
      },
      {
        'title': 'Library Session',
        'course': 'Calculus Review',
        'location': 'Rm 302',
        'event_type': 'Session',
        'start_time': monday.add(const Duration(days: 1, hours: 14)),
        'end_time': monday.add(const Duration(days: 1, hours: 15)),
      },
      {
        'title': 'Computer Lab',
        'course': 'Comp Sci Lab',
        'location': 'Bldg 5',
        'event_type': 'Lab',
        'start_time': monday.add(const Duration(days: 3, hours: 14)),
        'end_time': monday.add(const Duration(days: 3, hours: 16)),
      },
    ];

    for (final e in samples) {
      await supabase.from('schedule_events').insert({
        'group_id': groupId,
        'title': e['title'],
        'course': e['course'],
        'location': e['location'],
        'event_type': e['event_type'],
        'start_time': (e['start_time'] as DateTime).toIso8601String(),
        'end_time': (e['end_time'] as DateTime).toIso8601String(),
      });
    }
  }
}
