import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student_app_context.dart';
import '../utils/auth_user_display.dart';

/// Profile / settings screen state.
class ProfileViewModel extends ChangeNotifier {
  String displayName = 'Student';
  String email = '';
  String program = 'BS Information Technology • Year 3';
  String initials = '?';

  Uint8List? _profilePhotoBytes;

  Uint8List? get profilePhotoBytes => _profilePhotoBytes;

  void setProfilePhotoBytes(Uint8List? bytes) {
    _profilePhotoBytes = bytes;
    notifyListeners();
  }

  void clearProfilePhoto() {
    _profilePhotoBytes = null;
    notifyListeners();
  }

  /// Fills name / email / initials from Supabase Auth (metadata + email).
  void applyAuthUser(User? user) {
    final d = AuthUserDisplay.fromUser(user);
    displayName = d.displayName;
    if (d.email.isNotEmpty) email = d.email;
    initials = d.initials;
    if (d.programLine != null && d.programLine!.isNotEmpty) {
      program = d.programLine!;
    }
    notifyListeners();
  }

  /// College + year level and optional legal name from registration.
  void applyStudentContext(StudentAppContext ctx) {
    program = ctx.programLine;
    if (ctx.fullName != null && ctx.fullName!.isNotEmpty) {
      displayName = ctx.fullName!;
      initials = AuthUserDisplay.initialsFrom(ctx.fullName!, '');
    }
    notifyListeners();
  }

  void resetToGuest() {
    displayName = 'Student';
    email = '';
    program = 'BS Information Technology • Year 3';
    initials = '?';
    _profilePhotoBytes = null;
    notifyListeners();
  }
}
