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

    // Keep the complete robot safely inside its own box.
    final s = widget.size.clamp(48.0, 150.0).toDouble();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * math.pi * 2;

        final floatY = math.sin(t) * 1.5;

        final handMove = widget.expression == AIRobotExpression.speaking
            ? math.sin(t * 2) * 2.5
            : math.sin(t) * 1.2;

        final bodyScale = widget.expression == AIRobotExpression.thinking
            ? 1.0 + math.sin(t * 2) * 0.006
            : 1.0;

        final glowPulse = widget.expression == AIRobotExpression.speaking
            ? 1.0 + math.sin(t * 2) * 0.035
            : 1.0;

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Transform.scale(
            scale: bodyScale,
            child: SizedBox(
              width: s,
              height: s * 1.28,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                alignment: Alignment.center,
                children: [
                  // Glow
                  IgnorePointer(
                    child: Container(
                      width: s * 0.68 * glowPulse,
                      height: s * 0.68 * glowPulse,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.18),
                            blurRadius:
                                widget.expression == AIRobotExpression.speaking
                                ? 22
                                : 18,
                            spreadRadius:
                                widget.expression == AIRobotExpression.speaking
                                ? 5
                                : 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Antenna
                  Positioned(
                    top: s * 0.015,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 2.2,
                          height: s * 0.075,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Container(
                          width: s * 0.065,
                          height: s * 0.065,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.65),
                                blurRadius: 7,
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
                    child: SizedBox(
                      width: s * 0.60,
                      height: s * 0.40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: color,
                            width:
                                widget.expression == AIRobotExpression.speaking
                                ? 2.2
                                : 1.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.13),
                              blurRadius: 9,
                            ),
                          ],
                        ),
                        child: _RobotFace(
                          expression: widget.expression,
                          color: color,
                        ),
                      ),
                    ),
                  ),

                  // Left arm
                  Positioned(
                    left: s * 0.13,
                    top: s * 0.48 + handMove,
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: widget.expression == AIRobotExpression.speaking
                          ? -0.025
                          : -0.015,
                      child: _RobotArm(color: color, size: s),
                    ),
                  ),

                  // Right arm
                  Positioned(
                    right: s * 0.13,
                    top: s * 0.48 - handMove,
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: widget.expression == AIRobotExpression.speaking
                          ? 0.025
                          : 0.015,
                      child: _RobotArm(color: color, size: s),
                    ),
                  ),

                  // Body
                  Positioned(
                    top: s * 0.58,
                    child: Container(
                      width: s * 0.41,
                      height: s * 0.29,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: color.withValues(alpha: 0.72),
                          width: 1.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.07),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: s * 0.15,
                          height: s * 0.075,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: color.withValues(alpha: 0.60),
                            ),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: s * 0.052,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Left leg
                  Positioned(
                    top: s * 0.86,
                    left: s * 0.39,
                    child: _RobotLeg(color: color, size: s),
                  ),

                  // Right leg
                  Positioned(
                    top: s * 0.86,
                    right: s * 0.39,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size * 0.045,
          height: size * 0.145,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.65),
              width: 1.3,
            ),
          ),
        ),
        Container(
          width: size * 0.075,
          height: size * 0.075,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.13),
            border: Border.all(color: color, width: 1.3),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size * 0.052,
          height: size * 0.115,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.65),
              width: 1.3,
            ),
          ),
        ),
        Container(
          width: size * 0.105,
          height: size * 0.048,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.70),
              width: 1.1,
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
      begin: 10,
      end: 2,
    ).evaluate(_blinkController);

    final eyeWidth = widget.expression == AIRobotExpression.thinking
        ? 8.5
        : 10.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RobotEye(
              color: widget.color,
              height: eyeHeight,
              width: eyeWidth,
              expression: widget.expression,
            ),
            const SizedBox(width: 12),
            _RobotEye(
              color: widget.color,
              height: eyeHeight,
              width: eyeWidth,
              expression: widget.expression,
            ),
          ],
        ),
        const SizedBox(height: 7),
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
    final radius = expression == AIRobotExpression.thinking ? 5.0 : 12.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.60), blurRadius: 5),
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
          width: 24,
          height: 11,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: color, width: 2.5)),
            borderRadius: BorderRadius.circular(14),
          ),
        );

      case AIRobotExpression.error:
        return Container(
          width: 22,
          height: 7,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: color, width: 2.5)),
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
          width: 18,
          height: 3.5,
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
      width: 3.5,
      height: 3.5,
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
        final height = 6 + (_controller.value * 4);

        return Container(
          width: 21,
          height: height,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.30),
                blurRadius: 5,
              ),
            ],
          ),
        );
      },
    );
  }
}
