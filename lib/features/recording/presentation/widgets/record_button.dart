import 'package:flutter/material.dart';

class RecordButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onPressed; // Callback for when the button is pressed

  const RecordButton({
    super.key,
    required this.isRecording,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Use AnimatedSwitcher for a smooth transition between icons/styles
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: ElevatedButton(
        key: ValueKey<bool>(isRecording), // Key for AnimatedSwitcher
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(), // Make it circular
          padding: const EdgeInsets.all(20), // Adjust padding for size
          backgroundColor: isRecording ? Colors.redAccent : Colors.blueAccent,
          foregroundColor: Colors.white, // Icon/Text color
          elevation: 5.0,
        ),
        child: Icon(
          isRecording ? Icons.stop : Icons.mic, // Change icon based on state
          size: 40, // Adjust icon size
        ),
      ),
    );

    /* Alternative Style (FloatingActionButton):
    return FloatingActionButton(
      key: ValueKey<bool>(isRecording), // Key for AnimatedSwitcher
      onPressed: onPressed,
      backgroundColor: isRecording ? Colors.redAccent : Theme.of(context).colorScheme.secondary,
      foregroundColor: Colors.white,
      elevation: 5.0,
      heroTag: null, // Important if you have multiple FABs
      child: Icon(
        isRecording ? Icons.stop : Icons.mic,
        size: 30,
      ),
    );
    */
  }
}
