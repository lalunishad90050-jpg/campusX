// ignore_for_file: deprecated_member_use

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
  bool _voiceInitializing = false;
  bool _listening = false;
  bool _thinking = false;
  bool _conversationMode = false;
  bool _processingQuestion = false;

  int _voiceSession = 0;

  String _currentQuestion = '';
  String _lastReply = '';

  @override
  void initState() {
    super.initState();
    _setupVoice();
  }

  @override
  void dispose() {
    _voiceSession++;
    _conversationMode = false;

    _speech.stop();
    _tts.stop();

    super.dispose();
  }

  Future<void> _setupVoice() async {
    if (_voiceInitializing || _speechReady) {
      return;
    }

    _voiceInitializing = true;

    try {
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
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _speechReady = false;
        _expression = AIRobotExpression.error;
      });
    } finally {
      _voiceInitializing = false;
    }
  }

  Future<void> _startConversation() async {
    final session = ++_voiceSession;

    await _tts.stop();
    await _speech.stop();

    if (!_speechReady) {
      await _setupVoice();
    }

    if (!mounted || session != _voiceSession) {
      return;
    }

    if (!_speechReady) {
      _showMessage(
        'Voice input is not available. Please check microphone permission.',
      );
      return;
    }

    setState(() {
      _conversationMode = true;
      _listening = false;
      _thinking = false;
      _processingQuestion = false;
      _currentQuestion = '';
      _lastReply = '';
      _expression = AIRobotExpression.idle;
    });

    await _startListening(session);
  }

  Future<void> _startListening(int session) async {
    if (!mounted) return;

    if (session != _voiceSession) {
      return;
    }

    if (!_conversationMode || _listening || _thinking || _processingQuestion) {
      return;
    }

    if (!_speechReady) {
      return;
    }

    setState(() {
      _listening = true;
      _currentQuestion = '';
      _expression = AIRobotExpression.thinking;
    });

    try {
      await _speech.listen(
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        onResult: (result) {
          if (!mounted) return;

          if (session != _voiceSession) {
            return;
          }

          final words = result.recognizedWords.trim();

          setState(() {
            _currentQuestion = words;
          });

          if (result.finalResult && words.isNotEmpty) {
            _finishListening(session, words);
          }
        },
      );
    } catch (_) {
      if (!mounted || session != _voiceSession) {
        return;
      }

      setState(() {
        _listening = false;
        _expression = AIRobotExpression.error;
      });

      _showMessage('Could not start microphone.');
    }
  }

  Future<void> _finishListening(int session, String question) async {
    if (!mounted) return;

    if (session != _voiceSession) {
      return;
    }

    if (!_conversationMode) {
      return;
    }

    if (_processingQuestion) {
      return;
    }

    final cleanQuestion = question.trim();

    if (cleanQuestion.isEmpty) {
      return;
    }

    setState(() {
      _listening = false;
      _processingQuestion = true;
      _thinking = true;
      _expression = AIRobotExpression.thinking;
      _currentQuestion = cleanQuestion;
    });

    await _speech.stop();

    if (!mounted || session != _voiceSession) {
      return;
    }

    await _askAI(cleanQuestion, session);
  }

  Future<void> _stopConversation() async {
    ++_voiceSession;

    _conversationMode = false;

    await _speech.stop();
    await _tts.stop();

    if (!mounted) return;

    setState(() {
      _listening = false;
      _thinking = false;
      _processingQuestion = false;
      _currentQuestion = '';
      _expression = AIRobotExpression.idle;
    });
  }

  Future<void> _askAI(String question, int session) async {
    if (!mounted) return;

    if (session != _voiceSession) {
      return;
    }

    if (!_conversationMode) {
      return;
    }

    final cleanQuestion = question.trim();

    if (cleanQuestion.isEmpty) {
      if (mounted) {
        setState(() {
          _processingQuestion = false;
          _thinking = false;
          _expression = AIRobotExpression.idle;
        });
      }

      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _processingQuestion = false;
          _thinking = false;
        });
      }

      await _speak('Please login first.', language: 'en-IN');

      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!mounted || session != _voiceSession) {
        return;
      }

      final userData = userDoc.data() ?? {};

      final role = (userData['role'] ?? 'student').toString().toLowerCase();

      final context = await _buildContext(
        uid: user.uid,
        role: role,
        userData: userData,
      );

      if (!mounted || session != _voiceSession) {
        return;
      }

      final response = await http
          .post(
            Uri.parse(_backendUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'role': role,
              'question': cleanQuestion,
              'context': context,
            }),
          )
          .timeout(const Duration(seconds: 40));

      if (!mounted || session != _voiceSession) {
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('AI server returned ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);

      final reply = (decoded['reply'] ?? '').toString().trim();

      final language = (decoded['language'] ?? 'en').toString().toLowerCase();

      if (reply.isEmpty) {
        throw Exception('Empty AI response');
      }

      if (!mounted || session != _voiceSession) {
        return;
      }

      setState(() {
        _lastReply = reply;
        _thinking = false;
        _expression = AIRobotExpression.speaking;
      });

      await _speak(reply, language: language == 'hi' ? 'hi-IN' : 'en-IN');

      if (!mounted || session != _voiceSession) {
        return;
      }

      if (!_conversationMode) {
        return;
      }

      setState(() {
        _processingQuestion = false;
        _thinking = false;
        _listening = false;
        _currentQuestion = '';
        _expression = AIRobotExpression.idle;
      });

      await Future<void>.delayed(const Duration(milliseconds: 250));

      if (!mounted || session != _voiceSession) {
        return;
      }

      if (_conversationMode) {
        await _startListening(session);
      }
    } catch (_) {
      if (!mounted || session != _voiceSession) {
        return;
      }

      setState(() {
        _processingQuestion = false;
        _thinking = false;
        _listening = false;
        _expression = AIRobotExpression.error;
      });

      await _speak(
        'Sorry, I could not process that right now.',
        language: 'en-IN',
      );

      if (!mounted || session != _voiceSession) {
        return;
      }

      if (!_conversationMode) {
        return;
      }

      setState(() {
        _expression = AIRobotExpression.idle;
        _currentQuestion = '';
      });

      await Future<void>.delayed(const Duration(milliseconds: 350));

      if (!mounted || session != _voiceSession) {
        return;
      }

      if (_conversationMode) {
        await _startListening(session);
      }
    }
  }

  Future<void> _speak(String text, {required String language}) async {
    try {
      await _tts.stop();
      await _tts.setLanguage(language);

      if (!mounted) return;

      setState(() {
        _expression = AIRobotExpression.speaking;
      });

      await _tts.speak(text);
    } catch (_) {
      // TTS failure should not break the conversation.
    }
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

    final showBubble = _lastReply.isNotEmpty || _currentQuestion.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 16,
          maxHeight: MediaQuery.of(context).size.height - 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showBubble)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 24,
                  maxHeight: 150,
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
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
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                          const SizedBox(height: 3),
                          Text(
                            _currentQuestion,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (_lastReply.isNotEmpty &&
                            _currentQuestion.isNotEmpty)
                          const SizedBox(height: 8),
                        if (_lastReply.isNotEmpty) ...[
                          Text(
                            'CampusX AI',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _lastReply,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Smaller robot keeps the complete assistant
                // safely inside narrow screens.
                AIRobot(expression: _expression, size: 72),

                const SizedBox(width: 6),

                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    if (_conversationMode) {
                      await _stopConversation();
                    } else {
                      await _startConversation();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _conversationMode
                          ? Colors.redAccent
                          : theme.colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: _conversationMode ? 20 : 12,
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
                      _conversationMode
                          ? Icons.stop_rounded
                          : Icons.mic_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 3),

            Text(
              _conversationMode
                  ? (_listening
                        ? 'Listening...'
                        : _thinking
                        ? 'Thinking...'
                        : 'Talking with CampusX')
                  : 'Ask CampusX',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
