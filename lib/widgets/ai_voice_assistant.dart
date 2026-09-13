// ignore_for_file: deprecated_member_use

import 'dart:async';
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

  static const String _healthUrl =
      'https://campusx-backend-43jp.onrender.com/health';

  AIRobotExpression _expression = AIRobotExpression.idle;

  bool _speechReady = false;
  bool _voiceInitializing = false;
  bool _listening = false;
  bool _thinking = false;
  bool _conversationMode = false;
  bool _processingQuestion = false;

  int _voiceSession = 0;
  int _handledResultSession = -1;

  String _currentQuestion = '';
  String _lastReply = '';

  Map<String, dynamic>? _cachedUserData;
  String? _cachedRole;

  @override
  void initState() {
    super.initState();

    unawaited(_setupVoice());
    unawaited(_warmUpBackend());
  }

  @override
  void dispose() {
    _voiceSession++;
    _conversationMode = false;

    unawaited(_speech.stop());
    unawaited(_tts.stop());

    super.dispose();
  }

  Future<void> _warmUpBackend() async {
    try {
      await http.get(Uri.parse(_healthUrl)).timeout(const Duration(seconds: 6));
    } catch (_) {}
  }

  Future<void> _setupVoice() async {
    if (_voiceInitializing || _speechReady) {
      return;
    }

    _voiceInitializing = true;

    try {
      await _tts.setSpeechRate(0.58);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.05);
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('hi-IN');

      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;

          if (status == 'done' || status == 'notListening') {
            if (_listening &&
                _currentQuestion.trim().isNotEmpty &&
                _conversationMode) {
              unawaited(
                _finishListening(_voiceSession, _currentQuestion.trim()),
              );
            }
          }
        },
        onError: (error) {
          if (!mounted) return;

          final message = error.errorMsg.toLowerCase();

          setState(() {
            _listening = false;
          });

          // "no_match" normal situation hai, isko hard error mat dikhao.
          if (message.contains('no_match') ||
              message.contains('no match') ||
              message.contains('timeout')) {
            if (_conversationMode) {
              setState(() {
                _expression = AIRobotExpression.idle;
              });

              unawaited(_restartListeningAfterError());
            }
            return;
          }

          setState(() {
            _expression = AIRobotExpression.error;
          });

          if (_conversationMode) {
            _showMessage(
              'Mic start nahi ho paya. Microphone permission check karo.',
            );
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
    _handledResultSession = -1;

    await _tts.stop();
    await _speech.stop();

    if (!_speechReady) {
      await _setupVoice();
    }

    if (!mounted || session != _voiceSession) {
      return;
    }

    if (!_speechReady) {
      _showMessage('Microphone available nahi hai. Permission check karo.');
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
    if (!mounted ||
        session != _voiceSession ||
        !_conversationMode ||
        _thinking ||
        _processingQuestion) {
      return;
    }

    if (_listening) {
      return;
    }

    if (!_speechReady) {
      await _setupVoice();
      if (!_speechReady) return;
    }

    _handledResultSession = -1;

    setState(() {
      _listening = true;
      _currentQuestion = '';
      _expression = AIRobotExpression.thinking;
    });

    try {
      await _speech.listen(
        // System/Android ki available language use hogi.
        // Hard-coded en_IN hata diya hai taaki Hindi voice input fail na ho.
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(milliseconds: 800),
        partialResults: true,
        cancelOnError: false,
        onResult: (result) {
          if (!mounted || session != _voiceSession) {
            return;
          }

          final words = result.recognizedWords.trim();

          if (words.isEmpty) {
            return;
          }

          setState(() {
            _currentQuestion = words;
          });

          if (result.finalResult) {
            unawaited(_finishListening(session, words));
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

      _showMessage('Microphone start nahi ho paya. Permission check karo.');
    }
  }

  Future<void> _finishListening(int session, String question) async {
    if (!mounted ||
        session != _voiceSession ||
        !_conversationMode ||
        _processingQuestion) {
      return;
    }

    if (_handledResultSession == session) {
      return;
    }

    final cleanQuestion = question.trim();

    if (cleanQuestion.isEmpty) {
      return;
    }

    _handledResultSession = session;

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

  Future<void> _restartListeningAfterError() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (!mounted || !_conversationMode || _thinking) {
      return;
    }

    final session = _voiceSession;

    await _startListening(session);
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
    if (!mounted || session != _voiceSession || !_conversationMode) {
      return;
    }

    final cleanQuestion = question.trim();

    if (cleanQuestion.isEmpty) {
      _resetAfterQuestion();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _processingQuestion = false;
        _thinking = false;
      });

      await _speak('Pehle login kijiye.', language: 'hi-IN');

      return;
    }

    try {
      // User profile sirf FIRST question par Firebase se load hoga.
      // Har question par dobara read nahi hoga.
      Map<String, dynamic> userData;

      if (_cachedUserData != null && _cachedRole != null) {
        userData = _cachedUserData!;
      } else {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (!mounted || session != _voiceSession) {
          return;
        }

        userData = userDoc.data() ?? {};

        final role = (userData['role'] ?? 'student')
            .toString()
            .trim()
            .toLowerCase();

        _cachedUserData = userData;
        _cachedRole = role;
      }

      final role = _cachedRole ?? 'student';

      Map<String, dynamic> context = {
        'name': userData['name'] ?? '',
        'email': userData['email'] ?? '',
        'role': role,
      };

      // Sirf CampusX data wala question ho to Firebase query.
      if (_questionNeedsCampusData(cleanQuestion, role)) {
        context = await _buildContext(
          uid: user.uid,
          role: role,
          userData: userData,
          question: cleanQuestion,
        );
      }

      if (!mounted || session != _voiceSession) {
        return;
      }

      // AI ko explicitly Hindi answer instruction.
      final aiQuestion =
          '''
Is question ka jawab ONLY simple Hindi/Hinglish mein do.
English mein answer mat do.
Answer short, clear aur useful rakho.
Agar question general knowledge ka hai to available knowledge ke basis par answer do.
Agar CampusX data context diya gaya hai to uska use karo.
Question:
$cleanQuestion
''';

      final response = await http
          .post(
            Uri.parse(_backendUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'role': role,
              'question': aiQuestion,
              'context': context,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (!mounted || session != _voiceSession) {
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('AI server returned ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);

      final reply = (decoded['reply'] ?? '').toString().trim();

      if (reply.isEmpty) {
        throw Exception('Empty AI response');
      }

      if (!mounted || session != _voiceSession) {
        return;
      }

      setState(() {
        _lastReply = reply;
        _thinking = false;
        _processingQuestion = true;
        _expression = AIRobotExpression.speaking;
      });

      // Reply milte hi immediately Hindi TTS.
      await _speak(reply, language: 'hi-IN');

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

      await Future<void>.delayed(const Duration(milliseconds: 80));

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
        'Maaf kijiye, abhi jawab nahi mil paya. Dobara poochiye.',
        language: 'hi-IN',
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

      await Future<void>.delayed(const Duration(milliseconds: 100));

      if (!mounted || session != _voiceSession) {
        return;
      }

      if (_conversationMode) {
        await _startListening(session);
      }
    }
  }

  bool _questionNeedsCampusData(String question, String role) {
    final q = question.toLowerCase();

    const campusKeywords = [
      'attendance',
      'present',
      'absent',
      'student',
      'students',
      'safety',
      'report',
      'reports',
      'campus',
      'dark area',
      'dark areas',
      'broken light',
      'broken lights',
      'resolved',
      'reviewing',
      'college',
      'meri',
      'mere',
      'kitni',
      'kitne',
      'aaj',
      'today',
    ];

    return campusKeywords.any(q.contains);
  }

  Future<Map<String, dynamic>> _buildContext({
    required String uid,
    required String role,
    required Map<String, dynamic> userData,
    required String question,
  }) async {
    final context = <String, dynamic>{
      'name': userData['name'] ?? '',
      'email': userData['email'] ?? '',
      'role': role,
    };

    final q = question.toLowerCase();

    // STUDENT ATTENDANCE
    if (role == 'student' &&
        (q.contains('attendance') ||
            q.contains('present') ||
            q.contains('absent') ||
            q.contains('meri') ||
            q.contains('aaj'))) {
      final snapshot = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: uid)
          .get();

      int present = 0;
      int absent = 0;

      for (final doc in snapshot.docs) {
        final status = doc.data()['status'];

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

    // TEACHER ATTENDANCE
    if (role == 'teacher' &&
        (q.contains('attendance') ||
            q.contains('present') ||
            q.contains('absent') ||
            q.contains('student') ||
            q.contains('students'))) {
      final snapshot = await _firestore.collection('attendance').get();

      int present = 0;
      int absent = 0;

      for (final doc in snapshot.docs) {
        final status = doc.data()['status'];

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

    // ADMIN SAFETY
    if (role == 'admin' &&
        (q.contains('safety') ||
            q.contains('report') ||
            q.contains('reports') ||
            q.contains('campus') ||
            q.contains('dark') ||
            q.contains('light'))) {
      final snapshot = await _firestore.collection('safety_reports').get();

      int open = 0;
      int resolved = 0;

      for (final doc in snapshot.docs) {
        final status = (doc.data()['status'] ?? 'new').toString().toLowerCase();

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

  Future<void> _speak(String text, {required String language}) async {
    try {
      await _tts.stop();

      await _tts.setLanguage(language);
      await _tts.setSpeechRate(0.58);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.05);

      if (!mounted) return;

      setState(() {
        _expression = AIRobotExpression.speaking;
      });

      await _tts.speak(text);
    } catch (_) {}
  }

  void _resetAfterQuestion() {
    if (!mounted) return;

    setState(() {
      _processingQuestion = false;
      _thinking = false;
      _listening = false;
      _expression = AIRobotExpression.idle;
    });
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
    final screenWidth = MediaQuery.of(context).size.width;

    // Assistant ko screen ke andar safe rakho.
    final assistantWidth = screenWidth < 360 ? screenWidth - 20 : 350.0;

    final showBubble = _lastReply.isNotEmpty || _currentQuestion.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: SizedBox(
          width: assistantWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (showBubble)
                Container(
                  width: assistantWidth,
                  constraints: const BoxConstraints(maxHeight: 145),
                  margin: const EdgeInsets.only(bottom: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.97),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 16,
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
                            'Aap',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentQuestion,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (_lastReply.isNotEmpty &&
                            _currentQuestion.isNotEmpty)
                          const SizedBox(height: 6),
                        if (_lastReply.isNotEmpty) ...[
                          Text(
                            'CampusX AI',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
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

              // Compact robot + mic.
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 58,
                    height: 62,
                    child: ClipRect(
                      child: AIRobot(expression: _expression, size: 54),
                    ),
                  ),

                  const SizedBox(width: 5),

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
                      duration: const Duration(milliseconds: 180),
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _conversationMode
                            ? Colors.redAccent
                            : theme.colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: _conversationMode ? 18 : 10,
                            spreadRadius: 2,
                            color:
                                (_conversationMode
                                        ? Colors.redAccent
                                        : theme.colorScheme.primary)
                                    .withValues(alpha: 0.30),
                          ),
                        ],
                      ),
                      child: Icon(
                        _conversationMode
                            ? Icons.stop_rounded
                            : Icons.mic_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 2),

              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Text(
                  _conversationMode
                      ? (_listening
                            ? 'Sun raha hoon...'
                            : _thinking
                            ? 'Soch raha hoon...'
                            : 'CampusX AI bol raha hai...')
                      : 'CampusX AI se poochho',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
