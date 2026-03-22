import 'package:supabase_flutter/supabase_flutter.dart';

class GroupService {
  final supabase = Supabase.instance.client;

  Future<String?> createGroup(String name) async {
    final response = await supabase.from('groups').insert({
      'group_name': name,
    }).select();

    if (response.isNotEmpty) {
      return response[0]['id']?.toString();
    }
    return null;
  }

  Future<List<dynamic>> getGroups() async {
    final response = await supabase
        .from('groups')
        .select()
        .order('created_at', ascending: false);
    return response;
  }
}
