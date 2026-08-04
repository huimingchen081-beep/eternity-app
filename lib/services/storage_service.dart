import 'dart:io';
import 'dart:math';
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
      onUpgrade: _onUpgrade,
      version: 2,
    );
    final appDir = await getApplicationDocumentsDirectory();
    _mediaDir = join(appDir.path, 'eternity_media');
    final dir = Directory(_mediaDir!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add floating animation columns to planets table
      await db.execute('ALTER TABLE planets ADD COLUMN floatPhase REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE planets ADD COLUMN floatSpeed REAL DEFAULT 1.0');
      await db.execute('ALTER TABLE planets ADD COLUMN floatAmplitude REAL DEFAULT 15.0');

      // Populate float values for existing planets using deterministic per-planet random
      final planets = await db.query('planets');
      for (final p in planets) {
        final id = p['id'] as String;
        final rng = Random(id.hashCode);
        await db.update(
          'planets',
          {
            'floatPhase': rng.nextDouble() * 2 * pi,
            'floatSpeed': 0.5 + rng.nextDouble() * 1.5,
            'floatAmplitude': 10.0 + rng.nextDouble() * 15.0,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE planets (
        id TEXT PRIMARY KEY,
        x REAL, y REAL, z REAL,
        radius REAL, isLit INTEGER,
        litAt TEXT, entryCount INTEGER DEFAULT 0,
        colorHex TEXT,
        floatPhase REAL DEFAULT 0.0,
        floatSpeed REAL DEFAULT 1.0,
        floatAmplitude REAL DEFAULT 10.0
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
    // Copy audio from cache to persistent storage
    final persistedPath = await persistFile(audioPath, prefix: 'voice');
    final entry = MemoryEntry(
      id: _uuid.v4(),
      planetId: planetId,
      type: MemoryType.voice,
      audioPath: persistedPath,
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
    // Copy images from cache to persistent storage
    final persistedPaths = await persistImagePaths(imagePaths);
    final entry = MemoryEntry(
      id: _uuid.v4(),
      planetId: planetId,
      type: MemoryType.image,
      imagePaths: persistedPaths,
      createdAt: DateTime.now(),
      language: language,
    );
    await _db!.insert('memory_entries', entry.toMap());
    await _afterEntry(planetId);
    return entry;
  }

  Future<MemoryEntry> saveVideoEntry(
      String planetId, String videoPath, String language) async {
    // Copy video from cache to persistent storage
    final persistedPath = await persistFile(videoPath, prefix: 'video');
    final entry = MemoryEntry(
      id: _uuid.v4(),
      planetId: planetId,
      type: MemoryType.video,
      videoPath: persistedPath,
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
    // Persist media files
    final persistedImages = images != null ? await persistImagePaths(images) : null;
    final persistedAudio = audioPath != null ? await persistFile(audioPath, prefix: 'voice') : null;
    final persistedVideo = videoPath != null ? await persistFile(videoPath, prefix: 'video') : null;

    final entry = MemoryEntry(
      id: _uuid.v4(),
      planetId: planetId,
      type: MemoryType.mixed,
      textContent: text,
      imagePaths: persistedImages,
      audioPath: persistedAudio,
      audioTranscript: transcript,
      audioLanguage: audioLanguage,
      videoPath: persistedVideo,
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

  /// Copy a file from cache/temp directory to persistent storage.
  /// Returns the new persistent path. If the source is already in _mediaDir, returns as-is.
  Future<String> persistFile(String sourcePath, {String prefix = 'media'}) async {
    // Already in persistent storage?
    if (sourcePath.startsWith(_mediaDir!)) return sourcePath;

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return sourcePath; // Can't copy non-existent file

    final ext = sourcePath.contains('.') ? sourcePath.substring(sourcePath.lastIndexOf('.')) : '';
    final destPath = join(_mediaDir!, '${prefix}_${_uuid.v4()}$ext');
    await sourceFile.copy(destPath);
    return destPath;
  }

  /// Copy multiple image paths to persistent storage.
  Future<List<String>> persistImagePaths(List<String> paths) async {
    final result = <String>[];
    for (final p in paths) {
      final persisted = await persistFile(p, prefix: 'img');
      result.add(persisted);
    }
    return result;
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
