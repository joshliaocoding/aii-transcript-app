import 'package:flutter/material.dart';
import 'package:ai_transcript_app/features/meeting_records/domain/entities/meeting_record.dart'; // Updated import
import 'package:ai_transcript_app/core/database/database_helper.dart'; // Updated import
import 'package:flutter/foundation.dart'; // Import for kDebugMode

class MeetingRecordsProvider extends ChangeNotifier {
  List<MeetingRecord> _meetingRecords = [];

  List<MeetingRecord> get meetingRecords => _meetingRecords;

  // Load meeting records from the database when the provider is initialized
  MeetingRecordsProvider() {
    _loadMeetingRecords();
  }

  Future<void> _loadMeetingRecords() async {
    if (kDebugMode) print("Loading meeting records from database...");
    try {
      final dbHelper = DatabaseHelper.instance;
      final records = await dbHelper.getAllMeetingRecords();
      _meetingRecords =
          records
              .map(
                (record) => MeetingRecord.fromMap(record),
              ) // Use fromMap factory
              .toList();
      if (kDebugMode) print("Loaded ${_meetingRecords.length} records.");
      notifyListeners();
    } catch (e, stackTrace) {
      if (kDebugMode) print("Error loading meeting records: $e\n$stackTrace");
      // Handle error loading records (e.g., show an error message)
    }
  }

  Future<void> addMeetingRecord(MeetingRecord record) async {
    if (kDebugMode) print("Adding new meeting record: ${record.id}");
    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.insertMeetingRecord(record.toMap());
      _meetingRecords.add(record);
      notifyListeners();
      if (kDebugMode) print("Meeting record added successfully.");
    } catch (e, stackTrace) {
      if (kDebugMode) print("Error adding meeting record: $e\n$stackTrace");
      // Handle error adding record
      throw e; // Re-throw the exception to be handled by the caller (e.g., RecordScreen)
    }
  }

  Future<void> removeMeetingRecord(String id) async {
    if (kDebugMode) print("Removing meeting record: $id");
    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteMeetingRecord(id);
      _meetingRecords.removeWhere((record) => record.id == id);
      notifyListeners();
      if (kDebugMode) print("Meeting record removed successfully.");
    } catch (e, stackTrace) {
      if (kDebugMode) print("Error removing meeting record: $e\n$stackTrace");
      // Handle error removing record
    }
  }

  Future<void> updateMeetingRecord(MeetingRecord updatedRecord) async {
    if (kDebugMode) print("Updating meeting record: ${updatedRecord.id}");
    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.updateMeetingRecord(
        updatedRecord.toMap(), // Make sure toMap() is comprehensive
        updatedRecord.id,
      );
      final index = _meetingRecords.indexWhere(
        (record) => record.id == updatedRecord.id,
      );
      if (index != -1) {
        _meetingRecords[index] = updatedRecord;
        notifyListeners(); // This is key for UI updates
        if (kDebugMode)
          print("Meeting record updated successfully in provider.");
      }
    } catch (e, stackTrace) {
      if (kDebugMode)
        print("Error updating meeting record in provider: $e\n$stackTrace");
      throw e; // Re-throw to be caught by the UI
    }
  }

  Future<void> toggleFavorite(String id) async {
    if (kDebugMode) print("Toggling favorite for record: $id");
    final index = _meetingRecords.indexWhere((record) => record.id == id);
    if (index != -1) {
      final currentFavoriteStatus = _meetingRecords[index].isFavorite;
      final updatedRecord = _meetingRecords[index].copyWith(
        isFavorite: !currentFavoriteStatus,
      );
      // Optimistically update the UI
      _meetingRecords[index] = updatedRecord;
      notifyListeners();

      try {
        final dbHelper = DatabaseHelper.instance;
        await dbHelper.updateMeetingRecord(updatedRecord.toMap(), id);
        if (kDebugMode) print("Favorite status toggled successfully in DB.");
      } catch (e, stackTrace) {
        if (kDebugMode) print("Error toggling favorite in DB: $e\n$stackTrace");
        // Revert UI on error
        _meetingRecords[index] = _meetingRecords[index].copyWith(
          isFavorite: currentFavoriteStatus,
        ); // Revert
        notifyListeners();
        // Handle error saving favorite status
      }
    } else {
      if (kDebugMode) print("Record with ID $id not found to toggle favorite.");
    }
  }

  // Method to get a single meeting record by ID
  MeetingRecord? getMeetingRecordById(String id) {
    try {
      return _meetingRecords.firstWhere((record) => record.id == id);
    } catch (e) {
      if (kDebugMode) print("Record with ID $id not found in provider.");
      return null; // Return null if not found
    }
  }
}
