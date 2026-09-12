import 'dart:math' as math;

import 'package:flutter/material.dart';

class CampusXAnimatedBackground extends StatefulWidget {
  final Widget child;

  const CampusXAnimatedBackground({super.key, required this.child});

  @override
  State<CampusXAnimatedBackground> createState() =>
      _CampusXAnimatedBackgroundState();
}

class _CampusXAnimatedBackgroundState extends State<CampusXAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    final random = math.Random(42);

    _particles = List.generate(
      42,
      (_) => _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: 1.0 + random.nextDouble() * 2.5,
        speed: 0.15 + random.nextDouble() * 0.35,
        phase: random.nextDouble() * math.pi * 2,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _NetworkPainter(
                  particles: _particles,
                  progress: _controller.value,
                ),
              );
            },
          ),
        ),

        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _Particle {
  double x;
  double y;
  final double radius;
  final double speed;
  final double phase;

  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
  });
}

class _NetworkPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _NetworkPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final positions = <Offset>[];

    for (final particle in particles) {
      final movement = math.sin(
        progress * math.pi * 2 * particle.speed + particle.phase,
      );

      final x = ((particle.x + movement * 0.025) % 1.0) * size.width;

      final yMovement = math.cos(
        progress * math.pi * 2 * particle.speed + particle.phase,
      );

      final y = ((particle.y + yMovement * 0.018) % 1.0) * size.height;

      positions.add(Offset(x, y));
    }

    final linePaint = Paint()
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final distance = (positions[i] - positions[j]).distance;

        if (distance < 105) {
          final opacity = (1 - distance / 105) * 0.20;

          linePaint.color = Colors.cyan.withValues(alpha: opacity);

          canvas.drawLine(positions[i], positions[j], linePaint);
        }
      }
    }

    for (int i = 0; i < positions.length; i++) {
      final particle = particles[i];
      final pulse =
          0.75 + 0.25 * math.sin(progress * math.pi * 2 + particle.phase);

      final radius = particle.radius * pulse;

      final glowPaint = Paint()
        ..color = Colors.cyan.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

      canvas.drawCircle(positions[i], radius * 3.5, glowPaint);

      final dotPaint = Paint()..color = Colors.cyan.withValues(alpha: 0.55);

      canvas.drawCircle(positions[i], radius, dotPaint);
    }

    final gradientPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment.topRight,
        radius: 1.2,
        colors: [Color(0x331D4ED8), Color(0x00111A35)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Offset.zero & size, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant _NetworkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
