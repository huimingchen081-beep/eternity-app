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

  // Floating animation parameters (persistent per planet)
  final double floatPhase;
  final double floatSpeed;
  final double floatAmplitude;

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
    this.floatPhase = 0.0,
    this.floatSpeed = 1.0,
    this.floatAmplitude = 1.0,
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
      'floatPhase': floatPhase,
      'floatSpeed': floatSpeed,
      'floatAmplitude': floatAmplitude,
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
      floatPhase: (map['floatPhase'] as num?)?.toDouble() ?? (Random(map['id'].hashCode).nextDouble() * 2 * pi),
      floatSpeed: (map['floatSpeed'] as num?)?.toDouble() ?? (0.5 + Random(map['id'].hashCode + 1).nextDouble() * 1.5),
      floatAmplitude: (map['floatAmplitude'] as num?)?.toDouble() ?? (10.0 + Random(map['id'].hashCode + 2).nextDouble() * 15.0),
    );
  }

  static List<Planet> generateUniverse(int count, double width, double height) {
    final random = Random(42);
    final planets = <Planet>[];

    // Color palette for planets
    final colors = [
      '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7',
      '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9',
      '#F8C471', '#82E0AA', '#F1948A', '#85C1E9', '#D7BDE2',
      '#A9DFBF', '#F9E79F', '#AED6F1', '#F5B7B1', '#A3E4D7',
    ];

    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final dist = random.nextDouble() * max(width, height) * 2.5;
      final verticalSpread = (random.nextDouble() - 0.5) * max(width, height) * 1.5;
      final z = (random.nextDouble() - 0.5) * max(width, height) * 2;

      double radius;
      final sizeRoll = random.nextDouble();
      if (sizeRoll < 0.5) {
        radius = 2.0 + random.nextDouble() * 4.0;
      } else if (sizeRoll < 0.8) {
        radius = 6.0 + random.nextDouble() * 6.0;
      } else if (sizeRoll < 0.95) {
        radius = 12.0 + random.nextDouble() * 8.0;
      } else {
        radius = 20.0 + random.nextDouble() * 12.0;
      }

      // Each planet gets unique floating parameters
      final floatPhase = random.nextDouble() * 2 * pi;
      final floatSpeed = 0.5 + random.nextDouble() * 1.5; // 0.5-2.0
      final floatAmplitude = 10.0 + random.nextDouble() * 15.0; // 10-25 pixels

      planets.add(Planet(
        id: 'planet_$i',
        x: cos(angle) * dist,
        y: sin(angle) * dist * 0.6 + verticalSpread,
        z: z,
        radius: radius,
        colorHex: colors[random.nextInt(colors.length)],
        floatPhase: floatPhase,
        floatSpeed: floatSpeed,
        floatAmplitude: floatAmplitude,
      ));
    }

    return planets;
  }
}
