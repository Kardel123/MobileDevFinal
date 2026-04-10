/// Row from `subject_chat_messages`.
class SubjectChatMessage {
  const SubjectChatMessage({
    required this.id,
    required this.catalogSubjectId,
    required this.userId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String catalogSubjectId;
  final String userId;
  final String body;
  final DateTime createdAt;

  static SubjectChatMessage fromMap(Map<String, dynamic> m) {
    return SubjectChatMessage(
      id: m['id'] as String,
      catalogSubjectId: m['catalog_subject_id'] as String,
      userId: m['user_id'] as String,
      body: m['body'] as String,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}
