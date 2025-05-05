import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart'; // Import path_provider

class DatabaseHelper {
  static const _databaseName = "meeting_records.db";
  static const _databaseVersion = 1;

  static const tableMeetingRecords = 'meeting_records';
  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnStartTime = 'start_time';
  static const columnEndTime = 'end_time';
  static const columnAudioFilePathUser1 = 'audio_file_path_user1';
  static const columnAudioFilePathUser2 = 'audio_file_path_user2';
  static const columnTranscript = 'transcript';
  static const columnIsFavorite = 'is_favorite';
  // Define other column names here, matching your MeetingRecord fields
  static const columnParticipantIds = 'participant_ids'; // Example

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableMeetingRecords (
        $columnId TEXT PRIMARY KEY,
        $columnTitle TEXT,
        $columnStartTime INTEGER,
        $columnEndTime INTEGER,
        $columnAudioFilePathUser1 TEXT,
        $columnAudioFilePathUser2 TEXT,
        $columnTranscript TEXT,
        $columnIsFavorite INTEGER,
        $columnParticipantIds TEXT // Example for storing list as CSV
        // Add other columns here
      )
      ''');
  }

  Future<int> insertMeetingRecord(Map<String, dynamic> meetingRecord) async {
    Database db = await instance.database;
    return await db.insert(tableMeetingRecords, meetingRecord);
  }

  Future<List<Map<String, dynamic>>> getAllMeetingRecords() async {
    Database db = await instance.database;
    return await db.query(tableMeetingRecords);
  }

  Future<int> updateMeetingRecord(
    Map<String, dynamic> meetingRecord,
    String id,
  ) async {
    Database db = await instance.database;
    return await db.update(
      tableMeetingRecords,
      meetingRecord,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMeetingRecord(String id) async {
    Database db = await instance.database;
    return await db.delete(
      tableMeetingRecords,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}
