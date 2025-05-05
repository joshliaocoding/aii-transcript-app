import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_transcript_app/features/meeting_records/presentation/providers/meeting_records_provider.dart';
import 'package:ai_transcript_app/features/meeting_records/presentation/widgets/meeting_card.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to the MeetingRecordsProvider
    return Consumer<MeetingRecordsProvider>(
      builder: (context, meetingProvider, child) {
        // Filter the records to get only favorites
        final favoriteRecords =
            meetingProvider.meetingRecords
                .where((record) => record.isFavorite)
                .toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Saved Meetings')),
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
                          'No saved meetings yet.',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the heart icon on a meeting to save it.',
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
                      return MeetingCard(
                        record: record,
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
                                    ? 'Removed from favorites'
                                    : 'Added to favorites',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
        );
      },
    );
  }
}
