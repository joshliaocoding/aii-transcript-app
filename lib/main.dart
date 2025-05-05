import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Import this
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import the generated file

import 'package:ai_transcript_app/features/recording/presentation/providers/audio_recording_provider.dart';
import 'package:ai_transcript_app/features/recording/presentation/providers/recording_session_provider.dart';
import 'package:ai_transcript_app/features/meeting_records/presentation/providers/meeting_records_provider.dart';
import 'package:ai_transcript_app/shared/providers/language_provider.dart'; // Import the new provider
import 'package:ai_transcript_app/app_navigation/app_router.dart';

void main() async {
  // Ensure Flutter binding is initialized before using services like path_provider
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AudioRecordingProvider()),
        ChangeNotifierProvider(create: (context) => MeetingRecordsProvider()),
        ChangeNotifierProvider(create: (context) => RecordingSessionProvider()),
        ChangeNotifierProvider(
          create: (context) => LanguageProvider(),
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
    // Consume the LanguageProvider to react to locale changes
    final languageProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp.router(
      routerConfig: goRouter,
      title: 'AI Transcript App', // Consider localizing app title as well
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
      ),
      // Add localization delegates
      localizationsDelegates: const [
        AppLocalizations.delegate, // Generated delegate
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Define supported locales
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('zh', ''), // Chinese (Traditional)
        // Add other supported locales here
      ],
      // Set the locale based on the LanguageProvider
      locale: languageProvider.locale,
    );
  }
}
