import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:ai_transcript_app/features/recording/presentation/providers/audio_recording_provider.dart';
import 'package:ai_transcript_app/features/recording/presentation/providers/recording_session_provider.dart';
import 'package:ai_transcript_app/features/meeting_records/presentation/providers/meeting_records_provider.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  late TextEditingController _titleController;
  late TextEditingController _participantsController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _participantsController = TextEditingController();
    _descriptionController = TextEditingController();

    // Initialize Speech-to-Text when the screen loads.
    // This is now handled by the AudioRecordingProvider's constructor or first access,
    // but calling it here explicitly ensures it starts early.
    // Access using listen: false as we only need to call a method.
    Provider.of<AudioRecordingProvider>(
      context,
      listen: false,
    ).initializeSpeech();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _participantsController.dispose();
    _descriptionController.dispose();
    // Note: Disposing of the recorder and cancelling timers is now handled
    // in the RecordingSessionProvider's dispose method.
    // Cancelling STT listening is handled by the provider's discard method.
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // Function to handle starting or stopping the recording
  void _toggleRecording(
    RecordingSessionProvider recordingProvider,
    AudioRecordingProvider audioTranscriptProvider,
  ) async {
    if (recordingProvider.isRecording) {
      await recordingProvider.stopRecording(audioTranscriptProvider);
    } else {
      await recordingProvider.startRecording(audioTranscriptProvider);
    }
  }

  // Function to handle saving the recording
  void _saveRecording(
    RecordingSessionProvider recordingProvider,
    MeetingRecordsProvider meetingRecordsProvider,
    AudioRecordingProvider audioTranscriptProvider,
    AppLocalizations l10n, // Pass localization object
  ) async {
    final success = await recordingProvider.saveRecording(
      title: _titleController.text,
      participants: _participantsController.text,
      description: _descriptionController.text,
      meetingRecordsProvider: meetingRecordsProvider,
      audioTranscriptProvider: audioTranscriptProvider,
    );

    if (success) {
      _showSnackBar(l10n.saveSuccessMessage); // Use localized string
      // Clear text fields after successful save
      _titleController.clear();
      _participantsController.clear();
      // Navigate back to home after saving
      if (mounted) {
        context.goNamed('home');
      }
    } else {
      // Error message is set in the provider, show it to the user
      _showSnackBar(l10n.saveErrorMessage(recordingProvider.errorMessage));
    }
  }

  // Function to handle discarding the recording
  void _discardRecording(
    RecordingSessionProvider recordingProvider,
    AudioRecordingProvider audioTranscriptProvider,
  ) {
    recordingProvider.discardRecording(audioTranscriptProvider);
    // Clear text fields on discard
    _titleController.clear();
    _participantsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Access the localization object
    final l10n = AppLocalizations.of(context)!;
    // Consume providers
    final recordingProvider = Provider.of<RecordingSessionProvider>(context);
    final audioTranscriptProvider = Provider.of<AudioRecordingProvider>(
      context,
    );
    final meetingRecordsProvider = Provider.of<MeetingRecordsProvider>(
      context,
      listen: false,
    ); // Listen: false as we only call methods

    // Determine if the save button should be enabled
    final bool canSave =
        recordingProvider.hasRecorded &&
        !recordingProvider.isRecording &&
        recordingProvider.state != RecordingState.saving;

    return PopScope(
      canPop:
          !recordingProvider.isRecording &&
          !recordingProvider
              .hasRecorded, // Can pop if not recording and no unsaved record
      onPopInvoked: (bool didPop) async {
        if (kDebugMode) print('PopScope onPopInvoked: didPop = $didPop');
        // If didPop is true, the pop was successful (either allowed by canPop or confirmed discard)
        if (didPop) {
          if (kDebugMode) print('Pop was successful, returning.');
          return;
        }

        // If didPop is false, the pop was prevented by canPop (due to unsaved changes/recording)
        if (recordingProvider.isRecording || recordingProvider.hasRecorded) {
          if (kDebugMode)
            print(
              'Unsaved changes or recording in progress. Showing discard dialog.',
            );
          final confirm = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text(
                    l10n.discardChangesDialogTitle,
                  ), // Use localized string
                  content: Text(
                    recordingProvider.isRecording
                        ? l10n
                            .discardChangesDialogContentRecording // Use localized string
                        : l10n
                            .discardChangesDialogContentUnsaved, // Use localized string
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        if (kDebugMode)
                          print('Discard dialog: Cancel pressed.');
                        Navigator.of(
                          context,
                        ).pop(false); // Don't pop the dialog
                      },
                      child: Text(
                        l10n.dialogButtonCancel,
                      ), // Use localized string
                    ),
                    TextButton(
                      onPressed: () {
                        if (kDebugMode)
                          print('Discard dialog: Discard pressed.');
                        Navigator.of(
                          context,
                        ).pop(true); // Pop the dialog with true
                      },
                      child: Text(
                        l10n.dialogButtonDiscard,
                      ), // Use localized string
                    ),
                  ],
                ),
          );

          // If the user confirmed discarding changes (the dialog returned true)
          if (confirm == true) {
            if (kDebugMode)
              print(
                'User confirmed discard. Discarding recording and navigating to home.',
              );
            _discardRecording(recordingProvider, audioTranscriptProvider);
            _showSnackBar(l10n.discardSuccessMessage); // Use localized string

            // Add a small delay before navigating to home
            await Future.delayed(const Duration(milliseconds: 50));
            if (kDebugMode) print('Delay finished, navigating to home.');

            // Navigate directly to home after discarding
            if (mounted) {
              context.goNamed('home'); // Navigate to home
              if (kDebugMode) print('context.goNamed("home") called.');
            } else {
              if (kDebugMode)
                print('Not mounted after discard, cannot navigate.');
            }
          } else {
            if (kDebugMode) print('User cancelled discard. Staying on screen.');
          }
        } else {
          // This case should ideally not be reached if canPop is set correctly,
          // as the initial pop would have succeeded.
          if (kDebugMode)
            print(
              'No unsaved changes or recording. Initial pop should have worked.',
            );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            recordingProvider.isRecording
                ? l10n
                    .recordScreenTitleRecording // Use localized title
                : (recordingProvider.hasRecorded
                    ? l10n.recordScreenTitleReview
                    : l10n.recordScreenTitleNew), // Use localized titles
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip:
                l10n.dialogButtonCancel, // Consider a more specific tooltip like "Back"
            onPressed: () {
              // This onPressed triggers the PopScope's onPopInvoked callback.
              if (kDebugMode) print('Leading back button icon pressed.');
              Navigator.of(context).pop(); // This triggers the PopScope
            },
          ),
          actions: [
            IconButton(
              icon: Icon(
                recordingProvider.isRecording
                    ? Icons.stop_circle_outlined
                    : Icons.mic_none_outlined,
                color: recordingProvider.isRecording ? Colors.red : null,
              ),
              tooltip:
                  recordingProvider.isRecording
                      ? l10n
                          .stopRecordingTooltip // Localize tooltip
                      : l10n.startRecordingTooltip, // Localize tooltip
              iconSize: 28,
              onPressed:
                  recordingProvider.state == RecordingState.saving
                      ? null // Disable button while saving
                      : () => _toggleRecording(
                        recordingProvider,
                        audioTranscriptProvider,
                      ),
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              // Status Indicator
              if (recordingProvider.state == RecordingState.recording)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.circle, color: Colors.red, size: 12),
                    const SizedBox(width: 8),
                    Text(
                      l10n.recordScreenTitleRecording, // Use localized string
                      style: TextStyle(color: Colors.red),
                    ),
                    const SizedBox(width: 8),
                    // Display the timer value from the provider
                    Text(recordingProvider.formattedDuration),
                  ],
                )
              else if (recordingProvider.state == RecordingState.stopped)
                Row(
                  // Changed to Row to include localized text
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.recordingFinished), // Use localized string
                  ],
                )
              else if (recordingProvider.state == RecordingState.saving)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(l10n.savingLabel), // Use localized string
                  ],
                )
              else if (recordingProvider.state == RecordingState.error)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        // Error message is already localized in the provider or is a system message
                        "Error: ${recordingProvider.errorMessage}",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                )
              else if (audioTranscriptProvider
                  .isSpeechInitializing) // Indicate STT initialization
                Row(
                  // Changed to Row to include localized text
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(l10n.sttInitializing), // Use localized string
                  ],
                )
              else if (!audioTranscriptProvider.speechEnabled &&
                  !audioTranscriptProvider
                      .isSpeechInitializing) // Indicate STT not enabled
                Row(
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
                        l10n.speechRecognitionUnavailable, // Use localized string
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  l10n.tapMicToRecord, // Use localized string
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 30),
              TextField(
                controller: _titleController,
                enabled:
                    !recordingProvider.isRecording &&
                    recordingProvider.state !=
                        RecordingState
                            .saving, // Disable while recording or saving
                decoration: InputDecoration(
                  labelText: l10n.meetingTitleLabel, // Localize label
                  hintText: l10n.meetingTitleHint, // Use localized hint
                  border: const OutlineInputBorder(),
                  suffixIcon:
                      !recordingProvider.isRecording &&
                              recordingProvider.state !=
                                  RecordingState.saving &&
                              _titleController.text.isNotEmpty
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
                    !recordingProvider.isRecording &&
                    recordingProvider.state !=
                        RecordingState
                            .saving, // Disable while recording or saving
                decoration: InputDecoration(
                  labelText: l10n.participantsLabel, // Localize label
                  hintText: l10n.participantsHint, // Use localized hint
                  border: const OutlineInputBorder(),
                  suffixIcon:
                      !recordingProvider.isRecording &&
                              recordingProvider.state !=
                                  RecordingState.saving &&
                              _participantsController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _participantsController.clear(),
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                // Add the description text field
                controller: _descriptionController,
                enabled:
                    !recordingProvider.isRecording &&
                    recordingProvider.state != RecordingState.saving,
                maxLines: 5, // Allow multiple lines for description
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText:
                      l10n.descriptionLabel, // You'll need to add this localization key
                  hintText:
                      l10n.descriptionHint, // You'll need to add this localization key
                  border: const OutlineInputBorder(),
                  suffixIcon:
                      !recordingProvider.isRecording &&
                              recordingProvider.state !=
                                  RecordingState.saving &&
                              _descriptionController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _descriptionController.clear(),
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 20),
              // Show transcript area after recording or while listening
              if (recordingProvider.state != RecordingState.idle &&
                  recordingProvider.state !=
                      RecordingState
                          .error) // Show transcript area if not idle or error
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.transcriptTitle, // Use localized string
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Consumer<AudioRecordingProvider>(
                      // Display live/final transcript
                      builder: (context, provider, child) {
                        String transcriptText =
                            provider.currentTranscript.isNotEmpty
                                ? provider.currentTranscript
                                : (recordingProvider.isRecording
                                    ? l10n
                                        .sttListening // Use localized string
                                    : l10n
                                        .sttGeneratingTranscript); // Use localized string
                        return Text(
                          transcriptText,
                          style: Theme.of(context).textTheme.bodyMedium,
                        );
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_outlined),
                label: Text(l10n.saveMeetingButton), // Use localized string
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed:
                    canSave
                        ? () => _saveRecording(
                          recordingProvider,
                          meetingRecordsProvider,
                          audioTranscriptProvider,
                          l10n, // Pass localization object
                        )
                        : null,
              ),
              const SizedBox(height: 20),
              // Add Discard button
              if (recordingProvider.hasRecorded)
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: Text(
                    l10n.discardRecordingButton,
                  ), // Use localized string
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed:
                      recordingProvider.state == RecordingState.saving
                          ? null // Disable button while saving
                          : () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text(
                                      l10n.discardRecordingDialogTitle,
                                    ), // Use localized string
                                    content: Text(
                                      l10n.discardRecordingDialogContent,
                                    ), // Use localized string
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(
                                              context,
                                            ).pop(false),
                                        child: Text(
                                          l10n.dialogButtonCancel,
                                        ), // Use localized string
                                      ),
                                      TextButton(
                                        onPressed:
                                            () =>
                                                Navigator.of(context).pop(true),
                                        child: Text(
                                          l10n.dialogButtonDiscard,
                                        ), // Use localized string
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true) {
                              if (kDebugMode)
                                print(
                                  'User confirmed discard from discard button. Discarding recording and navigating to home.',
                                );
                              _discardRecording(
                                recordingProvider,
                                audioTranscriptProvider,
                              );
                              _showSnackBar(
                                l10n.discardSuccessMessage,
                              ); // Use localized string

                              // Add a small delay before navigating to home
                              await Future.delayed(
                                const Duration(milliseconds: 50),
                              );
                              if (kDebugMode)
                                print(
                                  'Delay finished, navigating to home from discard button.',
                                );

                              // Navigate directly to home after discarding
                              if (mounted) {
                                context.goNamed('home'); // Navigate to home
                                if (kDebugMode)
                                  print(
                                    'context.goNamed("home") called from discard button.',
                                  );
                              } else {
                                if (kDebugMode)
                                  print(
                                    'Not mounted after discard from discard button, cannot navigate.',
                                  );
                              }
                            }
                          },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
