import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting

import 'package:ai_transcript_app/features/meeting_records/domain/entities/meeting_record.dart'; // Import your entity
import 'package:ai_transcript_app/core/utils/date_formatting.dart'; // Import date formatting utility

// Define callback types for better readability
typedef VoidCallback = void Function();
typedef FavoriteCallback = void Function(String recordId);

class MeetingCard extends StatelessWidget {
  final MeetingRecord record; // Pass the whole record
  final VoidCallback? onTap; // Callback when the card is tapped
  final FavoriteCallback? onFavoriteTap; // Callback for favorite toggle

  const MeetingCard({
    super.key,
    required this.record,
    this.onTap,
    this.onFavoriteTap,
  });

  // Helper to format date and duration - Moved to core/utils
  String _formatSubtitle(MeetingRecord record) {
    String formattedDate = formatMeetingDateTime(
      record.startTime,
    ); // Use utility
    String duration = '';
    if (record.endTime != null) {
      duration =
          ' • ${formatMeetingDuration(record.startTime, record.endTime!)}'; // Use utility
    }
    return formattedDate + duration;
  }

  // Helper to get a snippet of the transcript/notes
  String _getContentSnippet(String transcript) {
    const maxLength = 100;
    if (transcript.length <= maxLength) {
      return transcript.isEmpty ? 'No summary available.' : transcript;
    }
    return '${transcript.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior:
          Clip.antiAlias, // Ensures InkWell ripple stays within bounds
      margin: const EdgeInsets.only(
        bottom: 12.0,
      ), // Add some margin between cards
      child: InkWell(
        // Make the whole card tappable
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flexible title allows text wrapping
                  Flexible(
                    child: Text(
                      record.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Favorite button
                  IconButton(
                    icon: Icon(
                      record.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: record.isFavorite ? Colors.redAccent : Colors.grey,
                    ),
                    iconSize: 20, // Smaller icon
                    padding: EdgeInsets.zero, // Remove default padding
                    constraints:
                        const BoxConstraints(), // Remove constraints to allow tight padding
                    tooltip:
                        record.isFavorite
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                    onPressed: () {
                      onFavoriteTap?.call(record.id); // Call the callback
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatSubtitle(record), // Use helper for subtitle
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),
              Text(
                _getContentSnippet(
                  record.transcript,
                ), // Use helper for content snippet
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              // Optionally display participants
              if (record.participantIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children:
                      record.participantIds
                          .map(
                            (p) => Chip(
                              label: Text(p),
                              labelStyle: const TextStyle(fontSize: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 0,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
