import 'package:flutter/material.dart';

/// App-wide appearance: theme mode and light-mode scaffold tint.
enum AppBackgroundPreset {
  neutral,
  white,
  cream,
  mintWash,
}

class SettingsViewModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppBackgroundPreset _backgroundPreset = AppBackgroundPreset.neutral;

  ThemeMode get themeMode => _themeMode;
  AppBackgroundPreset get backgroundPreset => _backgroundPreset;

  /// Light theme scaffold / main app background.
  Color get lightScaffoldBackground {
    switch (_backgroundPreset) {
      case AppBackgroundPreset.neutral:
        return const Color(0xFFF5F5F5);
      case AppBackgroundPreset.white:
        return Colors.white;
      case AppBackgroundPreset.cream:
        return const Color(0xFFF8F6F0);
      case AppBackgroundPreset.mintWash:
        return const Color(0xFFF0FAF7);
    }
  }

  /// Dark theme scaffold.
  Color get darkScaffoldBackground => const Color(0xFF121E1C);

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void setBackgroundPreset(AppBackgroundPreset preset) {
    if (preset == _backgroundPreset) return;
    _backgroundPreset = preset;
    notifyListeners();
  }

  String labelFor(AppBackgroundPreset p) {
    switch (p) {
      case AppBackgroundPreset.neutral:
        return 'Soft gray (default)';
      case AppBackgroundPreset.white:
        return 'White';
      case AppBackgroundPreset.cream:
        return 'Warm cream';
      case AppBackgroundPreset.mintWash:
        return 'Soft mint';
    }
  }
}
