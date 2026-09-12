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

  @override
  void initState() {
    super.initState();

    _setupVoice();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startWelcome();
    });
  }

  Future<void> _setupVoice() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);
  }

  Future<void> _startWelcome() async {
    if (_started) return;

    _started = true;

    await _speak('Welcome to CampusX. Your smart campus assistant is ready.');

    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/auth');
  }

  Future<void> _speak(String text) async {
    if (_speaking) {
      await _tts.stop();
    }

    if (mounted) {
      setState(() {
        _speaking = true;
        _expression = AIRobotExpression.speaking;
      });
    }

    try {
      await _tts.setLanguage('en-IN');
      await _tts.speak(text);
    } catch (_) {
      // Continue even if TTS is unavailable.
    }

    if (!mounted) return;

    setState(() {
      _speaking = false;
      _expression = AIRobotExpression.happy;
    });
  }

  Future<void> _speakHindi() async {
    await _speak(
      'CampusX mein aapka swagat hai. '
      'Aapka smart campus assistant taiyaar hai.',
    );
  }

  Future<void> _speakEnglish() async {
    await _speak(
      'Welcome to CampusX. '
      'Your smart campus assistant is ready.',
    );
  }

  Future<void> _skipWelcome() async {
    await _tts.stop();

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/auth');
  }

  @override
  void dispose() {
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
            child: Padding(
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

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _speaking ? null : _speakHindi,
                        icon: const Icon(Icons.volume_up),
                        label: const Text('हिंदी'),
                      ),

                      const SizedBox(width: 12),

                      ElevatedButton.icon(
                        onPressed: _speaking ? null : _speakEnglish,
                        icon: const Icon(Icons.volume_up),
                        label: const Text('English'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  TextButton(
                    onPressed: _speaking ? null : _skipWelcome,
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
