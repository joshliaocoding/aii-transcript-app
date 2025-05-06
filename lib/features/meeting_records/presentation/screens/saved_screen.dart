import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

import 'package:ai_transcript_app/features/meeting_records/presentation/providers/meeting_records_provider.dart';
import 'package:ai_transcript_app/features/meeting_records/presentation/widgets/meeting_card.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<MeetingRecordsProvider>(
      builder: (context, meetingProvider, child) {
        final favoriteRecords =
            meetingProvider.meetingRecords
                .where((record) => record.isFavorite)
                .toList();

        return Scaffold(
          appBar: AppBar(title: Text(l10n.savedMeetingsTitle)),
          body:
              favoriteRecords.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noSavedMeetings,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.tapHeartToSave,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: favoriteRecords.length,
                    itemBuilder: (context, index) {
                      final record = favoriteRecords[index];
                      return Dismissible(
                        // Wrap MeetingCard with Dismissible
                        key: Key(record.id), // Unique key
                        direction:
                            DismissDirection.endToStart, // Swipe direction
                        background: Container(
                          // Background
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
                          meetingProvider.removeMeetingRecord(record.id);
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
          // Floating Action Button is typically not on the SavedScreen
        );
      },
    );
  }
}
