// import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:permission_handler/permission_handler.dart'; // Import for permission handling

class AudioRecordingProvider extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _currentTranscript = '';
  bool _speechEnabled = false;
  bool _isSpeechInitializing = false; // To prevent multiple initializations

  bool get isListening => _isListening;
  String get currentTranscript => _currentTranscript;
  bool get speechEnabled => _speechEnabled;
  bool get isSpeechInitializing => _isSpeechInitializing;

  // Initialize speech-to-text
  Future<void> initializeSpeech() async {
    if (_isSpeechInitializing || _speechEnabled) {
      return;
    } // Prevent re-initialization

    _isSpeechInitializing = true;
    if (kDebugMode) print("Initializing speech to text...");
    try {
      // Request speech permission before initializing STT
      var status = await Permission.speech.status;
      if (status.isDenied ||
          status.isRestricted ||
          status.isPermanentlyDenied) {
        if (kDebugMode) print("Speech permission not granted. Requesting...");
        status = await Permission.speech.request();
        if (status != PermissionStatus.granted) {
          if (kDebugMode) {
            debugPrint("Speech permission denied. STT will not be enabled.");
          }
          _speechEnabled = false;
          _isSpeechInitializing = false;
          notifyListeners();
          return;
        }
      }

      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          if (kDebugMode) print('STT Status: $status');
          if (status == 'notListening' && _isListening) {
            // Handle cases where STT stops listening unexpectedly while recording
            if (kDebugMode) {
              debugPrint(
                "STT stopped listening unexpectedly. Attempting to restart...",
              );
            }
            // This might indicate an issue or end of a speech segment.
            // For continuous transcription, you might need to restart listening.
            // However, simply calling startListening again might not be ideal
            // for seamless transcription. More advanced handling is needed
            // for continuous speech. For this example, we'll just log.
          }
        },
        onError: (errorNotification) {
          if (kDebugMode) print('STT Error: ${errorNotification.errorMsg}');
          // Handle STT errors (e.g., no match, network issues)
        },
      );
      if (kDebugMode) print("Speech enabled: $_speechEnabled");
    } catch (e, stackTrace) {
      if (kDebugMode) print("Error initializing speech: $e\n$stackTrace");
      _speechEnabled = false;
      // Handle initialization errors
    } finally {
      _isSpeechInitializing = false;
      notifyListeners();
    }
  }

  // Start listening for speech
  Future<void> startListening() async {
    if (!_speechEnabled) {
      if (kDebugMode) print("Speech not enabled, cannot start listening.");
      return;
    }
    if (_isListening) return; // Prevent starting if already listening

    if (kDebugMode) print("Starting to listen...");
    _isListening = true;
    _currentTranscript = ''; // Reset transcript for new recording
    notifyListeners();

    _speech.listen(
      onResult: (result) {
        // Append recognized words to the current transcript
        // This gives a more continuous feel during live transcription.
        // In a real app, you might process partial and final results differently.
        _currentTranscript = result.recognizedWords;
        if (kDebugMode) print("Transcript Update: $_currentTranscript");
        notifyListeners();
      },
      // Add more configuration if needed, e.g., locale, listenMode
      // For continuous listening, you might need specific options depending on the platform and STT engine.
      // The `partialResults` parameter in listen might be relevant here.
    );
  }

  // Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;
    if (kDebugMode) print("Stopping listening...");
    await _speech.stop();
    _isListening = false;
    if (kDebugMode) print("Listening stopped.");
    // The final transcript is now in _currentTranscript
    notifyListeners();
  }

  // Cancel ongoing listening (e.g., on screen dispose or discard)
  void cancelListening() {
    if (!_isListening && !_speech.isListening)
      return; // Only cancel if listening

    if (kDebugMode) print("Cancelling listening...");
    _speech.cancel();
    _isListening = false; // Ensure state is updated
    _currentTranscript = ''; // Clear transcript on cancel
    if (kDebugMode) print("Listening cancelled.");
    notifyListeners();
  }

  // Method to get the final transcript
  String getFinalTranscript() {
    // This will return the last recognized words by the STT engine.
    // If using partial results, you might need to accumulate them.
    return _currentTranscript;
  }

  // Method to clear the current transcript
  void clearTranscript() {
    _currentTranscript = '';
    notifyListeners();
  }

  // Dispose of the provider
  @override
  void dispose() {
    // --- REMOVE THE LINE BELOW ---
    // _speech.dispose(); // This method does not exist on SpeechToText
    // --- END OF REMOVED LINE ---
    if (kDebugMode) print("AudioRecordingProvider disposed.");
    super.dispose();
  }
}
