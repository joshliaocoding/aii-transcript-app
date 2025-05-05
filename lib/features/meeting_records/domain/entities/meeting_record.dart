import 'package:ai_transcript_app/core/database/database_helper.dart'; // Using package import for core

class MeetingRecord {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final List<String> participantIds;
  final String? audioFilePathUser1;
  final String? audioFilePathUser2;
  final String transcript;
  final bool isFavorite;
  // Add other relevant fields

  MeetingRecord({
    required this.id,
    required this.title,
    required this.startTime,
    this.endTime,
    this.participantIds = const [],
    this.audioFilePathUser1,
    this.audioFilePathUser2,
    required this.transcript,
    this.isFavorite = false,
    // Add other fields with their named parameters
  });

  MeetingRecord copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? participantIds,
    String? audioFilePathUser1,
    String? audioFilePathUser2,
    String? transcript,
    bool? isFavorite,
    // Copy with other fields
  }) {
    return MeetingRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      participantIds: participantIds ?? this.participantIds,
      audioFilePathUser1: audioFilePathUser1 ?? this.audioFilePathUser1,
      audioFilePathUser2: audioFilePathUser2 ?? this.audioFilePathUser2,
      transcript: transcript ?? this.transcript,
      isFavorite: isFavorite ?? this.isFavorite,
      // Copy other fields
    );
  }

  // These methods ideally belong in the data layer (e.g., MeetingRecordModel)
  // and would be handled by a repository implementation.
  // For this refactor, we keep them here for simplicity and direct DB interaction.
  Map<String, dynamic> toMap() {
    return {
      DatabaseHelper.columnId: id,
      DatabaseHelper.columnTitle: title,
      DatabaseHelper.columnStartTime: startTime.millisecondsSinceEpoch,
      DatabaseHelper.columnEndTime: endTime?.millisecondsSinceEpoch,
      DatabaseHelper.columnAudioFilePathUser1: audioFilePathUser1,
      DatabaseHelper.columnAudioFilePathUser2: audioFilePathUser2,
      DatabaseHelper.columnTranscript: transcript,
      DatabaseHelper.columnIsFavorite: isFavorite ? 1 : 0,
      'participant_ids': participantIds.join(','),
    };
  }

  factory MeetingRecord.fromMap(Map<String, dynamic> map) {
    return MeetingRecord(
      id: map[DatabaseHelper.columnId] as String,
      title: map[DatabaseHelper.columnTitle] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(
        map[DatabaseHelper.columnStartTime] as int,
      ),
      endTime:
          map[DatabaseHelper.columnEndTime] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                map[DatabaseHelper.columnEndTime] as int,
              )
              : null,
      audioFilePathUser1:
          map[DatabaseHelper.columnAudioFilePathUser1] as String?,
      audioFilePathUser2:
          map[DatabaseHelper.columnAudioFilePathUser2] as String?,
      transcript: map[DatabaseHelper.columnTranscript] as String,
      isFavorite: (map[DatabaseHelper.columnIsFavorite] as int) == 1,
      participantIds: (map['participant_ids'] as String?)?.split(',') ?? [],
    );
  }
}
