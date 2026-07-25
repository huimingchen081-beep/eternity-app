import 'dart:math';
import 'package:flutter/material.dart';
import '../models/planet.dart';
import '../utils/constants.dart';

class UniverseCanvas extends StatefulWidget {
  final List<Planet> planets;
  final String? highlightedPlanetId;
  final Size screenSize;
  final VoidCallback? onPlanetTap;
  final String Function(String planetId)? onPlanetTapWithId;

  const UniverseCanvas({
    super.key,
    required this.planets,
    this.highlightedPlanetId,
    required this.screenSize,
    this.onPlanetTap,
    this.onPlanetTapWithId,
  });

  @override
  State<UniverseCanvas> createState() => _UniverseCanvasState();
}

class _UniverseCanvasState extends State<UniverseCanvas>
    with SingleTickerProviderStateMixin {
  // Camera transform
  double _offsetX = 0;
  double _offsetY = 0;
  double _scale = 1.0;
  double _rotation = 0;

  // Interaction state
  Offset? _lastFocalPoint;
  double? _initialScale;
  Offset? _initialOffset;

  // Animation
  late AnimationController _animController;
  final List<_Star> _stars = [];
  final List<_NebulaParticle> _nebula = [];

  // Highlight animation
  double _highlightPulse = 1.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _animController.addListener(_onAnimate);
    _generateStars(500);
    _generateNebula(80);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onAnimate() {
    // Slowly rotate background stars
    _rotation += 0.0001;
    if (_rotation > 2 * pi) _rotation -= 2 * pi;

    // Pulse on highlighted planet
    if (widget.highlightedPlanetId != null) {
      _highlightPulse = 1.0 + sin(_animController.value * 20) * 0.3;
    }

    setState(() {});
  }

  void _generateStars(int count) {
    final rng = Random(42);
    for (int i = 0; i < count; i++) {
      _stars.add(_Star(
        x: rng.nextDouble() * 4000 - 2000,
        y: rng.nextDouble() * 4000 - 2000,
        size: 0.3 + rng.nextDouble() * 1.5,
        brightness: 0.3 + rng.nextDouble() * 0.7,
        twinkleSpeed: 0.5 + rng.nextDouble() * 2.0,
        twinkleOffset: rng.nextDouble() * 2 * pi,
      ));
    }
  }

  void _generateNebula(int count) {
    final rng = Random(99);
    for (int i = 0; i < count; i++) {
      _nebula.add(_NebulaParticle(
        x: rng.nextDouble() * 3000 - 1500,
        y: rng.nextDouble() * 3000 - 1500,
        radius: 20 + rng.nextDouble() * 80,
        alpha: 0.02 + rng.nextDouble() * 0.06,
        hue: rng.nextDouble() * 360,
        driftX: (rng.nextDouble() - 0.5) * 0.3,
        driftY: (rng.nextDouble() - 0.5) * 0.3,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      onTapUp: _onTapUp,
      child: CustomPaint(
        painter: _UniversePainter(
          planets: widget.planets,
          highlightedPlanetId: widget.highlightedPlanetId,
          stars: _stars,
          nebula: _nebula,
          offsetX: _offsetX,
          offsetY: _offsetY,
          scale: _scale,
          rotation: _rotation,
          highlightPulse: _highlightPulse,
          animValue: _animController.value,
        ),
        size: Size.infinite,
      ),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.focalPoint;
    _initialScale = _scale;
    _initialOffset = Offset(_offsetX, _offsetY);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Pan
      if (_lastFocalPoint != null && _initialOffset != null) {
        final delta = details.focalPoint - _lastFocalPoint!;
        _offsetX = _initialOffset!.dx + delta.dx / _scale;
        _offsetY = _initialOffset!.dy + delta.dy / _scale;
      }

      // Zoom with limits
      if (_initialScale != null) {
        _scale = (_initialScale! * details.scale)
            .clamp(AppConstants.minZoom, AppConstants.maxZoom);
      }
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _lastFocalPoint = null;
    _initialScale = null;
    _initialOffset = null;
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPlanetTapWithId == null) return;

    // Convert tap position to universe coordinates
    final screenCenterX = widget.screenSize.width / 2;
    final screenCenterY = widget.screenSize.height / 2;

    final ux = (details.localPosition.dx - screenCenterX) / _scale - _offsetX;
    final uy = (details.localPosition.dy - screenCenterY) / _scale - _offsetY;

    // Find nearest planet
    String? nearestId;
    double minDist = double.infinity;

    for (final planet in widget.planets) {
      final dx = planet.x - ux;
      final dy = planet.y - uy;
      final dist = sqrt(dx * dx + dy * dy);

      // Scale hit test by current zoom
      final hitRadius = planet.radius * 3 / _scale;
      if (dist < hitRadius && dist < minDist) {
        nearestId = planet.id;
        minDist = dist;
      }
    }

    if (nearestId != null) {
      widget.onPlanetTapWithId!(nearestId);
    }
  }

  /// Programmatic methods for animation
  Offset getPlanetScreenPos(String planetId) {
    final planet = widget.planets.firstWhere(
      (p) => p.id == planetId,
      orElse: () => widget.planets.first,
    );

    final screenCenterX = widget.screenSize.width / 2;
    final screenCenterY = widget.screenSize.height / 2;

    final sx = (planet.x + _offsetX) * _scale + screenCenterX;
    final sy = (planet.y + _offsetY) * _scale + screenCenterY;

    return Offset(sx, sy);
  }
}

class _Star {
  final double x, y, size, brightness, twinkleSpeed, twinkleOffset;
  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.brightness,
    required this.twinkleSpeed,
    required this.twinkleOffset,
  });
}

class _NebulaParticle {
  final double x, y, radius, alpha, hue, driftX, driftY;
  _NebulaParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.alpha,
    required this.hue,
    required this.driftX,
    required this.driftY,
  });
}

class _UniversePainter extends CustomPainter {
  final List<Planet> planets;
  final String? highlightedPlanetId;
  final List<_Star> stars;
  final List<_NebulaParticle> nebula;
  final double offsetX, offsetY, scale, rotation;
  final double highlightPulse;
  final double animValue;

  _UniversePainter({
    required this.planets,
    this.highlightedPlanetId,
    required this.stars,
    required this.nebula,
    required this.offsetX,
    required this.offsetY,
    required this.scale,
    required this.rotation,
    required this.highlightPulse,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Deep space background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF050510),
    );

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.scale(scale);
    canvas.translate(offsetX, offsetY);

    // --- Nebula glow ---
    _drawNebula(canvas);

    // --- Far background stars ---
    _drawStars(canvas, true);

    // --- Planets (sorted by Z for depth) ---
    final sortedPlanets = List<Planet>.from(planets)
      ..sort((a, b) => a.z.compareTo(b.z));
    _drawPlanets(canvas, sortedPlanets);

    // --- Foreground stars ---
    _drawStars(canvas, false);

    canvas.restore();
  }

  void _drawNebula(Canvas canvas) {
    for (final n in nebula) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            HSLColor.fromAHSL(n.alpha, n.hue, 0.7, 0.5).toColor(),
            HSLColor.fromAHSL(0, n.hue, 0.7, 0.5).toColor(),
          ],
        ).createShader(Rect.fromCircle(center: Offset(n.x, n.y), radius: n.radius));

      canvas.drawCircle(Offset(n.x, n.y), n.radius, paint);
    }
  }

  void _drawStars(Canvas canvas, bool background) {
    final starPaint = Paint();
    final cosmosAngle = rotation;

    for (final star in stars) {
      // Apply slow rotation
      final cosA = cos(cosmosAngle);
      final sinA = sin(cosmosAngle);
      final rx = star.x * cosA - star.y * sinA;
      final ry = star.x * sinA + star.y * cosA;

      // Depth filter: background stars are further away
      final depth = (rx.abs() + ry.abs()) / 3000;
      if (background && depth > 0.6) continue;
      if (!background && depth <= 0.6) continue;

      // Twinkle
      final twinkle =
          0.5 + 0.5 * sin(animValue * star.twinkleSpeed + star.twinkleOffset);
      final alpha = star.brightness * (0.5 + 0.5 * twinkle);

      starPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(rx, ry), star.size, starPaint);
    }
  }

  void _drawPlanets(Canvas canvas, List<Planet> sortedPlanets) {
    for (final planet in sortedPlanets) {
      final isHighlighted = planet.id == highlightedPlanetId;

      if (planet.isLit) {
        _drawLitPlanet(canvas, planet, isHighlighted);
      } else {
        _drawDarkPlanet(canvas, planet);
      }
    }
  }

  void _drawLitPlanet(Canvas canvas, Planet planet, bool isHighlighted) {
    final pos = Offset(planet.x, planet.y);
    final r = planet.radius * (isHighlighted ? highlightPulse : 1.0);

    // Glow aura
    final glowRadius = r * 3.5;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xAA4FC3F7).withValues(alpha: isHighlighted ? 0.6 : 0.25),
          const Color(0x0029B6F6),
        ],
      ).createShader(Rect.fromCircle(center: pos, radius: glowRadius));
    canvas.drawCircle(pos, glowRadius, glowPaint);

    // Outer ring glow
    final ringPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF81D4FA).withValues(alpha: isHighlighted ? 0.8 : 0.3),
          const Color(0x0029B6F6),
        ],
        radius: 0.7,
      ).createShader(Rect.fromCircle(center: pos, radius: r * 2));
    canvas.drawCircle(pos, r * 2, ringPaint);

    // Core: warm glow
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          const Color(0xFFE1F5FE),
          const Color(0xFF4FC3F7),
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromCircle(center: pos, radius: r));
    canvas.drawCircle(pos, r, corePaint);

    // Sparkle particles around lit planet (only at certain animation frames)
    if ((planet.x * 100).round() % 3 == 0) {
      _drawSparkles(canvas, pos, r);
    }
  }

  void _drawDarkPlanet(Canvas canvas, Planet planet) {
    final pos = Offset(planet.x, planet.y);
    final r = planet.radius;

    // Dark core
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF2A2A3A),
          const Color(0xFF1A1A2E),
          const Color(0xFF0A0A15),
        ],
      ).createShader(Rect.fromCircle(center: pos, radius: r));
    canvas.drawCircle(pos, r, corePaint);

    // Very subtle outline to make it visible against dark background
    final outlinePaint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(pos, r, outlinePaint);
  }

  void _drawSparkles(Canvas canvas, Offset center, double radius) {
    final rng = Random(planetHash(center));
    for (int i = 0; i < 3; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = radius * 1.5 + rng.nextDouble() * radius * 2;
      final sx = center.dx + cos(angle) * dist;
      final sy = center.dy + sin(angle) * dist;
      final sparkAlpha = 0.3 + rng.nextDouble() * 0.5;

      canvas.drawCircle(
        Offset(sx, sy),
        1.0,
        Paint()..color = Colors.white.withValues(alpha: sparkAlpha),
      );
    }
  }

  int planetHash(Offset pos) {
    return (pos.dx * 1000 + pos.dy * 1000).round().abs();
  }

  @override
  bool shouldRepaint(covariant _UniversePainter old) => true;
}
