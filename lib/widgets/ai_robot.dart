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

  Color _robotColor(BuildContext context) {
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
    final color = _robotColor(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final movement = math.sin(_controller.value * math.pi * 2) * 5;

        return Transform.translate(
          offset: Offset(0, movement),
          child: SizedBox(
            width: widget.size,
            height: widget.size + 35,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow
                Container(
                  width: widget.size * 0.8,
                  height: widget.size * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 35,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),

                // Robot body
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: widget.size * 0.58,
                    height: widget.size * 0.30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      border: Border.all(
                        color: color.withValues(alpha: 0.7),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                // Robot head
                Positioned(
                  top: widget.size * 0.15,
                  child: Container(
                    width: widget.size * 0.70,
                    height: widget.size * 0.55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(color: color, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.18),
                          blurRadius: 22,
                        ),
                      ],
                    ),
                    child: _RobotFace(
                      expression: widget.expression,
                      color: color,
                    ),
                  ),
                ),

                // Antenna
                Positioned(
                  top: 0,
                  child: Column(
                    children: [
                      Container(width: 4, height: 18, color: color),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.8),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      duration: const Duration(milliseconds: 180),
    );

    _blinkLoop();
  }

  Future<void> _blinkLoop() async {
    while (mounted) {
      await Future.delayed(
        Duration(milliseconds: 2500 + math.Random().nextInt(2500)),
      );

      if (!mounted) return;

      await _blinkController.forward();
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
      begin: 18,
      end: 2,
    ).evaluate(_blinkController);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RobotEye(color: widget.color, height: eyeHeight),
            const SizedBox(width: 28),
            _RobotEye(color: widget.color, height: eyeHeight),
          ],
        ),
        const SizedBox(height: 16),
        _RobotMouth(color: widget.color, expression: widget.expression),
      ],
    );
  }
}

class _RobotEye extends StatelessWidget {
  final Color color;
  final double height;

  const _RobotEye({required this.color, required this.height});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 18,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.75), blurRadius: 10),
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
    if (expression == AIRobotExpression.speaking) {
      return Container(
        width: 30,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
      );
    }

    if (expression == AIRobotExpression.happy) {
      return Container(
        width: 42,
        height: 18,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: color, width: 4)),
          borderRadius: BorderRadius.circular(20),
        ),
      );
    }

    if (expression == AIRobotExpression.error) {
      return Container(
        width: 35,
        height: 12,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: color, width: 4)),
        ),
      );
    }

    return Container(
      width: 30,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
