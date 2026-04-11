/// Row from `subject_chat_messages`.
/// [senderDisplayName] is set at send time so readers see names without querying profiles.
class SubjectChatMessage {
  const SubjectChatMessage({
    required this.id,
    required this.catalogSubjectId,
    required this.userId,
    required this.body,
    required this.createdAt,
    this.senderDisplayName,
  });

  final String id;
  final String catalogSubjectId;
  final String userId;
  final String body;
  final DateTime createdAt;

  /// Denormalized label from the sender (preferred for display).
  final String? senderDisplayName;

  static SubjectChatMessage fromMap(Map<String, dynamic> m) {
    final rawName = m['sender_display_name'];
    String? senderName;
    if (rawName is String && rawName.trim().isNotEmpty) {
      senderName = rawName.trim();
    }
    return SubjectChatMessage(
      id: m['id'] as String,
      catalogSubjectId: m['catalog_subject_id'] as String,
      userId: m['user_id'] as String,
      body: m['body'] as String,
      createdAt: DateTime.parse(m['created_at'] as String),
      senderDisplayName: senderName,
    );
  }
}
