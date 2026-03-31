/// Stored in `student_profiles.app_role` (set in Supabase; default student).
enum AppRole {
  student,
  faculty,
  admin,
}

extension AppRoleLabel on AppRole {
  String get displayLabel {
    switch (this) {
      case AppRole.student:
        return 'Student';
      case AppRole.faculty:
        return 'Faculty';
      case AppRole.admin:
        return 'Admin';
    }
  }
}

AppRole appRoleFromDb(String? raw) {
  switch ((raw ?? 'student').toLowerCase()) {
    case 'faculty':
      return AppRole.faculty;
    case 'admin':
      return AppRole.admin;
    default:
      return AppRole.student;
  }
}
