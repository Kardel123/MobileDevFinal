import 'package:flutter/foundation.dart';

/// Sub-tabs under Academics: Tasks, Projects, Insights, Team.
class AcademicsViewModel extends ChangeNotifier {
  static const int tabCount = 4;

  int _tabIndex = 0;

  int get tabIndex => _tabIndex;

  void selectTasks() => setTabIndex(0);

  void selectProjects() => setTabIndex(1);

  void selectInsights() => setTabIndex(2);

  void selectTeam() => setTabIndex(3);

  void setTabIndex(int index) {
    if (index < 0 || index >= tabCount || index == _tabIndex) return;
    _tabIndex = index;
    notifyListeners();
  }
}
