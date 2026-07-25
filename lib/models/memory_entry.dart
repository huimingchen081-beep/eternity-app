import 'dart:convert';

enum MemoryType { text, voice, image, video, mixed }

class MemoryEntry {
  final String id;
  final String planetId;
  final MemoryType type;
  final String? textContent;
  final List<String>? imagePaths;
  final String? audioPath;
  final String? audioTranscript;
  final String? audioLanguage;
  final String? videoPath;
  final DateTime createdAt;
  final String language;

  MemoryEntry({
    required this.id,
    required this.planetId,
    required this.type,
    this.textContent,
    this.imagePaths,
    this.audioPath,
    this.audioTranscript,
    this.audioLanguage,
    this.videoPath,
    required this.createdAt,
    this.language = 'en',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'planetId': planetId,
      'type': type.index,
      'textContent': textContent,
      'imagePaths': imagePaths != null ? jsonEncode(imagePaths) : null,
      'audioPath': audioPath,
      'audioTranscript': audioTranscript,
      'audioLanguage': audioLanguage,
      'videoPath': videoPath,
      'createdAt': createdAt.toIso8601String(),
      'language': language,
    };
  }

  factory MemoryEntry.fromMap(Map<String, dynamic> map) {
    return MemoryEntry(
      id: map['id'],
      planetId: map['planetId'],
      type: MemoryType.values[map['type']],
      textContent: map['textContent'],
      imagePaths: map['imagePaths'] != null
          ? List<String>.from(jsonDecode(map['imagePaths']))
          : null,
      audioPath: map['audioPath'],
      audioTranscript: map['audioTranscript'],
      audioLanguage: map['audioLanguage'],
      videoPath: map['videoPath'],
      createdAt: DateTime.parse(map['createdAt']),
      language: map['language'] ?? 'en',
    );
  }

  String get summary {
    switch (type) {
      case MemoryType.text:
        final t = textContent ?? '';
        return t.length > 50 ? '${t.substring(0, 50)}...' : t;
      case MemoryType.voice:
        return audioTranscript ?? 'Voice Memory';
      case MemoryType.image:
        return '${imagePaths?.length ?? 0} Photos';
      case MemoryType.video:
        return 'Video Memory';
      case MemoryType.mixed:
        return 'Mixed Memory';
    }
  }
}
