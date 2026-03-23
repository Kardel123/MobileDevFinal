import 'package:supabase_flutter/supabase_flutter.dart';

class MessageService {
  final supabase = Supabase.instance.client;

  Future<void> sendMessage({
    required String groupId,
    required String message,
    required String userId,
  }) async {
    await supabase.from('messages').insert({
      'group_id': groupId,
      'message': message,
      'sender_id': userId,
    });
  }

  Stream<List<Map<String, dynamic>>> getMessages(String groupId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId);
  }
}