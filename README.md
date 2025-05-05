# ai_transcript_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## File Structure
lib
├── app_navigation
│   └── app_router.dart
├── core
│   ├── database
│   │   └── database_helper.dart
│   ├── errors
│   │   └── exceptions.dart
│   └── utils
│       └── date_formatting.dart
├── features
│   ├── meeting_records
│   │   ├── data
│   │   │   ├── datasources
│   │   │   │   └── meeting_record_local_data_source.dart
│   │   │   ├── models
│   │   │   │   └── meeting_record_model.dart
│   │   │   └── repositories
│   │   │       └── meeting_record_repository_impl.dart
│   │   ├── domain
│   │   │   ├── entities
│   │   │   │   └── meeting_record.dart
│   │   │   ├── repositories
│   │   │   │   └── meeting_record_repository.dart
│   │   │   └── usecases
│   │   │       ├── delete_meeting_record.dart
│   │   │       ├── get_all_meeting_records.dart
│   │   │       ├── save_meeting_record.dart
│   │   │       └── toggle_meeting_favorite.dart
│   │   └── presentation
│   │       ├── providers
│   │       │   └── meeting_records_provider.dart
│   │       ├── screens
│   │       │   ├── home_screen.dart
│   │       │   ├── meeting_details_screen.dart
│   │       │   └── saved_screen.dart
│   │       └── widgets
│   │           └── meeting_card.dart
│   ├── profile
│   │   └── presentation
│   │       └── screens
│   │           └── profile_screen.dart
│   └── recording
│       ├── domain
│       │   └── usecases
│       └── presentation
│           ├── providers
│           │   └── audio_recording_provider.dart
│           ├── screens
│           │   └── record_screen.dart
│           └── widgets
│               └── record_button.dart
├── main.dart
└── shared
    ├── services
    └── widgets

33 directories, 23 files
