import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define an enum for the theme mode options
enum AppThemeMode { system, light, dark }

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppThemeMode _appThemeMode = AppThemeMode.system; // Store our custom enum

  ThemeMode get themeMode => _themeMode;
  AppThemeMode get appThemeMode => _appThemeMode; // Expose the custom enum

  final String _themeModeKey = 'theme_mode';

  ThemeProvider() {
    _loadThemePreference();
  }

  // Load the saved theme preference
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode =
        prefs.getString(_themeModeKey) ??
        AppThemeMode.system.toString(); // Default to system

    // Convert the saved string back to our enum
    _appThemeMode = AppThemeMode.values.firstWhere(
      (e) => e.toString() == savedThemeMode,
      orElse: () => AppThemeMode.system,
    );

    _updateThemeMode(_appThemeMode);
    notifyListeners();
  }

  // Set the new theme and save the preference
  Future<void> setAppThemeMode(AppThemeMode newThemeMode) async {
    if (_appThemeMode == newThemeMode) return; // No change

    _appThemeMode = newThemeMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeModeKey,
      newThemeMode.toString(),
    ); // Save enum as string

    _updateThemeMode(_appThemeMode);
    notifyListeners();
  }

  // Internal helper to convert our AppThemeMode to Flutter's ThemeMode
  void _updateThemeMode(AppThemeMode appThemeMode) {
    switch (appThemeMode) {
      case AppThemeMode.system:
        _themeMode = ThemeMode.system;
        break;
      case AppThemeMode.light:
        _themeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        _themeMode = ThemeMode.dark;
        break;
    }
  }

  // Helper to get a display name for the theme mode
  String getThemeModeDisplayName(AppThemeMode themeMode) {
    // You'll want to localize these strings using AppLocalizations later
    switch (themeMode) {
      case AppThemeMode.system:
        return 'System Default'; // Localize
      case AppThemeMode.light:
        return 'Light Mode'; // Localize
      case AppThemeMode.dark:
        return 'Dark Mode'; // Localize
    }
  }
}
