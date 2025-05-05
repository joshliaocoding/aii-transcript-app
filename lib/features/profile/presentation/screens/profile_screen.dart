import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

import 'package:ai_transcript_app/shared/providers/language_provider.dart'; // Import language provider

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the localization object
    final l10n = AppLocalizations.of(context)!;
    // Access the LanguageProvider
    final languageProvider = Provider.of<LanguageProvider>(context);

    // Define the list of supported languages for the dropdown
    final List<String> supportedLanguageCodes = [
      'en',
      'zh',
    ]; // Add more as you create .arb files

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)), // Use localized title
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    l10n.profileSectionTitle, // Use localized string
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    l10n.profileSectionDescription, // Use localized string
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40), // Add some space
            Text(
              l10n.languageSettingTitle, // Use localized string for setting title
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value:
                  languageProvider
                      .currentLanguageCode, // Currently selected language
              items:
                  supportedLanguageCodes.map((String code) {
                    return DropdownMenuItem<String>(
                      value: code,
                      child: Text(
                        languageProvider.getLanguageDisplayName(code),
                      ), // Display language name
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  languageProvider.setLocale(
                    Locale(newValue),
                  ); // Change language using provider
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
          ],
        ),
      ),
    );
  }
}
