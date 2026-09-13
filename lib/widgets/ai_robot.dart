import 'dart:math' as math;

import 'package:flutter/material.dart';

enum AIRobotExpression { happy, thinking, speaking, error, idle }

class AIRobot extends StatefulWidget {
  final AIRobotExpression expression;
  final double size;

  const AIRobot({
    super.key,
    this.expression = AIRobotExpression.idle,
    this.size = 150,
  });

  @override
  State<AIRobot> createState() => _AIRobotState();
}

class _AIRobotState extends State<AIRobot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _color(BuildContext context) {
    switch (widget.expression) {
      case AIRobotExpression.happy:
        return Colors.greenAccent;
      case AIRobotExpression.thinking:
        return Colors.amberAccent;
      case AIRobotExpression.speaking:
        return Colors.cyanAccent;
      case AIRobotExpression.error:
        return Colors.redAccent;
      case AIRobotExpression.idle:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);

    // Keep the robot compact inside the available dashboard space.
    final s = widget.size.clamp(48.0, 150.0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * math.pi * 2;

        final floatY = math.sin(t) * 2.5;

        final handMove = widget.expression == AIRobotExpression.speaking
            ? math.sin(t * 2) * 4
            : math.sin(t) * 2;

        final bodyScale = widget.expression == AIRobotExpression.thinking
            ? 1.0 + math.sin(t * 2) * 0.01
            : 1.0;

        final glowPulse = widget.expression == AIRobotExpression.speaking
            ? 1.0 + math.sin(t * 2) * 0.06
            : 1.0;

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Transform.scale(
            scale: bodyScale,
            child: SizedBox(
              width: s,
              height: s * 1.30,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Glow
                  IgnorePointer(
                    child: Container(
                      width: s * 0.72 * glowPulse,
                      height: s * 0.72 * glowPulse,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.20),
                            blurRadius:
                                widget.expression == AIRobotExpression.speaking
                                ? 28
                                : 22,
                            spreadRadius:
                                widget.expression == AIRobotExpression.speaking
                                ? 7
                                : 5,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Antenna
                  Positioned(
                    top: s * 0.01,
                    child: Column(
                      children: [
                        Container(
                          width: 2.5,
                          height: s * 0.09,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Container(
                          width: s * 0.07,
                          height: s * 0.07,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.7),
                                blurRadius: 9,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Head
                  Positioned(
                    top: s * 0.105,
                    child: Container(
                      width: s * 0.62,
                      height: s * 0.43,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: color,
                          width: widget.expression == AIRobotExpression.speaking
                              ? 2.5
                              : 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.15),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: _RobotFace(
                        expression: widget.expression,
                        color: color,
                      ),
                    ),
                  ), // Left arm
                  Positioned(
                    left: s * 0.115,
                    top: s * 0.48 + handMove,
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: widget.expression == AIRobotExpression.speaking
                          ? -0.035
                          : -0.02,
                      child: _RobotArm(color: color, size: s),
                    ),
                  ),

                  // Right arm
                  Positioned(
                    right: s * 0.115,
                    top: s * 0.48 - handMove,
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: widget.expression == AIRobotExpression.speaking
                          ? 0.035
                          : 0.02,
                      child: _RobotArm(color: color, size: s),
                    ),
                  ),

                  // Body
                  Positioned(
                    top: s * 0.58,
                    child: Container(
                      width: s * 0.43,
                      height: s * 0.31,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: color.withValues(alpha: 0.75),
                          width: 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.08),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: s * 0.17,
                          height: s * 0.085,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withValues(alpha: 0.65),
                            ),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: s * 0.06,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Left leg
                  Positioned(
                    top: s * 0.86,
                    left: s * 0.385,
                    child: _RobotLeg(color: color, size: s),
                  ),

                  // Right leg
                  Positioned(
                    top: s * 0.86,
                    right: s * 0.385,
                    child: _RobotLeg(color: color, size: s),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RobotArm extends StatelessWidget {
  final Color color;
  final double size;

  const _RobotArm({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size * 0.052,
          height: size * 0.16,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
          ),
        ),
        Container(
          width: size * 0.085,
          height: size * 0.085,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
      ],
    );
  }
}

class _RobotLeg extends StatelessWidget {
  final Color color;
  final double size;

  const _RobotLeg({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size * 0.06,
          height: size * 0.13,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
          ),
        ),
        Container(
          width: size * 0.12,
          height: size * 0.055,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.75),
              width: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _RobotFace extends StatefulWidget {
  final AIRobotExpression expression;
  final Color color;

  const _RobotFace({required this.expression, required this.color});

  @override
  State<_RobotFace> createState() => _RobotFaceState();
}

class _RobotFaceState extends State<_RobotFace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkController;

  @override
  void initState() {
    super.initState();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    _blinkLoop();
  }

  Future<void> _blinkLoop() async {
    final random = math.Random();

    while (mounted) {
      await Future.delayed(Duration(milliseconds: 2200 + random.nextInt(2400)));

      if (!mounted) return;

      await _blinkController.forward();

      if (!mounted) return;

      await _blinkController.reverse();
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eyeHeight = Tween<double>(
      begin: 12,
      end: 2,
    ).evaluate(_blinkController);

    final eyeWidth = widget.expression == AIRobotExpression.thinking
        ? 10.0
        : 12.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RobotEye(
              color: widget.color,
              height: eyeHeight,
              width: eyeWidth,
              expression: widget.expression,
            ),
            const SizedBox(width: 16),
            _RobotEye(
              color: widget.color,
              height: eyeHeight,
              width: eyeWidth,
              expression: widget.expression,
            ),
          ],
        ),
        const SizedBox(height: 9),
        _RobotMouth(color: widget.color, expression: widget.expression),
      ],
    );
  }
}

class _RobotEye extends StatelessWidget {
  final Color color;
  final double height;
  final double width;
  final AIRobotExpression expression;

  const _RobotEye({
    required this.color,
    required this.height,
    required this.width,
    required this.expression,
  });

  @override
  Widget build(BuildContext context) {
    final radius = expression == AIRobotExpression.thinking ? 6.0 : 14.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.65), blurRadius: 6),
        ],
      ),
    );
  }
}

class _RobotMouth extends StatelessWidget {
  final Color color;
  final AIRobotExpression expression;

  const _RobotMouth({required this.color, required this.expression});

  @override
  Widget build(BuildContext context) {
    switch (expression) {
      case AIRobotExpression.speaking:
        return _SpeakingMouth(color: color);

      case AIRobotExpression.happy:
        return Container(
          width: 28,
          height: 13,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: color, width: 3)),
            borderRadius: BorderRadius.circular(16),
          ),
        );

      case AIRobotExpression.error:
        return Container(
          width: 25,
          height: 8,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: color, width: 3)),
          ),
        );

      case AIRobotExpression.thinking:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThinkingDot(color: color),
            const SizedBox(width: 3),
            _ThinkingDot(color: color),
            const SizedBox(width: 3),
            _ThinkingDot(color: color),
          ],
        );

      case AIRobotExpression.idle:
        return Container(
          width: 20,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        );
    }
  }
}

class _ThinkingDot extends StatelessWidget {
  final Color color;

  const _ThinkingDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _SpeakingMouth extends StatefulWidget {
  final Color color;

  const _SpeakingMouth({required this.color});

  @override
  State<_SpeakingMouth> createState() => _SpeakingMouthState();
}

class _SpeakingMouthState extends State<_SpeakingMouth>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..repeat(reverse: true);
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
        final height = 7 + (_controller.value * 6);

        return Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.35),
                blurRadius: 6,
              ),
            ],
          ),
        );
      },
    );
  }
}
