import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

// Import your components, models, and providers from their new locations
import 'package:ai_transcript_app/features/meeting_records/presentation/widgets/meeting_card.dart';
import 'package:ai_transcript_app/features/meeting_records/domain/entities/meeting_record.dart';
import 'package:ai_transcript_app/features/meeting_records/presentation/providers/meeting_records_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the localization object
    final l10n = AppLocalizations.of(context)!;
    // Use Consumer to listen to the MeetingRecordsProvider
    return Consumer<MeetingRecordsProvider>(
      builder: (context, meetingProvider, child) {
        // Get the list of records from the provider
        final List<MeetingRecord> records = meetingProvider.meetingRecords;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.homeTitle), // Use localized title
            // Optional: Add actions like search or sort
            // actions: [ ... ],
          ),
          body:
              records.isEmpty
                  ? Center(
                    // Show a message if there are no records
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
                          l10n.noMeetingRecords, // Use localized string
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.tapMicToRecord, // Use localized string
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    // Build list dynamically
                    padding: const EdgeInsets.all(16.0),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return MeetingCard(
                        record: record, // Pass the MeetingRecord object
                        onTap: () {
                          // Navigate to details screen on tap
                          context.goNamed(
                            'details',
                            pathParameters: {'meetingId': record.id},
                          );
                        },
                        onFavoriteTap: (recordId) {
                          // Toggle favorite status using the provider
                          meetingProvider.toggleFavorite(recordId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                record
                                        .isFavorite // Check the updated status
                                    ? l10n
                                        .removedFromFavorites // Localize
                                    : l10n.addedToFavorites, // Localize
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
          // Floating Action Button for starting a new recording
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              context.go('/record'); // Navigate to RecordScreen
            },
            tooltip: l10n.recordNewMeetingTooltip, // Localize tooltip
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.mic, color: Colors.white),
          ),
        );
      },
    );
  }
}
