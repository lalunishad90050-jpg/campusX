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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * math.pi * 2;

        final floatY = math.sin(t) * 4;

        final handMove = widget.expression == AIRobotExpression.speaking
            ? math.sin(t * 2) * 7
            : math.sin(t) * 3;

        final bodyScale = widget.expression == AIRobotExpression.thinking
            ? 1.0 + math.sin(t * 2) * 0.015
            : 1.0;

        final glowPulse = widget.expression == AIRobotExpression.speaking
            ? 1.0 + math.sin(t * 2) * 0.12
            : 1.0;

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Transform.scale(
            scale: bodyScale,
            child: SizedBox(
              width: widget.size * 1.15,
              height: widget.size * 1.45,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: widget.size * 0.9 * glowPulse,
                    height: widget.size * 0.9 * glowPulse,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.22),
                          blurRadius:
                              widget.expression == AIRobotExpression.speaking
                              ? 48
                              : 38,
                          spreadRadius:
                              widget.expression == AIRobotExpression.speaking
                              ? 14
                              : 10,
                        ),
                      ],
                    ),
                  ),

                  // Antenna
                  Positioned(
                    top: 0,
                    child: Column(
                      children: [
                        Container(
                          width: 3,
                          height: widget.size * 0.13,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: widget.size * 0.09,
                          height: widget.size * 0.09,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.8),
                                blurRadius:
                                    widget.expression ==
                                        AIRobotExpression.speaking
                                    ? 18
                                    : 12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Head
                  Positioned(
                    top: widget.size * 0.13,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: widget.size * 0.68,
                      height: widget.size * 0.52,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: color,
                          width: widget.expression == AIRobotExpression.speaking
                              ? 3
                              : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.18),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: _RobotFace(
                        expression: widget.expression,
                        color: color,
                      ),
                    ),
                  ),

                  // Left arm
                  Positioned(
                    left: widget.size * 0.08,
                    top: widget.size * 0.58 + handMove,
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 250),
                      turns: widget.expression == AIRobotExpression.speaking
                          ? -0.04
                          : -0.028,
                      child: _RobotArm(color: color, size: widget.size),
                    ),
                  ),

                  // Right arm
                  Positioned(
                    right: widget.size * 0.08,
                    top: widget.size * 0.58 - handMove,
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 250),
                      turns: widget.expression == AIRobotExpression.speaking
                          ? 0.04
                          : 0.028,
                      child: _RobotArm(color: color, size: widget.size),
                    ),
                  ),

                  // Body
                  Positioned(
                    top: widget.size * 0.66,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: widget.size * 0.48,
                      height: widget.size * 0.36,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: color.withValues(alpha: 0.75),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.10),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: widget.size * 0.20,
                          height: widget.size * 0.10,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: color.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: widget.size * 0.07,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Left leg
                  Positioned(
                    top: widget.size * 1.00,
                    left: widget.size * 0.38,
                    child: _RobotLeg(color: color, size: widget.size),
                  ),

                  // Right leg
                  Positioned(
                    top: widget.size * 1.00,
                    right: widget.size * 0.38,
                    child: _RobotLeg(color: color, size: widget.size),
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
          width: size * 0.065,
          height: size * 0.20,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.75), width: 2),
          ),
        ),
        Container(
          width: size * 0.105,
          height: size * 0.105,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.18),
            border: Border.all(color: color, width: 2),
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
          width: size * 0.075,
          height: size * 0.17,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.75), width: 2),
          ),
        ),
        Container(
          width: size * 0.15,
          height: size * 0.07,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withValues(alpha: 0.8)),
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
      duration: const Duration(milliseconds: 150),
    );

    _blinkLoop();
  }

  Future<void> _blinkLoop() async {
    final random = math.Random();

    while (mounted) {
      await Future.delayed(Duration(milliseconds: 2200 + random.nextInt(2600)));

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
      begin: 16,
      end: 2,
    ).evaluate(_blinkController);

    final eyeWidth = widget.expression == AIRobotExpression.thinking
        ? 13.0
        : 16.0;

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
            const SizedBox(width: 22),
            _RobotEye(
              color: widget.color,
              height: eyeHeight,
              width: eyeWidth,
              expression: widget.expression,
            ),
          ],
        ),
        const SizedBox(height: 13),
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
    final radius = expression == AIRobotExpression.thinking ? 8.0 : 20.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.75), blurRadius: 9),
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
          width: 36,
          height: 17,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: color, width: 4)),
            borderRadius: BorderRadius.circular(20),
          ),
        );

      case AIRobotExpression.error:
        return Container(
          width: 32,
          height: 10,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: color, width: 4)),
          ),
        );

      case AIRobotExpression.thinking:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThinkingDot(color: color),
            const SizedBox(width: 4),
            _ThinkingDot(color: color),
            const SizedBox(width: 4),
            _ThinkingDot(color: color),
          ],
        );

      case AIRobotExpression.idle:
        return Container(
          width: 25,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
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
      width: 5,
      height: 5,
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
        final height = 10 + (_controller.value * 10);

        return Container(
          width: 30,
          height: height,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.45),
                blurRadius: 8,
              ),
            ],
          ),
        );
      },
    );
  }
}
