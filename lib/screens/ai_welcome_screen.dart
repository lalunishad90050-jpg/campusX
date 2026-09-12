import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../widgets/ai_robot.dart';

class AIWelcomeScreen extends StatefulWidget {
  const AIWelcomeScreen({super.key});

  @override
  State<AIWelcomeScreen> createState() => _AIWelcomeScreenState();
}

class _AIWelcomeScreenState extends State<AIWelcomeScreen> {
  final FlutterTts _tts = FlutterTts();

  AIRobotExpression _expression = AIRobotExpression.happy;

  bool _speaking = false;
  bool _started = false;
  bool _skipped = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startWelcome();
    });
  }

  Future<void> _setupVoice() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);

    // IMPORTANT:
    // Wait for every sentence to finish before continuing.
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() {
      if (!mounted) return;

      setState(() {
        _speaking = true;
        _expression = AIRobotExpression.speaking;
      });
    });

    _tts.setCompletionHandler(() {
      if (!mounted) return;

      setState(() {
        _speaking = false;
        _expression = AIRobotExpression.happy;
      });
    });

    _tts.setCancelHandler(() {
      if (!mounted) return;

      setState(() {
        _speaking = false;
        _expression = AIRobotExpression.happy;
      });
    });

    _tts.setErrorHandler((message) {
      if (!mounted) return;

      setState(() {
        _speaking = false;
        _expression = AIRobotExpression.error;
      });
    });
  }

  Future<void> _startWelcome() async {
    if (_started || _skipped) return;

    _started = true;

    try {
      // Give Android TTS a moment after Activity startup.
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted || _skipped) return;

      // IMPORTANT: setup must finish BEFORE speaking.
      await _setupVoice();

      if (!mounted || _skipped) return;

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted || _skipped) return;

      // English
      await _speak(
        'Welcome to CampusX. '
            'Your smart campus assistant is ready.',
        'en-IN',
      );

      if (!mounted || _skipped) return;

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted || _skipped) return;

      // Hindi
      await _speak(
        'CampusX mein aapka swagat hai. '
            'Aapka smart campus assistant taiyaar hai.',
        'hi-IN',
      );

      if (!mounted || _skipped) return;

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted || _skipped) return;

      setState(() {
        _expression = AIRobotExpression.happy;
      });

      Navigator.pushReplacementNamed(context, '/auth');
    } catch (_) {
      // If TTS is unavailable, still allow the user to continue.
      if (!mounted || _skipped) return;

      setState(() {
        _speaking = false;
        _expression = AIRobotExpression.error;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted || _skipped) return;

      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  Future<void> _speak(String text, String language) async {
    if (_skipped) return;

    try {
      // Stop anything already playing.
      await _tts.stop();

      if (!mounted || _skipped) return;

      await _tts.setLanguage(language);

      if (!mounted || _skipped) return;

      setState(() {
        _speaking = true;
        _expression = AIRobotExpression.speaking;
      });

      // Because awaitSpeakCompletion(true) is enabled,
      // this waits until the complete sentence finishes.
      await _tts.speak(text);

      if (!mounted || _skipped) return;

      setState(() {
        _speaking = false;
        _expression = AIRobotExpression.happy;
      });
    } catch (_) {
      if (!mounted || _skipped) return;

      setState(() {
        _speaking = false;
        _expression = AIRobotExpression.error;
      });
    }
  }

  Future<void> _skipWelcome() async {
    _skipped = true;

    await _tts.stop();

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/auth');
  }

  @override
  void dispose() {
    _skipped = true;
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AIRobot(expression: _expression, size: 190),

                  const SizedBox(height: 24),

                  Text(
                    'CampusX',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'AI-Powered Smart Campus',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),

                  const SizedBox(height: 30),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _speaking
                        ? const Text(
                            '🤖 Speaking...',
                            key: ValueKey('speaking'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : const Text(
                            'Your campus assistant is ready',
                            key: ValueKey('ready'),
                            style: TextStyle(fontSize: 16),
                          ),
                  ),

                  const SizedBox(height: 30),

                  TextButton(
                    onPressed: _skipped ? null : _skipWelcome,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
