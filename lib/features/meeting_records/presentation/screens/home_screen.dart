import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:ai_transcript_app/features/meeting_records/presentation/widgets/meeting_card.dart';
import 'package:ai_transcript_app/features/meeting_records/domain/entities/meeting_record.dart';
import 'package:ai_transcript_app/features/meeting_records/presentation/providers/meeting_records_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<MeetingRecordsProvider>(
      builder: (context, meetingProvider, child) {
        final List<MeetingRecord> records = meetingProvider.meetingRecords;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.homeTitle),
            // Optional: Add actions like search or sort
            // actions: [ ... ],
          ),
          body:
              records.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mic_off_outlined,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noMeetingRecords,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.tapMicToRecord,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return Dismissible(
                        // Wrap MeetingCard with Dismissible
                        key: Key(record.id), // Unique key for each item
                        direction:
                            DismissDirection
                                .endToStart, // Allow swiping from right to left
                        background: Container(
                          // Background shown behind the item when swiping
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          // Optional: Show a confirmation dialog before dismissing
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(
                                  l10n.confirmDeleteTitle,
                                ), // Localize
                                content: Text(
                                  l10n.confirmDeleteContent,
                                ), // Localize
                                actions: <Widget>[
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(
                                          context,
                                        ).pop(false), // Cancel
                                    child: Text(
                                      l10n.dialogButtonCancel,
                                    ), // Localize
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(
                                          context,
                                        ).pop(true), // Confirm
                                    child: Text(
                                      l10n.dialogButtonDelete,
                                      style: TextStyle(color: Colors.red),
                                    ), // Localize
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          // Remove the item from your data source.
                          // The UI will update automatically because MeetingRecordsProvider notifies listeners.
                          meetingProvider.removeMeetingRecord(record.id);

                          // Show a snackbar to indicate deletion
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.meetingDeletedMessage(record.title),
                              ), // Localize and include title
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: MeetingCard(
                          record: record,
                          onTap: () {
                            context.goNamed(
                              'details',
                              pathParameters: {'meetingId': record.id},
                            );
                          },
                          onFavoriteTap: (recordId) {
                            meetingProvider.toggleFavorite(recordId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  record.isFavorite
                                      ? l10n.removedFromFavorites
                                      : l10n.addedToFavorites,
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              context.go('/record');
            },
            tooltip: l10n.recordNewMeetingTooltip,
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.mic, color: Colors.white),
          ),
        );
      },
    );
  }
}
