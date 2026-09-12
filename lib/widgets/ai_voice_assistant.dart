import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'ai_robot.dart';

class AIVoiceAssistant extends StatefulWidget {
  const AIVoiceAssistant({super.key});

  @override
  State<AIVoiceAssistant> createState() => _AIVoiceAssistantState();
}

class _AIVoiceAssistantState extends State<AIVoiceAssistant> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _backendUrl =
      'https://campusx-backend-43jp.onrender.com/assistant/chat';

  AIRobotExpression _expression = AIRobotExpression.idle;

  bool _speechReady = false;
  bool _listening = false;
  bool _thinking = false;
  bool _conversationMode = false;

  String _currentQuestion = '';
  String _lastReply = '';

  @override
  void initState() {
    super.initState();
    _setupVoice();
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _setupVoice() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);
    await _tts.awaitSpeakCompletion(true);

    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;

        if (status == 'done' || status == 'notListening') {
          setState(() {
            _listening = false;
          });

          if (_conversationMode &&
              !_thinking &&
              _currentQuestion.trim().isNotEmpty) {
            _askAI(_currentQuestion.trim());
          }
        }
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          _listening = false;
          _expression = AIRobotExpression.error;
        });

        if (_conversationMode) {
          _showMessage('Voice input error. Please try again.');
        }
      },
    );

    if (!mounted) return;

    setState(() {
      _speechReady = available;
    });
  }

  Future<void> _startConversation() async {
    if (!_speechReady) {
      await _setupVoice();
    }

    if (!_speechReady || !mounted) {
      _showMessage('Voice input is not available.');
      return;
    }

    setState(() {
      _conversationMode = true;
      _currentQuestion = '';
      _expression = AIRobotExpression.idle;
    });

    await _startListening();
  }

  Future<void> _startListening() async {
    if (!_speechReady || _listening || _thinking || !_conversationMode) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _listening = true;
      _currentQuestion = '';
      _expression = AIRobotExpression.thinking;
    });

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          _currentQuestion = result.recognizedWords;
        });

        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _speech.stop();
        }
      },
    );
  }

  Future<void> _stopConversation() async {
    _conversationMode = false;

    await _speech.stop();
    await _tts.stop();

    if (!mounted) return;

    setState(() {
      _listening = false;
      _thinking = false;
      _currentQuestion = '';
      _expression = AIRobotExpression.idle;
    });
  }

  Future<void> _askAI(String question) async {
    if (!_conversationMode || question.trim().isEmpty) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      await _speak('Please login first.', language: 'en-IN');
      return;
    }

    if (!mounted) return;

    setState(() {
      _thinking = true;
      _listening = false;
      _expression = AIRobotExpression.thinking;
    });

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      final userData = userDoc.data() ?? {};
      final role = (userData['role'] ?? 'student').toString().toLowerCase();

      final context = await _buildContext(
        uid: user.uid,
        role: role,
        userData: userData,
      );

      final response = await http
          .post(
            Uri.parse(_backendUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'role': role,
              'question': question,
              'context': context,
            }),
          )
          .timeout(const Duration(seconds: 40));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('AI server returned ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);

      final reply = (decoded['reply'] ?? '').toString().trim();

      final language = (decoded['language'] ?? 'en').toString().toLowerCase();

      if (reply.isEmpty) {
        throw Exception('Empty AI response');
      }

      if (!mounted) return;

      setState(() {
        _lastReply = reply;
        _thinking = false;
        _expression = AIRobotExpression.speaking;
      });

      await _speak(reply, language: language == 'hi' ? 'hi-IN' : 'en-IN');

      if (!mounted || !_conversationMode) return;

      setState(() {
        _expression = AIRobotExpression.idle;
        _currentQuestion = '';
      });

      // Automatically listen for the next question.
      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (mounted && _conversationMode) {
        await _startListening();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _thinking = false;
        _expression = AIRobotExpression.error;
      });

      await _speak(
        'Sorry, I could not process that right now.',
        language: 'en-IN',
      );

      if (!mounted || !_conversationMode) return;

      setState(() {
        _expression = AIRobotExpression.idle;
        _currentQuestion = '';
      });

      await Future<void>.delayed(const Duration(milliseconds: 700));

      if (mounted && _conversationMode) {
        await _startListening();
      }
    }
  }

  Future<void> _speak(String text, {required String language}) async {
    await _tts.setLanguage(language);
    await _tts.speak(text);
  }

  Future<Map<String, dynamic>> _buildContext({
    required String uid,
    required String role,
    required Map<String, dynamic> userData,
  }) async {
    final context = <String, dynamic>{
      'name': userData['name'] ?? '',
      'email': userData['email'] ?? '',
      'role': role,
    };

    if (role == 'student') {
      final snapshot = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: uid)
          .get();

      int present = 0;
      int absent = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'];

        if (status == 'present') {
          present++;
        } else if (status == 'absent') {
          absent++;
        }
      }

      final total = present + absent;

      context['attendance'] = {
        'present': present,
        'absent': absent,
        'total': total,
        'percentage': total == 0 ? 0 : (present / total) * 100,
      };
    }

    if (role == 'teacher') {
      final snapshot = await _firestore.collection('attendance').get();

      int present = 0;
      int absent = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'];

        if (status == 'present') {
          present++;
        } else if (status == 'absent') {
          absent++;
        }
      }

      context['attendance'] = {
        'presentRecords': present,
        'absentRecords': absent,
        'totalRecords': present + absent,
      };
    }

    if (role == 'admin') {
      final snapshot = await _firestore.collection('safety_reports').get();

      int open = 0;
      int resolved = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? 'new').toString().toLowerCase();

        if (status == 'resolved') {
          resolved++;
        } else {
          open++;
        }
      }

      context['safetyReports'] = {
        'total': snapshot.docs.length,
        'open': open,
        'resolved': resolved,
      };
    }

    return context;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_lastReply.isNotEmpty || _currentQuestion.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxWidth: 280),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    spreadRadius: 1,
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentQuestion.isNotEmpty) ...[
                    Text(
                      'You',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_currentQuestion),
                  ],
                  if (_lastReply.isNotEmpty && _currentQuestion.isNotEmpty)
                    const SizedBox(height: 10),
                  if (_lastReply.isNotEmpty) ...[
                    Text(
                      'CampusX AI',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _lastReply,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AIRobot(expression: _expression, size: 82),
              const SizedBox(width: 8),

              GestureDetector(
                onTap: () async {
                  if (_conversationMode) {
                    await _stopConversation();
                  } else {
                    await _startConversation();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _conversationMode
                        ? Colors.redAccent
                        : theme.colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: _conversationMode ? 22 : 14,
                        spreadRadius: 2,
                        color:
                            (_conversationMode
                                    ? Colors.redAccent
                                    : theme.colorScheme.primary)
                                .withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                  child: Icon(
                    _conversationMode ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Text(
            _conversationMode
                ? (_listening
                      ? 'Listening...'
                      : _thinking
                      ? 'Thinking...'
                      : 'Talking with CampusX')
                : 'Ask CampusX',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
