import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:ai_transcript_app/features/recording/presentation/providers/audio_recording_provider.dart';
import 'package:ai_transcript_app/features/recording/presentation/providers/recording_session_provider.dart';
import 'package:ai_transcript_app/features/meeting_records/presentation/providers/meeting_records_provider.dart';
import 'package:ai_transcript_app/shared/providers/language_provider.dart';
import 'package:ai_transcript_app/shared/providers/theme_provider.dart'; // Import the new provider
import 'package:ai_transcript_app/app_navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AudioRecordingProvider()),
        ChangeNotifierProvider(create: (context) => MeetingRecordsProvider()),
        ChangeNotifierProvider(create: (context) => RecordingSessionProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
        ), // Register the new provider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(
      context,
    ); // Consume ThemeProvider

    return MaterialApp.router(
      routerConfig: goRouter,
      title: 'AI Transcript App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.lightBlue[100],
          centerTitle: true,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
        ),
        // Define dark theme
        brightness: Brightness.light, // Default brightness
      ),
      darkTheme: ThemeData(
        // Define dark theme
        primarySwatch: Colors.blueGrey, // Example dark theme primary color
        brightness: Brightness.dark,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey[800],
          centerTitle: true,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.blueGrey[300],
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.blueGrey[900],
        ),
        // Customize other dark theme properties as needed
      ),
      themeMode: themeProvider.themeMode, // Use the themeMode from the provider
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('zh', ''), // Mandarin Chinese
        Locale('es', ''), // Spanish
        Locale('ar', ''), // Arabic
        Locale('fr', ''), // French
        Locale('de', ''), // German
        Locale('ja', ''), // Japanese
        Locale('pt', ''), // Portuguese
        Locale('ru', ''), // Russian
        Locale('hi', ''), // Hindi
        // Add more locales if needed (e.g., country-specific variants)
      ],
      locale: languageProvider.locale,
    );
  }
}
