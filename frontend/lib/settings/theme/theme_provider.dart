import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("isDarkMode", isDark);
  }

  Future<void> _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isDarkMode = prefs.getBool("isDarkMode");
    if (isDarkMode != null) {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }
}
