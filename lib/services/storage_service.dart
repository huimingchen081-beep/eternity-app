import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/planet.dart';
import '../models/memory_entry.dart';

class StorageService {
  static Database? _db;
  static String? _mediaDir;
  static const _uuid = Uuid();

  Future<void> init() async {
    _db ??= await openDatabase(
      join(await getDatabasesPath(), 'eternity.db'),
      onCreate: _onCreate,
      version: 1,
    );
    final appDir = await getApplicationDocumentsDirectory();
    _mediaDir = join(appDir.path, 'eternity_media');
    final dir = Directory(_mediaDir!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE planets (
        id TEXT PRIMARY KEY,
        x REAL, y REAL, z REAL,
        radius REAL, isLit INTEGER,
        litAt TEXT, entryCount INTEGER DEFAULT 0,
        colorHex TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE memory_entries (
        id TEXT PRIMARY KEY,
        planetId TEXT,
        type INTEGER,
        textContent TEXT,
        imagePaths TEXT,
        audioPath TEXT,
        audioTranscript TEXT,
        audioLanguage TEXT,
        videoPath TEXT,
        createdAt TEXT,
        language TEXT DEFAULT 'en',
        FOREIGN KEY (planetId) REFERENCES planets(id)
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_entries_planet ON memory_entries(planetId)
    ''');
    await db.execute('''
      CREATE INDEX idx_entries_date ON memory_entries(createdAt)
    ''');
  }

  // --- Planet Operations ---
  Future<void> savePlanets(List<Planet> planets) async {
    final batch = _db!.batch();
    for (final p in planets) {
      batch.insert('planets', p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Planet>> loadPlanets() async {
    final maps = await _db!.query('planets');
    return maps.map((m) {
      final p = Planet.fromMap(m);
      return p;
    }).toList();
  }

  Future<void> lightPlanet(String planetId) async {
    await _db!.update(
      'planets',
      {
        'isLit': 1,
        'litAt': DateTime.now().toIso8601String(),
        'entryCount': 1,
      },
      where: 'id = ?',
      whereArgs: [planetId],
    );
  }

  Future<void> incrementPlanetEntry(String planetId) async {
    await _db!.rawUpdate(
      'UPDATE planets SET entryCount = entryCount + 1 WHERE id = ?',
      [planetId],
    );
  }

  // --- Memory Entry Operations ---
  Future<MemoryEntry> saveTextEntry(
      String planetId, String text, String language) async {
    final entry = MemoryEntry(
      id: _uuid.v4(),
      planetId: planetId,
      type: MemoryType.text,
      textContent: text,
      createdAt: DateTime.now(),
      language: language,
    );
    await _db!.insert('memory_entries', entry.toMap());
    await _afterEntry(planetId);
    return entry;
  }

  Future<MemoryEntry> saveVoiceEntry(
    String planetId,
    String audioPath,
    String transcript,
    String audioLanguage,
    String language,
  ) async {
    final entry = MemoryEntry(
      id: _uuid.v4(),
      planetId: planetId,
      type: MemoryType.voice,
      audioPath: audioPath,
      audioTranscript: transcript,
      audioLanguage: audioLanguage,
      createdAt: DateTime.now(),
      language: language,
    );
    await _db!.insert('memory_entries', entry.toMap());
    await _afterEntry(planetId);
    return entry;
  }

  Future<MemoryEntry> saveImageEntry(
      String planetId, List<String> imagePaths, String language) async {
    final entry = MemoryEntry(
      id: _uuid.v4(),
      planetId: planetId,
      type: MemoryType.image,
      imagePaths: imagePaths,
      createdAt: DateTime.now(),
      language: language,
    );
    await _db!.insert('memory_entries', entry.toMap());
    await _afterEntry(planetId);
    return entry;
  }

  Future<MemoryEntry> saveVideoEntry(
      String planetId, String videoPath, String language) async {
    final entry = MemoryEntry(
      id: _uuid.v4(),
      planetId: planetId,
      type: MemoryType.video,
      videoPath: videoPath,
      createdAt: DateTime.now(),
      language: language,
    );
    await _db!.insert('memory_entries', entry.toMap());
    await _afterEntry(planetId);
    return entry;
  }

  Future<MemoryEntry> saveMixedEntry(
    String planetId, {
    String? text,
    List<String>? images,
    String? audioPath,
    String? transcript,
    String? audioLanguage,
    String? videoPath,
    String language = 'en',
  }) async {
    final entry = MemoryEntry(
      id: _uuid.v4(),
      planetId: planetId,
      type: MemoryType.mixed,
      textContent: text,
      imagePaths: images,
      audioPath: audioPath,
      audioTranscript: transcript,
      audioLanguage: audioLanguage,
      videoPath: videoPath,
      createdAt: DateTime.now(),
      language: language,
    );
    await _db!.insert('memory_entries', entry.toMap());
    await _afterEntry(planetId);
    return entry;
  }

  Future<void> _afterEntry(String planetId) async {
    final planets = await _db!.query('planets',
        where: 'id = ?', whereArgs: [planetId]);
    if (planets.isNotEmpty && planets.first['isLit'] == 0) {
      await lightPlanet(planetId);
    } else {
      await incrementPlanetEntry(planetId);
    }
  }

  Future<List<MemoryEntry>> getEntriesForPlanet(String planetId) async {
    final maps = await _db!.query(
      'memory_entries',
      where: 'planetId = ?',
      whereArgs: [planetId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => MemoryEntry.fromMap(m)).toList();
  }

  Future<List<MemoryEntry>> getAllEntries() async {
    final maps = await _db!.query('memory_entries', orderBy: 'createdAt DESC');
    return maps.map((m) => MemoryEntry.fromMap(m)).toList();
  }

  Future<void> deleteEntry(String entryId) async {
    await _db!.delete('memory_entries', where: 'id = ?', whereArgs: [entryId]);
  }

  // --- Media file helpers ---
  String get mediaDir => _mediaDir!;

  String getMediaPath(String filename) {
    return join(_mediaDir!, filename);
  }

  Future<int> getStorageUsedMB() async {
    int total = 0;
    final dir = Directory(_mediaDir!);
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
    }
    return (total / (1024 * 1024)).round();
  }

  // --- Entry count ---
  Future<int> getLitPlanetCount() async {
    final result =
        await _db!.rawQuery('SELECT COUNT(*) as c FROM planets WHERE isLit = 1');
    return result.first['c'] as int;
  }

  Future<int> getTotalEntryCount() async {
    final result =
        await _db!.rawQuery('SELECT COUNT(*) as c FROM memory_entries');
    return result.first['c'] as int;
  }
}
