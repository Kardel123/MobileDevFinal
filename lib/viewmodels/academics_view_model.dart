import 'package:flutter/foundation.dart';

/// Which sub-tab is shown under Academics (Tasks vs Projects).
class AcademicsViewModel extends ChangeNotifier {
  int _tabIndex = 0;

  int get tabIndex => _tabIndex;

  void selectTasks() {
    if (_tabIndex == 0) return;
    _tabIndex = 0;
    notifyListeners();
  }

  void selectProjects() {
    if (_tabIndex == 1) return;
    _tabIndex = 1;
    notifyListeners();
  }

  void setTabIndex(int index) {
    if (index < 0 || index > 1 || index == _tabIndex) return;
    _tabIndex = index;
    notifyListeners();
  }
}
