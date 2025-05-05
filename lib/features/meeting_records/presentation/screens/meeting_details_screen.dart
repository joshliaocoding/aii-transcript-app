import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_transcript_app/features/meeting_records/domain/entities/meeting_record.dart';
import 'package:ai_transcript_app/features/meeting_records/presentation/providers/meeting_records_provider.dart';
import 'package:ai_transcript_app/core/utils/date_formatting.dart'; // Import date formatting utility

class MeetingDetailsScreen extends StatelessWidget {
  const MeetingDetailsScreen({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context) {
    // Access the provider to find the meeting record
    final meetingRecordsProvider = Provider.of<MeetingRecordsProvider>(context);
    final meetingRecord = meetingRecordsProvider.getMeetingRecordById(
      meetingId,
    );

    // Handle case where record is not found
    if (meetingRecord == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Details Not Found')),
        body: const Center(child: Text('Meeting record not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(meetingRecord.title),
        actions: [
          IconButton(
            icon: Icon(
              meetingRecord.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: meetingRecord.isFavorite ? Colors.redAccent : null,
            ),
            onPressed: () {
              meetingRecordsProvider.toggleFavorite(meetingRecord.id);
              // Optionally show a snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    meetingRecord
                            .isFavorite // Check the updated status from provider state
                        ? 'Removed from favorites'
                        : 'Added to favorites',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          // Add edit or delete actions here
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Start Time: ${formatMeetingDateTime(meetingRecord.startTime)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'End Time: ${meetingRecord.endTime != null ? formatMeetingDateTime(meetingRecord.endTime!) : 'Not ended'}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Duration: ${formatMeetingDuration(meetingRecord.startTime, meetingRecord.endTime)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            if (meetingRecord.participantIds.isNotEmpty) ...[
              Text(
                'Participants:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children:
                    meetingRecord.participantIds
                        .map((p) => Chip(label: Text(p)))
                        .toList(),
              ),
              const SizedBox(height: 16),
            ],
            Text('Transcript:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              meetingRecord.transcript.isNotEmpty
                  ? meetingRecord.transcript
                  : 'No transcript available.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            // Display audio file path if needed
            if (meetingRecord.audioFilePathUser1 != null) ...[
              const SizedBox(height: 16),
              Text(
                'Audio File Path: ${meetingRecord.audioFilePathUser1}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
            // Add UI for audio playback here if desired
          ],
        ),
      ),
    );
  }
}
