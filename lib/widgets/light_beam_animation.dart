import 'dart:math';
import 'package:flutter/material.dart';

class LightBeamAnimation extends StatefulWidget {
  final Offset startPoint;
  final Offset endPoint;
  final VoidCallback onComplete;

  const LightBeamAnimation({
    super.key,
    required this.startPoint,
    required this.endPoint,
    required this.onComplete,
  });

  @override
  State<LightBeamAnimation> createState() => _LightBeamAnimationState();
}

class _LightBeamAnimationState extends State<LightBeamAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;
  late Animation<double> _particleSpread;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _particleSpread = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _LightBeamPainter(
            start: widget.startPoint,
            end: widget.endPoint,
            progress: _progress.value,
            particleSpread: _particleSpread.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _LightBeamPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final double progress;
  final double particleSpread;

  _LightBeamPainter({
    required this.start,
    required this.end,
    required this.progress,
    required this.particleSpread,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final totalDist = sqrt(dx * dx + dy * dy);
    if (totalDist <= 0) return;

    final beamDir = Offset(dx / totalDist, dy / totalDist);
    final perpDir = Offset(-beamDir.dy, beamDir.dx);

    // --- Main beam ---
    final beamHead = Offset(
      start.dx + dx * progress,
      start.dy + dy * progress,
    );

    // Beam trail: thick bright line with gradient
    final trailLen = 80.0 * (1 - progress * 0.3);
    final trailStart = beamHead - beamDir * trailLen;

    // Core beam (bright white center)
    final beamPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9),
          const Color(0xAA81D4FA),
          const Color(0x0029B6F6),
        ],
        begin: Alignment(beamDir.dx, beamDir.dy),
        end: Alignment(-beamDir.dx * 0.5, -beamDir.dy * 0.5),
      ).createShader(Rect.fromPoints(trailStart, beamHead));

    canvas.drawLine(trailStart, beamHead,
        beamPaint..strokeWidth = 4.0 + (1 - progress) * 2);

    // Outer glow
    canvas.drawLine(
      trailStart + perpDir * 3,
      beamHead + perpDir * 3,
      Paint()
        ..color = const Color(0x444FC3F7)
        ..strokeWidth = 10 + (1 - progress) * 5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawLine(
      trailStart - perpDir * 3,
      beamHead - perpDir * 3,
      Paint()
        ..color = const Color(0x444FC3F7)
        ..strokeWidth = 10 + (1 - progress) * 5
        ..strokeCap = StrokeCap.round,
    );

    // --- Trailing particles ---
    final rng = Random(42);
    for (int i = 0; i < 12; i++) {
      final t = progress - (i / 12) * 0.5;
      if (t < 0) continue;

      final pos = Offset(
        start.dx + dx * t,
        start.dy + dy * t,
      );

      final offsetAngle = rng.nextDouble() * 2 * pi;
      final offsetDist = 4.0 + rng.nextDouble() * 12;
      final particlePos = Offset(
        pos.dx + cos(offsetAngle) * offsetDist,
        pos.dy + sin(offsetAngle) * offsetDist,
      );

      final alpha = 0.3 + t * 0.5;
      canvas.drawCircle(
        particlePos,
        1.5 + rng.nextDouble() * 2,
        Paint()..color = const Color(0xAA81D4FA).withValues(alpha: alpha),
      );
    }

    // --- Impact particles at destination ---
    if (particleSpread > 0) {
      final particlesRng = Random(123);
      for (int i = 0; i < 25; i++) {
        final angle = particlesRng.nextDouble() * 2 * pi;
        final dist = particleSpread * (8 + particlesRng.nextDouble() * 30);
        final ppx = end.dx + cos(angle) * dist;
        final ppy = end.dy + sin(angle) * dist;
        final alpha = (1.0 - particleSpread) * 0.8;
        final particleSize = 1.0 + particlesRng.nextDouble() * 2.5;

        canvas.drawCircle(
          Offset(ppx, ppy),
          particleSize,
          Paint()
            ..color = const Color(0xAAE1F5FE).withValues(alpha: alpha),
        );
      }

      // Impact glow ring
      final ringRadius = particleSpread * 40;
      canvas.drawCircle(
        end,
        ringRadius,
        Paint()
          ..color = const Color(0x44FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LightBeamPainter old) => true;
}
