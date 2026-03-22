import 'package:supabase_flutter/supabase_flutter.dart';

class GroupService {
  final supabase = Supabase.instance.client;

  Future<String?> createGroup(String name) async {
    final response = await supabase
        .from('groups')
        .insert({
          'group_name': name,
        })
        .select();

    return response[0]['id'];
  }
}