import 'package:ai_transcript_app/features/meeting_records/domain/entities/meeting_record.dart';

abstract class MeetingRecordRepository {
  Future<List<MeetingRecord>> getAllMeetingRecords();
  Future<void> saveMeetingRecord(
    MeetingRecord record,
  ); // Handles both add and update
  Future<void> deleteMeetingRecord(String id);
  Future<void> toggleFavorite(String id);
  Future<MeetingRecord?> getMeetingRecordById(
    String id,
  ); // Add this for details screen
}
