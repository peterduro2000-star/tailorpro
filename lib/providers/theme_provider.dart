import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _darkModeKey = 'dark_mode_enabled';

  bool? _darkModeEnabled;

  ThemeProvider() {
    _loadThemePreference();
  }

  ThemeMode get themeMode {
    if (_darkModeEnabled == null) return ThemeMode.system;
    return _darkModeEnabled! ? ThemeMode.dark : ThemeMode.light;
  }

  bool isDarkMode(BuildContext context) {
    return _darkModeEnabled ??
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  Future<void> setDarkMode(bool enabled) async {
    _darkModeEnabled = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _darkModeEnabled = prefs.getBool(_darkModeKey);
    notifyListeners();
  }
}
