import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import 'package:ai_transcript_app/features/recording/presentation/providers/audio_recording_provider.dart';
import 'package:ai_transcript_app/features/meeting_records/domain/entities/meeting_record.dart'; // Import the entity
import 'package:ai_transcript_app/features/meeting_records/presentation/providers/meeting_records_provider.dart'; // Import meeting records provider
import 'package:ai_transcript_app/core/utils/date_formatting.dart'; // Import date formatting utility

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  late final Record _audioRecorder;
  // bool _isRecording = false; // Use provider state
  bool _hasRecorded = false;
  String? _recordFilePath;
  DateTime? _recordingStartTime;
  DateTime? _recordingEndTime;

  late TextEditingController _titleController;
  late TextEditingController _participantsController;

  // Get provider instances
  late AudioRecordingProvider _audioRecordingProvider;
  late MeetingRecordsProvider _meetingRecordsProvider;

  // Timer for recording duration display
  Timer? _timer;
  int _startTimer = 0;

  @override
  void initState() {
    super.initState();
    _audioRecorder = Record();
    _titleController = TextEditingController();
    _participantsController = TextEditingController();
    _checkPermissions(); // Check permissions on screen load

    // Initialize providers
    _audioRecordingProvider = Provider.of<AudioRecordingProvider>(
      context,
      listen: false,
    );
    _meetingRecordsProvider = Provider.of<MeetingRecordsProvider>(
      context,
      listen: false,
    );

    // Initialize speech-to-text when the screen loads
    // This is now handled by the provider's constructor or first access,
    // but calling it here explicitly ensures it starts early.
    _audioRecordingProvider.initializeSpeech();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _titleController.dispose();
    _participantsController.dispose();
    _audioRecordingProvider.cancelListening(); // Cancel listening on dispose
    _timer?.cancel(); // Cancel the timer
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    var micStatus = await Permission.microphone.status;
    if (micStatus.isDenied || micStatus.isRestricted) {
      micStatus = await Permission.microphone.request();
    }
    if (kDebugMode) {
      print("Initial microphone permission status on init: ${micStatus.name}");
    }
    // Speech permission is handled by AudioRecordingProvider now
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _startTimerDisplay() {
    _startTimer = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted) {
        setState(() {
          _startTimer++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTimerDuration(int seconds) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(remainingSeconds)}";
  }

  Future<void> _startRecording() async {
    // Use provider state to check if already recording
    if (_audioRecordingProvider.isListening) return;
    FocusScope.of(context).unfocus();

    try {
      if (kIsWeb) {
        _showSnackBar('Recording not supported on web');
        return;
      }

      var micStatus = await Permission.microphone.request();
      // Speech permission is requested by the provider during its initialization
      if (micStatus != PermissionStatus.granted) {
        _showSnackBar('Microphone permission is required for recording.');
        if (micStatus == PermissionStatus.permanentlyDenied) {
          await openAppSettings();
        }
        return;
      }

      // Ensure STT is initialized and enabled before starting recording
      if (!_audioRecordingProvider.speechEnabled &&
          !_audioRecordingProvider.isSpeechInitializing) {
        await _audioRecordingProvider.initializeSpeech();
      }
      if (!_audioRecordingProvider.speechEnabled) {
        _showSnackBar(
          'Speech recognition is not available or permission denied.',
        );
        return; // Cannot record without speech recognition for transcription
      }

      Directory tempDir = await getTemporaryDirectory();
      setState(() {
        _recordFilePath =
            '${tempDir.path}/meeting_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _recordingStartTime = null;
        _recordingEndTime = null;
        _hasRecorded = false;
        _startTimer = 0; // Reset timer
      });

      if (kDebugMode)
        print('Attempting to start recording to: $_recordFilePath');

      await _audioRecorder.start(
        path: _recordFilePath!,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        samplingRate: 44100,
      );
      await Future.delayed(const Duration(milliseconds: 100)); // Small delay

      bool isRecording = await _audioRecorder.isRecording();
      if (isRecording) {
        _recordingStartTime = DateTime.now();
        if (mounted) setState(() => _hasRecorded = false); // Reset hasRecorded
        if (kDebugMode) print("Recording started successfully.");

        // Start speech-to-text listening
        _audioRecordingProvider.startListening();
        _startTimerDisplay(); // Start the timer display
      } else {
        _showSnackBar('Failed to start recording.');
        if (mounted) setState(() => _recordFilePath = null);
        if (kDebugMode) print("ERR: Recording did not start.");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) print('Error starting recording: $e\n$stackTrace');
      _showSnackBar(
        'Failed to start recording: ${e.toString()}',
      ); // Show more specific error
      if (mounted)
        setState(() {
          // Use provider to update isListening
          // _isRecording = false;
          _hasRecorded = false;
          _recordFilePath = null;
          _timer?.cancel(); // Cancel timer on error
        });
      _audioRecordingProvider.cancelListening(); // Cancel STT on error
    }
  }

  Future<void> _stopRecording() async {
    // Use provider state
    if (!_audioRecordingProvider.isListening) return;
    try {
      final path = await _audioRecorder.stop();
      if (kDebugMode) print("Recording stopped. Path: $path");

      // Stop speech-to-text listening
      _audioRecordingProvider.stopListening();
      _timer?.cancel(); // Stop timer

      if (path != null) {
        _recordingEndTime = DateTime.now();
        if (mounted) {
          setState(() {
            _hasRecorded = true; // Mark as recorded
            _recordFilePath =
                path; // Ensure _recordFilePath is updated with the final path
          });
        }
      } else {
        if (kDebugMode) print("ERR: _audioRecorder.stop() returned null.");
        _showSnackBar('Failed to get recording path after stopping.');
        if (mounted) {
          setState(() {
            _hasRecorded = false;
            _recordFilePath = null;
            _recordingStartTime = null;
            _recordingEndTime = null;
          });
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) print('Error stopping recording: $e\n$stackTrace');
      _showSnackBar('Failed to stop recording: ${e.toString()}');
      if (mounted) {
        setState(() {
          // _isRecording = false; // Use provider state
          _hasRecorded = false;
          _recordFilePath = null;
          _recordingStartTime = null;
          _recordingEndTime = null;
        });
      }
      _audioRecordingProvider.cancelListening(); // Ensure STT is cancelled
      _timer?.cancel(); // Cancel timer on error
    }
  }

  Future<void> _saveMeetingRecord() async {
    if (!_hasRecorded ||
        _recordFilePath == null ||
        _recordingStartTime == null ||
        _recordingEndTime == null) {
      _showSnackBar('No recording found to save, or recording was incomplete.');
      if (kDebugMode)
        print(
          "Save attempted but conditions not met: hasRecorded=$_hasRecorded, path=$_recordFilePath, start=$_recordingStartTime, end=$_recordingEndTime",
        );
      return;
    }
    if (!mounted) return;

    final String title =
        _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : 'Meeting ${formatMeetingDateTime(_recordingStartTime!).replaceAll(' •', '')}'; // Use utility for default title
    final String participants = _participantsController.text.trim();
    final List<String> participantList =
        participants
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
    final String uniqueId =
        _recordingStartTime!.millisecondsSinceEpoch.toString();

    // Get the final transcript from the provider
    final String finalTranscript = _audioRecordingProvider.getFinalTranscript();

    final newRecord = MeetingRecord(
      id: uniqueId,
      title: title,
      startTime: _recordingStartTime!,
      endTime: _recordingEndTime!,
      audioFilePathUser1: _recordFilePath!,
      transcript:
          finalTranscript.isNotEmpty
              ? finalTranscript
              : 'No transcript available.', // Save the transcript
      participantIds: participantList,
      isFavorite: false,
    );

    if (kDebugMode) print("Attempting to save record: ${newRecord.toMap()}");

    try {
      await _meetingRecordsProvider.addMeetingRecord(newRecord);
      _showSnackBar('Meeting saved: $title');
      _titleController.clear();
      _participantsController.clear();
      if (mounted) {
        setState(() {
          _hasRecorded = false;
          _recordFilePath = null;
          _recordingStartTime = null;
          _recordingEndTime = null;
          _audioRecordingProvider
              .clearTranscript(); // Clear transcript after saving
        });
        if (kDebugMode) {
          debugPrint("Save successful, navigating home via context.goNamed.");
        }
        context.goNamed('home'); // Use go_router to navigate
      }
    } catch (e, stackTrace) {
      if (kDebugMode) print('Error saving meeting record: $e\n$stackTrace');
      _showSnackBar('Failed to save meeting record: ${e.toString()}');
    }
  }

  // Helper to format duration while recording - Moved to core/utils
  // String _formatDuration(DateTime startTime, DateTime? endTime) { ... }

  @override
  Widget build(BuildContext context) {
    // Listen to the AudioRecordingProvider for UI updates
    final audioRecordingProvider = Provider.of<AudioRecordingProvider>(context);
    final bool canSave = !audioRecordingProvider.isListening && _hasRecorded;

    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        if (audioRecordingProvider.isListening || _hasRecorded) {
          // Use provider state
          final confirm = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Discard changes?'),
                  content: Text(
                    audioRecordingProvider
                            .isListening // Use provider state
                        ? 'Recording is in progress. Stop and discard?'
                        : 'You have an unsaved recording. Discard it?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Discard'),
                    ),
                  ],
                ),
          );

          if (confirm == true) {
            if (audioRecordingProvider.isListening) {
              // Use provider state
              try {
                await _audioRecorder.stop();
                audioRecordingProvider.cancelListening(); // Cancel STT
                _timer?.cancel(); // Cancel timer
              } catch (e, stackTrace) {
                if (kDebugMode)
                  print("Error stopping recording on discard: $e\n$stackTrace");
              }
            }
            if (mounted) {
              setState(() {
                // _isRecording = false; // Use provider state
                _hasRecorded = false;
                _recordFilePath = null;
                _recordingStartTime = null;
                _recordingEndTime = null;
                _audioRecordingProvider
                    .clearTranscript(); // Clear transcript on discard
              });
            }
            if (mounted) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.goNamed('home');
              }
            }
          }
        } else {
          // If not recording and no unsaved recording, just pop
          if (mounted) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.goNamed('home');
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            audioRecordingProvider
                    .isListening // Use provider state for title
                ? 'Recording...'
                : (_hasRecorded ? 'Review & Save' : 'New Meeting'),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: () {
              // Use PopScope's logic for back navigation
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              icon: Icon(
                audioRecordingProvider
                        .isListening // Use provider state for icon
                    ? Icons.stop_circle_outlined
                    : Icons.mic_none_outlined,
                color: audioRecordingProvider.isListening ? Colors.red : null,
              ),
              tooltip:
                  audioRecordingProvider.isListening
                      ? 'Stop Recording'
                      : 'Start Recording',
              iconSize: 28,
              onPressed:
                  audioRecordingProvider.isListening
                      ? _stopRecording
                      : _startRecording, // Use provider state to determine action
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              // Status Indicator
              if (audioRecordingProvider.isListening) // Use provider state
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.circle, color: Colors.red, size: 12),
                    const SizedBox(width: 8),
                    const Text(
                      "Recording...",
                      style: TextStyle(color: Colors.red),
                    ),
                    if (_recordingStartTime != null) ...[
                      const SizedBox(width: 8),
                      // Display the timer value
                      Text(_formatTimerDuration(_startTimer)),
                    ],
                  ],
                )
              else if (_hasRecorded)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text("Recording finished. Ready to save."),
                  ],
                )
              else if (audioRecordingProvider
                  .isSpeechInitializing) // Indicate STT initialization
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text("Initializing Speech Recognition..."),
                  ],
                )
              else if (!audioRecordingProvider.speechEnabled &&
                  !audioRecordingProvider
                      .isSpeechInitializing) // Indicate STT not enabled
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: Colors.orange,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      // Use Expanded to prevent overflow
                      child: Text(
                        "Speech recognition not available or permission denied. Transcription will be disabled.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  "Tap the microphone button above to start recording.",
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 30),
              TextField(
                controller: _titleController,
                enabled:
                    !audioRecordingProvider
                        .isListening, // Disable while recording
                decoration: InputDecoration(
                  labelText: 'Meeting Title (Optional)',
                  hintText: 'Defaults to date/time if left blank',
                  border: const OutlineInputBorder(),
                  suffixIcon:
                      !audioRecordingProvider.isListening &&
                              _titleController
                                  .text
                                  .isNotEmpty // Disable while recording
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _titleController.clear(),
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _participantsController,
                enabled:
                    !audioRecordingProvider
                        .isListening, // Disable while recording
                decoration: InputDecoration(
                  labelText: 'Participants (Optional, comma-separated)',
                  border: const OutlineInputBorder(),
                  suffixIcon:
                      !audioRecordingProvider.isListening &&
                              _participantsController
                                  .text
                                  .isNotEmpty // Disable while recording
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _participantsController.clear(),
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 20),
              // Show transcript area after recording or while listening
              if (_hasRecorded || audioRecordingProvider.isListening)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transcript:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Consumer<AudioRecordingProvider>(
                      // Display live/final transcript
                      builder: (context, provider, child) {
                        return Text(
                          provider.currentTranscript.isNotEmpty
                              ? provider.currentTranscript
                              : (provider.isListening
                                  ? 'Listening...'
                                  : 'Generating transcript...'), // Show appropriate message
                          style: Theme.of(context).textTheme.bodyMedium,
                        );
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Save Meeting Recording'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: canSave ? _saveMeetingRecord : null,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
