import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:ai_transcript_app/shared/providers/language_provider.dart';
import 'package:ai_transcript_app/shared/providers/theme_provider.dart'; // Import ThemeProvider

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(
      context,
    ); // Consume ThemeProvider

    final List<String> supportedLanguageCodes = ['en', 'zh'];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          // Changed Column to ListView to prevent overflow with more settings
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    l10n.profileSectionTitle,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    l10n.profileSectionDescription,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Language Setting
            Text(
              l10n.languageSettingTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: languageProvider.currentLanguageCode,
              items:
                  supportedLanguageCodes.map((String code) {
                    return DropdownMenuItem<String>(
                      value: code,
                      child: Text(
                        languageProvider.getLanguageDisplayName(code),
                      ),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  languageProvider.setLocale(Locale(newValue));
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 15,
                ),
              ),
            ),
            const SizedBox(height: 24), // Add space between settings sections
            // Theme Setting
            Text(
              l10n.themeSettingTitle, // Localize this title
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AppThemeMode>(
              // Use our custom enum
              value: themeProvider.appThemeMode, // Use the custom enum value
              items:
                  AppThemeMode.values.map((AppThemeMode mode) {
                    return DropdownMenuItem<AppThemeMode>(
                      value: mode,
                      child: Text(
                        themeProvider.getThemeModeDisplayName(mode),
                      ), // Use helper for display name
                    );
                  }).toList(),
              onChanged: (AppThemeMode? newValue) {
                if (newValue != null) {
                  themeProvider.setAppThemeMode(
                    newValue,
                  ); // Set theme using provider
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 15,
                ),
              ),
            ),

            // Add other profile settings here later
            const SizedBox(height: 24), // Space at the bottom
          ],
        ),
      ),
    );
  }
}
