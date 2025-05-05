import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'package:ai_transcript_app/features/meeting_records/domain/entities/meeting_record.dart';
import 'package:ai_transcript_app/features/meeting_records/presentation/providers/meeting_records_provider.dart';
import 'package:ai_transcript_app/features/recording/presentation/providers/audio_recording_provider.dart';
import 'package:ai_transcript_app/core/utils/date_formatting.dart'; // Import date formatting utility

enum RecordingState {
  idle,
  recording,
  stopped, // Recording finished, ready to save
  saving,
  saved,
  error,
}

class RecordingSessionProvider extends ChangeNotifier {
  final Record _audioRecorder = Record();
  RecordingState _state = RecordingState.idle;
  String? _recordFilePath;
  DateTime? _recordingStartTime;
  DateTime? _recordingEndTime;
  String _errorMessage = '';

  // Timer for recording duration display
  Timer? _timer;
  int _currentDurationInSeconds = 0;

  // Dependencies (AudioRecordingProvider will be passed in or accessed via Provider)
  // MeetingRecordsProvider will be accessed in saveRecording

  RecordingState get state => _state;
  bool get isRecording => _state == RecordingState.recording;
  bool get hasRecorded => _state == RecordingState.stopped;
  String? get recordFilePath => _recordFilePath;
  DateTime? get recordingStartTime => _recordingStartTime;
  DateTime? get recordingEndTime => _recordingEndTime;
  String get errorMessage => _errorMessage;
  int get currentDurationInSeconds => _currentDurationInSeconds;

  // Formatted duration string
  String get formattedDuration {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    int hours = _currentDurationInSeconds ~/ 3600;
    int minutes = (_currentDurationInSeconds % 3600) ~/ 60;
    int remainingSeconds = _currentDurationInSeconds % 60;
    return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(remainingSeconds)}";
  }

  // Initialize the recorder (can be done here or in a separate init method)
  RecordingSessionProvider();

  // Dispose of resources
  @override
  void dispose() {
    _audioRecorder.dispose();
    _timer?.cancel();
    if (kDebugMode) print("RecordingSessionProvider disposed.");
    super.dispose();
  }

  // --- Recording Control ---

  Future<void> startRecording(
    AudioRecordingProvider audioTranscriptProvider,
  ) async {
    if (_state == RecordingState.recording || _state == RecordingState.saving)
      return;

    _resetState(); // Reset state before starting a new recording
    _setState(RecordingState.recording);
    _errorMessage = ''; // Clear previous errors

    try {
      if (kIsWeb) {
        _setErrorMessage('Recording not supported on web');
        _setState(RecordingState.error);
        return;
      }

      var micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        _setErrorMessage('Microphone permission is required for recording.');
        _setState(RecordingState.error);
        if (micStatus == PermissionStatus.permanentlyDenied) {
          // Consider guiding the user to settings
        }
        return;
      }

      // Ensure STT is initialized and enabled before starting recording
      if (!audioTranscriptProvider.speechEnabled &&
          !audioTranscriptProvider.isSpeechInitializing) {
        await audioTranscriptProvider.initializeSpeech();
      }
      if (!audioTranscriptProvider.speechEnabled) {
        _setErrorMessage(
          'Speech recognition is not available or permission denied. Transcription will be disabled.',
        );
        // We might still allow recording without transcription, depending on requirements.
        // For now, we'll treat it as an error preventing recording if transcription is essential.
        _setState(RecordingState.error);
        return;
      }

      Directory tempDir = await getTemporaryDirectory();
      _recordFilePath =
          '${tempDir.path}/meeting_${DateTime.now().millisecondsSinceEpoch}.m4a';

      if (kDebugMode)
        print('Attempting to start recording to: $_recordFilePath');

      await _audioRecorder.start(
        path: _recordFilePath!,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        samplingRate: 44100,
      );
      await Future.delayed(const Duration(milliseconds: 100)); // Small delay

      bool isRecordingNow = await _audioRecorder.isRecording();
      if (isRecordingNow) {
        _recordingStartTime = DateTime.now();
        if (kDebugMode) print("Recording started successfully.");
        _setState(RecordingState.recording);

        // Start speech-to-text listening
        audioTranscriptProvider.startListening();
        _startTimer(); // Start the duration timer
      } else {
        _setErrorMessage('Failed to start recording.');
        _setState(RecordingState.error);
        _recordFilePath = null;
        if (kDebugMode) print("ERR: Recording did not start.");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) print('Error starting recording: $e\n$stackTrace');
      _setErrorMessage('Failed to start recording: ${e.toString()}');
      _setState(RecordingState.error);
      _recordFilePath = null;
      audioTranscriptProvider.cancelListening(); // Cancel STT on error
      _timer?.cancel(); // Cancel timer on error
    }
  }

  Future<void> stopRecording(
    AudioRecordingProvider audioTranscriptProvider,
  ) async {
    if (_state != RecordingState.recording) return;

    _setState(RecordingState.stopped); // Transition to stopped state
    _errorMessage = ''; // Clear any previous errors

    try {
      final path = await _audioRecorder.stop();
      if (kDebugMode) print("Recording stopped. Path: $path");

      // Stop speech-to-text listening
      audioTranscriptProvider.stopListening();
      _timer?.cancel(); // Stop timer

      if (path != null) {
        _recordFilePath = path; // Ensure path is updated
        _recordingEndTime = DateTime.now();
        if (kDebugMode) print("Recording finished. Ready to save.");
      } else {
        _setErrorMessage('Failed to get recording path after stopping.');
        _setState(RecordingState.error);
        _recordFilePath = null;
        _recordingStartTime = null;
        _recordingEndTime = null;
        if (kDebugMode) print("ERR: _audioRecorder.stop() returned null.");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) print('Error stopping recording: $e\n$stackTrace');
      _setErrorMessage('Failed to stop recording: ${e.toString()}');
      _setState(RecordingState.error);
      audioTranscriptProvider.cancelListening(); // Ensure STT is cancelled
      _timer?.cancel(); // Cancel timer on error
    }
  }

  // --- Saving ---

  Future<bool> saveRecording({
    required String title,
    required String participants,
    required MeetingRecordsProvider meetingRecordsProvider,
    required AudioRecordingProvider audioTranscriptProvider,
  }) async {
    if (_state != RecordingState.stopped ||
        _recordFilePath == null ||
        _recordingStartTime == null ||
        _recordingEndTime == null) {
      _setErrorMessage(
        'No recording found to save, or recording was incomplete.',
      );
      if (kDebugMode) print("Save attempted but conditions not met.");
      return false;
    }

    _setState(RecordingState.saving);
    _errorMessage = ''; // Clear any previous errors

    final String finalTitle =
        title.trim().isNotEmpty
            ? title.trim()
            : 'Meeting ${formatMeetingDateTime(_recordingStartTime!).replaceAll(' •', '')}';
    final List<String> participantList =
        participants
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
    final String uniqueId =
        _recordingStartTime!.millisecondsSinceEpoch.toString();

    // Get the final transcript from the AudioRecordingProvider
    final String finalTranscript = audioTranscriptProvider.getFinalTranscript();

    final newRecord = MeetingRecord(
      id: uniqueId,
      title: finalTitle,
      startTime: _recordingStartTime!,
      endTime: _recordingEndTime!,
      audioFilePathUser1: _recordFilePath!,
      transcript:
          finalTranscript.isNotEmpty
              ? finalTranscript
              : 'No transcript available.',
      participantIds: participantList,
      isFavorite: false,
    );

    if (kDebugMode) print("Attempting to save record: ${newRecord.toMap()}");

    try {
      await meetingRecordsProvider.addMeetingRecord(newRecord);
      if (kDebugMode) print("Meeting record added successfully.");

      _setState(RecordingState.saved);
      _resetState(); // Reset state after successful save
      audioTranscriptProvider
          .clearTranscript(); // Clear transcript after saving
      return true; // Indicate success
    } catch (e, stackTrace) {
      if (kDebugMode) print('Error saving meeting record: $e\n$stackTrace');
      _setErrorMessage('Failed to save meeting record: ${e.toString()}');
      _setState(RecordingState.error);
      // Do not reset state on save error, allow user to try again or discard
      return false; // Indicate failure
    }
  }

  // --- Discarding ---

  void discardRecording(AudioRecordingProvider audioTranscriptProvider) {
    if (kDebugMode) print("Discarding recording.");
    _resetState();
    audioTranscriptProvider
        .cancelListening(); // Cancel STT and clear transcript
    _timer?.cancel(); // Cancel timer
    _errorMessage = ''; // Clear any errors
    notifyListeners(); // Notify listeners after discarding
  }

  // --- State Management Helpers ---

  void _setState(RecordingState newState) {
    if (_state != newState) {
      _state = newState;
      if (kDebugMode) print("RecordingState changed to: $_state");
      notifyListeners();
    }
  }

  void _setErrorMessage(String message) {
    _errorMessage = message;
    if (kDebugMode) print("Error: $message");
    notifyListeners();
  }

  void _resetState() {
    _state = RecordingState.idle;
    _recordFilePath = null;
    _recordingStartTime = null;
    _recordingEndTime = null;
    _currentDurationInSeconds = 0;
    _timer?.cancel(); // Ensure timer is cancelled on reset
    _errorMessage = '';
    if (kDebugMode) print("Recording state reset to idle.");
  }

  // --- Timer Logic ---

  void _startTimer() {
    _currentDurationInSeconds = 0;
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _currentDurationInSeconds++;
      notifyListeners(); // Notify listeners to update the UI with the new duration
    });
  }
}
