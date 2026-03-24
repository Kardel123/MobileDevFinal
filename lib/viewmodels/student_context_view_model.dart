import 'package:flutter/foundation.dart';

import '../models/student_app_context.dart';
import '../services/student_profile_service.dart';

/// Cached profile + enrollments for dashboard, calendar, academics, profile.
class StudentContextViewModel extends ChangeNotifier {
  StudentContextViewModel(this._profile);

  final StudentProfileService _profile;

  StudentAppContext? context;
  bool loading = false;
  String? errorMessage;

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      context = await _profile.fetchStudentAppContext();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
      context = null;
    }
    loading = false;
    notifyListeners();
  }

  void clear() {
    context = null;
    errorMessage = null;
    notifyListeners();
  }
}
