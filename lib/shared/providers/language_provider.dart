import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;

  final String _languageCodeKey = 'language_code';

  LanguageProvider() {
    _loadLanguagePreference();
  }

  // Load the saved language preference
  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey);
    if (languageCode != null) {
      _locale = Locale(languageCode);
    } else {
      // Default to system locale or a specific locale if no preference is saved
      // For simplicity, we'll default to English if no preference is saved.
      _locale = const Locale('en');
    }
    notifyListeners();
  }

  // Set the new language and save the preference
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return; // No change

    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, newLocale.languageCode);
    notifyListeners();
  }

  // Get the currently selected language code
  String get currentLanguageCode => _locale?.languageCode ?? 'en';

  // Get the display name for a given locale (basic implementation)
  String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'zh':
        return '繁體中文'; // Traditional Chinese
      // Add other languages here
      default:
        return 'English';
    }
  }
}
