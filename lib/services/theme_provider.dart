import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeData get currentTheme {
    AppTheme.isDark = _isDark;
    return AppTheme.theme;
  }

  void toggleTheme() {
    _isDark = !_isDark;
    AppTheme.isDark = _isDark;
    notifyListeners();
  }

  void setDark(bool dark) {
    _isDark = dark;
    AppTheme.isDark = dark;
    notifyListeners();
  }
}
