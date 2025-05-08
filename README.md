# ai_transcript_app
AI transcript app is a project written by Flutter that can transcribe your meeting audio file into a transcript, then analyze it and summarize it afterward.

## Setup
Getting neccessary dependencies.
```
flutter pub get 
```

## Getting Started
Paste it to your shell in the root path of your project.
```
flutter run
```

## File Structure
This project used a feature-first file structure to organize files. It currently has features such as speech-to-text, recording, and storing in the user's device through SQLite. In the features/ folder, it contains other 3 folders that handle most of the work in this project.

The core/ folder stores how I structured the SQLite database by starting with database_helper.dart. The exceptions.dart file determines how the project handles runtime errors.

In app_router.dart file, I used the go_router package for routing different screens. It is extendable in the future when adding other new screens. Furthermore, the app_router.dart file works with the bottom navigation bar.

lib
├── app_navigation
│   └── app_router.dart
├── core
│   ├── databasea
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
