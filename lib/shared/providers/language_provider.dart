import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;

  final String _languageCodeKey = 'language_code';

  // Define the list of supported language codes
  final List<String> supportedLanguageCodes = [
    'en', // English
    'zh', // Mandarin Chinese
    'es', // Spanish
    'ar', // Arabic
    'fr', // French
    'de', // German
    'ja', // Japanese
    'pt', // Portuguese
    'ru', // Russian
    'hi', // Hindi
  ];

  LanguageProvider() {
    _loadLanguagePreference();
  }

  // Load the saved language preference
  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey);

    // Validate if the saved language code is supported
    if (languageCode != null && supportedLanguageCodes.contains(languageCode)) {
      _locale = Locale(languageCode);
    } else {
      // Default to English if no preference is saved or the saved one is not supported
      _locale = const Locale('en');
    }
    notifyListeners();
  }

  // Set the new language and save the preference
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return; // No change

    // Only set if the new locale's language code is supported
    if (supportedLanguageCodes.contains(newLocale.languageCode)) {
      _locale = newLocale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageCodeKey, newLocale.languageCode);
      notifyListeners();
    } else {
      // Optionally show an error or message if the language is not supported
      print("Language ${newLocale.languageCode} is not supported.");
    }
  }

  // Get the currently selected language code
  String get currentLanguageCode => _locale?.languageCode ?? 'en';

  // Get the display name for a given locale
  String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'zh':
        return '繁體中文'; // Traditional Chinese (or 简体中文 for Simplified)
      case 'es':
        return 'Español'; // Spanish
      case 'ar':
        return 'العربية'; // Arabic
      case 'fr':
        return 'Français'; // French
      case 'de':
        return 'Deutsch'; // German
      case 'ja':
        return '日本語'; // Japanese
      case 'pt':
        return 'Português'; // Portuguese
      case 'ru':
        return 'Русский'; // Russian
      case 'hi':
        return 'हिन्दी'; // Hindi
      // Add other languages here
      default:
        return 'English'; // Default display name
    }
  }

  // You might also want a method to get the list of supported locales
  List<Locale> getSupportedLocales() {
    return supportedLanguageCodes.map((code) => Locale(code)).toList();
  }
}
