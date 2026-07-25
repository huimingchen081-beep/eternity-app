import 'dart:math';

class Planet {
  final String id;
  final double x;
  final double y;
  final double z;
  final double radius;
  bool isLit;
  DateTime? litAt;
  int entryCount;
  String? colorHex;
  List<String> entryIds;

  Planet({
    required this.id,
    required this.x,
    required this.y,
    required this.z,
    this.radius = 8.0,
    this.isLit = false,
    this.litAt,
    this.entryCount = 0,
    this.colorHex,
    List<String>? entryIds,
  }) : entryIds = entryIds ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'z': z,
      'radius': radius,
      'isLit': isLit ? 1 : 0,
      'litAt': litAt?.toIso8601String(),
      'entryCount': entryCount,
      'colorHex': colorHex,
    };
  }

  factory Planet.fromMap(Map<String, dynamic> map) {
    return Planet(
      id: map['id'],
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      z: (map['z'] as num).toDouble(),
      radius: (map['radius'] as num?)?.toDouble() ?? 8.0,
      isLit: (map['isLit'] as int?) == 1,
      litAt: map['litAt'] != null ? DateTime.tryParse(map['litAt']) : null,
      entryCount: map['entryCount'] as int? ?? 0,
      colorHex: map['colorHex'],
    );
  }

  static List<Planet> generateUniverse(int count, double width, double height) {
    final random = Random(42);
    final planets = <Planet>[];

    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final dist = random.nextDouble() * max(width, height) * 2.5;
      final z = (random.nextDouble() - 0.5) * max(width, height) * 2;

      planets.add(Planet(
        id: 'planet_$i',
        x: cos(angle) * dist,
        y: sin(angle) * dist + (random.nextDouble() - 0.5) * 200,
        z: z,
        radius: 4.0 + random.nextDouble() * 6.0,
      ));
    }

    return planets;
  }
}
