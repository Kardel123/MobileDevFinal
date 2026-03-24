import 'package:flutter/foundation.dart';

import '../models/catalog_subject.dart';
import '../models/college.dart';
import '../models/course_schedule.dart';
import '../services/academic_catalog_service.dart';
import '../services/student_profile_service.dart';

class StudentRegistrationViewModel extends ChangeNotifier {
  StudentRegistrationViewModel(this._catalog, this._profile);

  final AcademicCatalogService _catalog;
  final StudentProfileService _profile;

  List<College> colleges = [];
  List<CatalogSubject> subjects = [];
  final Map<String, List<CourseSchedule>> schedulesBySubjectId = {};

  String? selectedCollegeId;
  String? selectedYearLevel;
  final Set<String> selectedSubjectIds = {};

  bool loadingCatalog = false;
  bool submitting = false;
  String? errorMessage;

  College? get selectedCollege {
    if (selectedCollegeId == null) return null;
    for (final c in colleges) {
      if (c.id == selectedCollegeId) return c;
    }
    return null;
  }

  Future<void> loadColleges() async {
    loadingCatalog = true;
    errorMessage = null;
    notifyListeners();
    try {
      colleges = await _catalog.fetchColleges();
    } catch (e) {
      errorMessage = e.toString();
      colleges = [];
    }
    loadingCatalog = false;
    notifyListeners();
  }

  void selectYearLevel(String? yearLevel) {
    selectedYearLevel = yearLevel;
    notifyListeners();
  }

  Future<void> selectCollege(String? collegeId) async {
    selectedCollegeId = collegeId;
    subjects = [];
    selectedSubjectIds.clear();
    schedulesBySubjectId.clear();
    notifyListeners();

    if (collegeId == null) return;

    loadingCatalog = true;
    errorMessage = null;
    notifyListeners();
    try {
      subjects = await _catalog.fetchSubjects(collegeId: collegeId);
    } catch (e) {
      errorMessage = e.toString();
      subjects = [];
    }
    loadingCatalog = false;
    notifyListeners();
  }

  Future<void> toggleSubject(String subjectId, bool selected) async {
    if (selected) {
      selectedSubjectIds.add(subjectId);
      if (!schedulesBySubjectId.containsKey(subjectId)) {
        try {
          schedulesBySubjectId[subjectId] =
              await _catalog.fetchSchedulesForSubject(subjectId);
        } catch (_) {
          schedulesBySubjectId[subjectId] = [];
        }
      }
    } else {
      selectedSubjectIds.remove(subjectId);
    }
    notifyListeners();
  }

  Future<bool> submit({String? fullName}) async {
    final cid = selectedCollegeId;
    if (cid == null) {
      errorMessage = 'Choose your college.';
      notifyListeners();
      return false;
    }
    final yl = selectedYearLevel;
    if (yl == null || yl.trim().isEmpty) {
      errorMessage = 'Select your year level.';
      notifyListeners();
      return false;
    }
    if (selectedSubjectIds.isEmpty) {
      errorMessage = 'Select at least one subject.';
      notifyListeners();
      return false;
    }

    submitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _profile.saveRegistration(
        collegeId: cid,
        subjectIds: selectedSubjectIds.toList(),
        yearLevel: yl,
        fullName: fullName,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }
}
