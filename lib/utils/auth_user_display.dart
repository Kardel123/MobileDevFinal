import 'package:supabase_flutter/supabase_flutter.dart';

/// Display strings derived from [User] (metadata + email).
class AuthUserDisplay {
  const AuthUserDisplay({
    required this.displayName,
    required this.email,
    required this.initials,
    this.programLine,
  });

  final String displayName;
  final String email;
  final String initials;

  /// Optional subtitle (e.g. course) from `user_metadata.program`.
  final String? programLine;

  static AuthUserDisplay fromUser(User? user) {
    if (user == null) {
      return const AuthUserDisplay(
        displayName: 'Student',
        email: '',
        initials: '?',
      );
    }

    final email = user.email ?? '';
    final meta = user.userMetadata;

    var name = _stringMeta(meta, 'full_name');
    if (name.isEmpty) name = _stringMeta(meta, 'name');
    if (name.isEmpty) name = _stringMeta(meta, 'display_name');

    if (name.isEmpty && email.isNotEmpty) {
      final local = email.split('@').first;
      name = _titleCaseFromLocalPart(local);
    }
    if (name.isEmpty) name = 'Student';

    final program = _stringMeta(meta, 'program');
    final programLine = program.isEmpty ? null : program;

    return AuthUserDisplay(
      displayName: name,
      email: email,
      initials: initialsFrom(name, email),
      programLine: programLine,
    );
  }

  static String _stringMeta(Map<String, dynamic>? meta, String key) {
    final v = meta?[key];
    if (v is String) return v.trim();
    return '';
  }

  /// e.g. `john.doe` → `John Doe`, `mary_smith` → `Mary Smith`
  static String _titleCaseFromLocalPart(String local) {
    final cleaned = local.replaceAll('_', ' ').replaceAll('.', ' ');
    return cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map(
          (w) =>
              w.length == 1 ? w.toUpperCase() : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static String initialsFrom(String displayName, String email) {
    final parts = displayName.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    if (email.isNotEmpty) {
      final c = email[0].toUpperCase();
      return c;
    }
    return '?';
  }
}
