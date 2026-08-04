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
  State<UniverseCanvas> createState() => UniverseCanvasState();
}

class UniverseCanvasState extends State<UniverseCanvas>
    with TickerProviderStateMixin {
  // Camera transform
  double _offsetX = 0;
  double _offsetY = 0;
  double _scale = 1.0;
  double _rotation = 0;

  // Interaction state
  Offset? _lastFocalPoint;
  double? _initialScale;
  Offset? _initialOffset;

  // Animation controllers
  late AnimationController _floatController;
  final List<_Star> _stars = [];
  final List<_NebulaParticle> _nebula = [];
  final List<_ShootingStar> _shootingStars = [];

  // Highlight animation
  double _highlightPulse = 1.0;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _floatController.addListener(_onTick);
    _generateStars(2500);
    _generateNebula(150);
    _generateShootingStars();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _onTick() {
    // Rotate background stars
    _rotation += 0.0003;
    if (_rotation > 2 * pi) _rotation -= 2 * pi;

    // Pulse on highlighted planet
    if (widget.highlightedPlanetId != null) {
      _highlightPulse = 1.0 + sin(_floatController.value * 20) * 0.3;
    }

    // Update shooting stars
    for (final star in _shootingStars) {
      star.update();
    }
  }

  void _generateStars(int count) {
    final rng = Random(42);
    for (int i = 0; i < count; i++) {
      _stars.add(_Star(
        x: rng.nextDouble() * 6000 - 3000,
        y: rng.nextDouble() * 6000 - 3000,
        size: 0.2 + rng.nextDouble() * 2.5,
        brightness: 0.2 + rng.nextDouble() * 0.8,
        twinkleSpeed: 0.3 + rng.nextDouble() * 3.0,
        twinkleOffset: rng.nextDouble() * 2 * pi,
        color: _randomStarColor(rng),
      ));
    }
  }

  Color _randomStarColor(Random rng) {
    final roll = rng.nextDouble();
    if (roll < 0.7) return Colors.white;
    if (roll < 0.8) return const Color(0xFFFFF4E6); // Warm white
    if (roll < 0.88) return const Color(0xFFE6F0FF); // Blue white
    if (roll < 0.94) return const Color(0xFFFFD699); // Orange
    return const Color(0xFFFFB3BA); // Pinkish
  }

  void _generateNebula(int count) {
    final rng = Random(99);
    for (int i = 0; i < count; i++) {
      _nebula.add(_NebulaParticle(
        x: rng.nextDouble() * 4000 - 2000,
        y: rng.nextDouble() * 4000 - 2000,
        radius: 30 + rng.nextDouble() * 120,
        alpha: 0.03 + rng.nextDouble() * 0.1,
        hue: rng.nextDouble() * 360,
        driftX: (rng.nextDouble() - 0.5) * 0.2,
        driftY: (rng.nextDouble() - 0.5) * 0.2,
      ));
    }
  }

  void _generateShootingStars() {
    final rng = Random(77);
    for (int i = 0; i < 12; i++) {
      _shootingStars.add(_ShootingStar(
        x: rng.nextDouble() * 4000 - 2000,
        y: rng.nextDouble() * 4000 - 2000,
        angle: rng.nextDouble() * pi * 2,
        speed: 2.0 + rng.nextDouble() * 4.0,
        length: 30 + rng.nextDouble() * 70,
        delay: rng.nextDouble() * 300,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      onTapUp: _onTapUp,
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            return CustomPaint(
              painter: _UniversePainter(
                planets: widget.planets,
                highlightedPlanetId: widget.highlightedPlanetId,
                stars: _stars,
                nebula: _nebula,
                shootingStars: _shootingStars,
                offsetX: _offsetX,
                offsetY: _offsetY,
                scale: _scale,
                rotation: _rotation,
                highlightPulse: _highlightPulse,
                animValue: _floatController.value,
                floatValue: _floatController.value,
              ),
            );
          },
        ),
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

    final screenCenterX = widget.screenSize.width / 2;
    final screenCenterY = widget.screenSize.height / 2;

    final ux = (details.localPosition.dx - screenCenterX) / _scale - _offsetX;
    final uy = (details.localPosition.dy - screenCenterY) / _scale - _offsetY;

    // Current animation value for float calculation
    final animVal = _floatController.value;

    String? nearestId;
    double minDist = double.infinity;

    for (final planet in widget.planets) {
      // Calculate float offset — must match the drawing logic exactly
      final floatX = sin(animVal * planet.floatSpeed * 2 * pi + planet.floatPhase) * planet.floatAmplitude;
      final floatY = cos(animVal * planet.floatSpeed * 1.5 * pi + planet.floatPhase * 1.3) * planet.floatAmplitude * 0.7;

      // Use float-adjusted position for hit test
      final dx = (planet.x + floatX) - ux;
      final dy = (planet.y + floatY) - uy;
      final dist = sqrt(dx * dx + dy * dy);

      // Lit planets get a larger hit radius (min 30px) so they're easy to tap;
      // dark planets keep the standard radius since they're not interactive
      double hitRadius;
      if (planet.isLit) {
        hitRadius = max(planet.radius * 4, 30.0) / _scale;
      } else {
        hitRadius = planet.radius * 3 / _scale;
      }

      if (dist < hitRadius && dist < minDist) {
        nearestId = planet.id;
        minDist = dist;
      }
    }

    if (nearestId != null) {
      widget.onPlanetTapWithId!(nearestId);
    }
  }

  Offset getPlanetScreenPos(String planetId) {
    final planet = widget.planets.firstWhere(
      (p) => p.id == planetId,
      orElse: () => widget.planets.first,
    );

    final screenCenterX = widget.screenSize.width / 2;
    final screenCenterY = widget.screenSize.height / 2;

    // Account for floating animation offset so beam ends at actual planet position
    final floatX = sin(_floatController.value * planet.floatSpeed * 2 * pi + planet.floatPhase) * planet.floatAmplitude;
    final floatY = cos(_floatController.value * planet.floatSpeed * 1.5 * pi + planet.floatPhase * 1.3) * planet.floatAmplitude * 0.7;

    final sx = (planet.x + floatX + _offsetX) * _scale + screenCenterX;
    final sy = (planet.y + floatY + _offsetY) * _scale + screenCenterY;

    return Offset(sx, sy);
  }

  /// Center camera on a specific planet so the user can see it
  void centerOnPlanet(String planetId) {
    final planet = widget.planets.firstWhere(
      (p) => p.id == planetId,
      orElse: () => widget.planets.first,
    );

    setState(() {
      // Center camera on the planet
      _offsetX = -planet.x;
      _offsetY = -planet.y;
    });
  }
}

class _Star {
  final double x, y, size, brightness, twinkleSpeed, twinkleOffset;
  final Color color;
  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.brightness,
    required this.twinkleSpeed,
    required this.twinkleOffset,
    required this.color,
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

class _ShootingStar {
  double x, y;
  final double angle;
  final double speed;
  final double length;
  double delay;
  double progress = 0;
  bool active = false;

  _ShootingStar({
    required this.x,
    required this.y,
    required this.angle,
    required this.speed,
    required this.length,
    required this.delay,
  });

  void update() {
    if (!active) {
      delay -= 0.016;
      if (delay <= 0) {
        active = true;
        progress = 0;
      }
      return;
    }

    progress += speed;
    x += cos(angle) * speed;
    y += sin(angle) * speed;

    if (progress > length * 3) {
      active = false;
      delay = 100 + Random().nextDouble() * 400;
      // Reset position
      final rng = Random();
      x = rng.nextDouble() * 4000 - 2000;
      y = rng.nextDouble() * 4000 - 2000;
    }
  }
}

class _UniversePainter extends CustomPainter {
  final List<Planet> planets;
  final String? highlightedPlanetId;
  final List<_Star> stars;
  final List<_NebulaParticle> nebula;
  final List<_ShootingStar> shootingStars;
  final double offsetX, offsetY, scale, rotation;
  final double highlightPulse;
  final double animValue;
  final double floatValue;

  _UniversePainter({
    required this.planets,
    this.highlightedPlanetId,
    required this.stars,
    required this.nebula,
    required this.shootingStars,
    required this.offsetX,
    required this.offsetY,
    required this.scale,
    required this.rotation,
    required this.highlightPulse,
    required this.animValue,
    required this.floatValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Deep space background with subtle gradient
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.3, -0.3),
        radius: 1.2,
        colors: [
          const Color(0xFF0A0A2E),
          const Color(0xFF050510),
          const Color(0xFF020208),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      bgPaint,
    );

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.scale(scale);
    canvas.translate(offsetX, offsetY);

    // --- Milky Way band ---
    _drawMilkyWay(canvas);

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

    // --- Shooting stars ---
    _drawShootingStars(canvas);

    canvas.restore();
  }

  void _drawMilkyWay(Canvas canvas) {
    // Draw a subtle galaxy band across the universe
    final galaxyPaint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-1, -0.3),
        end: const Alignment(1, 0.3),
        colors: [
          const Color(0x001A1A3E),
          const Color(0xFF151530),
          const Color(0xFF201840),
          const Color(0xFF151530),
          const Color(0x001A1A3E),
        ],
      ).createShader(const Rect.fromLTRB(-3000, -400, 3000, 400));

    canvas.drawRect(const Rect.fromLTRB(-3000, -400, 3000, 400), galaxyPaint);

    // Second band offset
    final galaxyPaint2 = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-1, 0.2),
        end: const Alignment(1, -0.2),
        colors: [
          const Color(0x00101028),
          const Color(0xFF0D0D20),
          const Color(0xFF121228),
          const Color(0xFF0D0D20),
          const Color(0x00101028),
        ],
      ).createShader(const Rect.fromLTRB(-3000, -200, 3000, 600));

    canvas.drawRect(const Rect.fromLTRB(-3000, -200, 3000, 600), galaxyPaint2);
  }

  void _drawNebula(Canvas canvas) {
    for (final n in nebula) {
      final driftX = n.driftX * sin(animValue * 0.5);
      final driftY = n.driftY * cos(animValue * 0.3);
      final nx = n.x + driftX;
      final ny = n.y + driftY;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            HSLColor.fromAHSL(n.alpha, n.hue, 0.6, 0.5).toColor(),
            HSLColor.fromAHSL(n.alpha * 0.5, n.hue, 0.6, 0.5).toColor(),
            HSLColor.fromAHSL(0, n.hue, 0.6, 0.5).toColor(),
          ],
        ).createShader(Rect.fromCircle(center: Offset(nx, ny), radius: n.radius));

      canvas.drawCircle(Offset(nx, ny), n.radius, paint);
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

      // Depth filter
      final depth = (rx.abs() + ry.abs()) / 4000;
      if (background && depth > 0.5) continue;
      if (!background && depth <= 0.5) continue;

      // Twinkle
      final twinkle =
          0.5 + 0.5 * sin(animValue * star.twinkleSpeed + star.twinkleOffset);
      final alpha = star.brightness * (0.4 + 0.6 * twinkle);

      starPaint.color = star.color.withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(rx, ry), star.size, starPaint);

      // Cross sparkle for bright stars
      if (star.brightness > 0.8 && star.size > 1.5) {
        final sparkleAlpha = alpha * 0.5 * twinkle;
        starPaint.color = star.color.withValues(alpha: sparkleAlpha.clamp(0.0, 1.0));
        canvas.drawLine(
          Offset(rx - star.size * 2, ry),
          Offset(rx + star.size * 2, ry),
          starPaint..strokeWidth = 0.3,
        );
        canvas.drawLine(
          Offset(rx, ry - star.size * 2),
          Offset(rx, ry + star.size * 2),
          starPaint..strokeWidth = 0.3,
        );
      }
    }
  }

  void _drawPlanets(Canvas canvas, List<Planet> sortedPlanets) {
    for (final planet in sortedPlanets) {
      final isHighlighted = planet.id == highlightedPlanetId;

      // Calculate floating offset
      final floatX = sin(floatValue * planet.floatSpeed * 2 * pi + planet.floatPhase) * planet.floatAmplitude;
      final floatY = cos(floatValue * planet.floatSpeed * 1.5 * pi + planet.floatPhase * 1.3) * planet.floatAmplitude * 0.7;
      final floatOffset = Offset(floatX, floatY);

      if (planet.isLit) {
        _drawLitPlanet(canvas, planet, isHighlighted, floatOffset);
      } else {
        _drawDarkPlanet(canvas, planet, floatOffset);
      }
    }
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF4FC3F7);
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF4FC3F7);
    }
  }

  void _drawLitPlanet(Canvas canvas, Planet planet, bool isHighlighted, Offset floatOffset) {
    final pos = Offset(planet.x + floatOffset.dx, planet.y + floatOffset.dy);
    final breathe = 1.0 + sin(animValue * planet.floatSpeed * 4 * pi + planet.floatPhase) * 0.08;
    final r = planet.radius * (isHighlighted ? highlightPulse : 1.0) * breathe;
    final baseColor = _hexToColor(planet.colorHex);

    // Persistent slow pulse for lit planets - makes them clearly distinguishable from dark ones
    final litPulse = 1.0 + sin(animValue * 2 * pi * 0.4 + planet.floatPhase) * 0.15;
    final litAlphaBoost = 0.7 + sin(animValue * 2 * pi * 0.4 + planet.floatPhase) * 0.15;

    // Outer glow aura - dramatically larger so even small planets are visible
    final glowRadius = (r * 12.0 + 30.0) * litPulse; // Minimum 30px glow, pulses gently
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withValues(alpha: isHighlighted ? 0.8 * litAlphaBoost : 0.65 * litAlphaBoost),
          baseColor.withValues(alpha: 0.25),
          baseColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: pos, radius: glowRadius));
    canvas.drawCircle(pos, glowRadius, glowPaint);

    // Middle ring glow - strong colorful halo
    final ringRadius = r * 5.0 * litPulse;
    final ringPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withValues(alpha: isHighlighted ? 0.9 : 0.7),
          baseColor.withValues(alpha: 0.3),
          baseColor.withValues(alpha: 0.0),
        ],
        radius: 0.7,
      ).createShader(Rect.fromCircle(center: pos, radius: ringRadius));
    canvas.drawCircle(pos, ringRadius, ringPaint);

    // Core: bright gradient from white center to colored edge
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          baseColor.withValues(alpha: 0.95),
          baseColor.withValues(alpha: 0.7),
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromCircle(center: pos, radius: r * 1.2));
    canvas.drawCircle(pos, r * 1.2, corePaint);

    // Bright highlight spot (like a reflection)
    final highlightSpotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(
      Offset(pos.dx - r * 0.25, pos.dy - r * 0.25),
      r * 0.35,
      highlightSpotPaint,
    );

    // Sparkle particles around lit planet
    _drawSparkles(canvas, pos, r, baseColor);
  }

  void _drawDarkPlanet(Canvas canvas, Planet planet, Offset floatOffset) {
    final pos = Offset(planet.x + floatOffset.dx, planet.y + floatOffset.dy);
    final breathe = 1.0 + sin(animValue * planet.floatSpeed * 3 * pi + planet.floatPhase) * 0.08;
    final r = planet.radius * breathe;
    final baseColor = _hexToColor(planet.colorHex);

    // Subtle dark glow - visible enough to see planet is there
    final darkGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withValues(alpha: 0.18),
          baseColor.withValues(alpha: 0.06),
          baseColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: pos, radius: r * 3.0));
    canvas.drawCircle(pos, r * 3.0, darkGlowPaint);

    // Dark core - dimly visible
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withValues(alpha: 0.3),
          baseColor.withValues(alpha: 0.1),
          const Color(0xFF050510),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: pos, radius: r));
    canvas.drawCircle(pos, r, corePaint);

    // Subtle outline
    final outlinePaint = Paint()
      ..color = baseColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(pos, r, outlinePaint);

    // Center dot - small but visible
    final dotPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    canvas.drawCircle(pos, r * 0.15, dotPaint);
  }

  void _drawSparkles(Canvas canvas, Offset center, double radius, Color color) {
    final rng = Random(planetHash(center));
    for (int i = 0; i < 4; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = radius * 1.8 + rng.nextDouble() * radius * 2.5;
      final sx = center.dx + cos(angle) * dist;
      final sy = center.dy + sin(angle) * dist;
      final sparkAlpha = 0.3 + rng.nextDouble() * 0.6;
      final sparkSize = 0.5 + rng.nextDouble() * 1.5;

      canvas.drawCircle(
        Offset(sx, sy),
        sparkSize,
        Paint()..color = color.withValues(alpha: sparkAlpha),
      );
    }
  }

  void _drawShootingStars(Canvas canvas) {
    for (final star in shootingStars) {
      if (!star.active) continue;

      final tailX = star.x - cos(star.angle) * star.length;
      final tailY = star.y - sin(star.angle) * star.length;

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromPoints(Offset(star.x, star.y), Offset(tailX, tailY)))
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(tailX, tailY), Offset(star.x, star.y), paint);
    }
  }

  int planetHash(Offset pos) {
    return (pos.dx * 1000 + pos.dy * 1000).round().abs();
  }

  @override
  bool shouldRepaint(covariant _UniversePainter old) => true;
}
