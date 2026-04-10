import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student_app_context.dart' show EnrolledSubjectRef;
import '../services/subject_chat_service.dart';
import '../theme/app_colors.dart';
import '../viewmodels/student_context_view_model.dart';
import 'subject_chat_room_view.dart';

/// Lists subjects the user can chat in (enrolled + faculty assignments).
class SubjectChatsHubView extends StatelessWidget {
  const SubjectChatsHubView({super.key});

  @override
  Widget build(BuildContext context) {
    final stud = context.watch<StudentContextViewModel>().context;
    final chat = context.read<SubjectChatService>();

    return FutureBuilder<List<EnrolledSubjectRef>>(
      future: chat.fetchChatSubjects(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load chats.\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final subjects = snap.data ?? [];
        if (subjects.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 100),
            children: [
              Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No subject chats yet',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                stud == null
                    ? 'Complete registration and enroll in subjects to see rooms here. Faculty assigned to a subject will also see it here.'
                    : 'Enroll in subjects (or get assigned as faculty) to open a room.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.35),
              ),
            ],
          );
        }

        final primary = stud?.primaryColor ?? AppColors.primary;

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: subjects.length,
          separatorBuilder: (context, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final s = subjects[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: primary.withValues(alpha: 0.15),
                  child: Icon(Icons.forum_outlined, color: primary),
                ),
                title: Text(
                  s.code,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  s.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SubjectChatRoomView(
                        catalogSubjectId: s.id,
                        subjectCode: s.code,
                        subjectName: s.name,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
