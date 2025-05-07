import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import 'package:go_router/go_router.dart'; // Import go_router for context.pop()

import 'package:ai_transcript_app/features/meeting_records/domain/entities/meeting_record.dart';
import 'package:ai_transcript_app/features/meeting_records/presentation/providers/meeting_records_provider.dart';
import 'package:ai_transcript_app/core/utils/date_formatting.dart'; // Import date formatting utility

class MeetingDetailsScreen extends StatelessWidget {
  const MeetingDetailsScreen({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context) {
    // Access the localization object
    final l10n = AppLocalizations.of(context)!;
    // Access the provider to find the meeting record
    final meetingRecordsProvider = Provider.of<MeetingRecordsProvider>(context);
    final meetingRecord = meetingRecordsProvider.getMeetingRecordById(
      meetingId,
    );

    // Handle case where record is not found
    if (meetingRecord == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            // Add back button even for error screen
            icon: const Icon(Icons.arrow_back),
            tooltip:
                l10n.dialogButtonCancel, // Or a more generic "Back" tooltip
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                // If it can't pop (e.g., deep link), go to home as a fallback
                context.goNamed('home');
              }
            },
          ),
          title: Text(l10n.detailsNotFoundTitle), // Localize this error title
        ),
        body: Center(
          child: Text(
            l10n.meetingRecordNotFound,
          ), // Localize this error message
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          // This is the new back button
          icon: const Icon(Icons.arrow_back),
          tooltip:
              l10n.dialogButtonCancel, // You might want a more specific "Back" tooltip here
          onPressed: () {
            // Standard way to navigate back
            if (context.canPop()) {
              context.pop();
            } else {
              // Fallback if there's nothing to pop to (e.g. if this screen was the first one opened via a deep link)
              // You might want to navigate to a specific screen like 'home'
              context.goNamed('home');
            }
          },
        ),
        title: Text(meetingRecord.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.editMeetingTooltip,
            onPressed: () async {
              final result = await context.pushNamed(
                'editMeeting',
                pathParameters: {'meetingId': meetingRecord.id},
              );
              if (result == true) {
                // Data already updated by provider, screen will rebuild.
              }
            },
          ),
          IconButton(
            icon: Icon(
              (meetingRecordsProvider
                          .getMeetingRecordById(meetingId)
                          ?.isFavorite ??
                      false)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color:
                  (meetingRecordsProvider
                              .getMeetingRecordById(meetingId)
                              ?.isFavorite ??
                          false)
                      ? Colors.redAccent
                      : null,
            ),
            tooltip:
                (meetingRecordsProvider
                            .getMeetingRecordById(meetingId)
                            ?.isFavorite ??
                        false)
                    ? l10n
                        .removeFromFavoritesTooltip // Add this localization
                    : l10n.addToFavoritesTooltip, // Add this localization
            onPressed: () {
              bool wasFavorite =
                  meetingRecordsProvider
                      .getMeetingRecordById(meetingId)
                      ?.isFavorite ??
                  false;
              meetingRecordsProvider.toggleFavorite(meetingRecord.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    !wasFavorite // Status *after* toggle
                        ? l10n.addedToFavorites
                        : l10n.removedFromFavorites,
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              '${l10n.startTimeLabel}: ${formatMeetingDateTime(meetingRecord.startTime)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.endTimeLabel}: ${meetingRecord.endTime != null ? formatMeetingDateTime(meetingRecord.endTime!) : l10n.notEndedLabel}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.durationLabel}: ${formatMeetingDuration(meetingRecord.startTime, meetingRecord.endTime)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (meetingRecord.description != null &&
                meetingRecord.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.descriptionLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                meetingRecord.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            if (meetingRecord.participantIds.isNotEmpty) ...[
              Text(
                l10n.participantsLabel,
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
            Text(
              l10n.transcriptTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SelectableText(
              // Made transcript selectable
              meetingRecord.transcript.isNotEmpty
                  ? meetingRecord.transcript
                  : l10n.noTranscriptAvailable,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (meetingRecord.audioFilePathUser1 != null) ...[
              const SizedBox(height: 16),
              Text(
                'Audio File Path: ${meetingRecord.audioFilePathUser1}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
