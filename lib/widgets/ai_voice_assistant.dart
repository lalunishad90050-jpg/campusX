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
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AIRobotExpression _expression = AIRobotExpression.idle;

  bool _speechReady = false;
  bool _listening = false;
  bool _thinking = false;

  String _lastQuestion = '';
  String _lastReply = '';

  static const String _backendUrl =
      'https://campusx-backend-43jp.onrender.com/assistant/chat';

  @override
  void initState() {
    super.initState();
    _setupVoice();
  }

  Future<void> _setupVoice() async {
    try {
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.05);
      await _tts.awaitSpeakCompletion(true);

      _speechReady = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;

          if (status == 'done' || status == 'notListening') {
            setState(() {
              _listening = false;
            });
          }
        },
        onError: (_) {
          if (!mounted) return;

          setState(() {
            _listening = false;
            _expression = AIRobotExpression.error;
          });
        },
      );

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      _speechReady = false;
    }
  }

  Future<void> _toggleListening() async {
    if (_thinking) return;

    if (!_speechReady) {
      await _setupVoice();
    }

    if (!_speechReady) {
      _showMessage('Microphone available nahi hai.');
      return;
    }

    if (_listening) {
      await _speech.stop();

      if (mounted) {
        setState(() {
          _listening = false;
          _expression = AIRobotExpression.thinking;
        });
      }

      final question = _lastQuestion.trim();

      if (question.isNotEmpty) {
        await _askAI(question);
      }

      return;
    }

    _lastQuestion = '';

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;

          setState(() {
            _lastQuestion = result.recognizedWords;
          });

          if (result.finalResult) {
            _listening = false;

            final question = _lastQuestion.trim();

            if (question.isNotEmpty) {
              _askAI(question);
            }
          }
        },
      );

      if (mounted) {
        setState(() {
          _listening = true;
          _expression = AIRobotExpression.thinking;
        });
      }
    } catch (_) {
      _showMessage('Voice input start nahi ho paya.');
    }
  }

  Future<void> _askAI(String question) async {
    if (question.isEmpty || _thinking) return;

    if (mounted) {
      setState(() {
        _thinking = true;
        _expression = AIRobotExpression.thinking;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        await _speakReply('Please login to continue.', 'en-IN');
        return;
      }

      final userSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userSnapshot.data() ?? {};
      final role = (userData['role'] ?? 'student').toString();

      final contextData = await _buildContext(uid: user.uid, role: role);

      final response = await http
          .post(
            Uri.parse(_backendUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'role': role,
              'question': question,
              'context': contextData,
            }),
          )
          .timeout(const Duration(seconds: 40));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('AI server error');
      }

      final decoded = jsonDecode(response.body);

      final reply = (decoded['reply'] ?? '').toString();
      final language = (decoded['language'] ?? 'en').toString();

      if (reply.isEmpty) {
        throw Exception('Empty AI reply');
      }

      if (mounted) {
        setState(() {
          _lastReply = reply;
        });
      }

      await _speakReply(reply, language == 'hi' ? 'hi-IN' : 'en-IN');
    } catch (_) {
      await _speakReply(
        'Sorry, I could not connect to CampusX AI right now.',
        'en-IN',
      );
    } finally {
      if (mounted) {
        setState(() {
          _thinking = false;
          _expression = AIRobotExpression.idle;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _buildContext({
    required String uid,
    required String role,
  }) async {
    final result = <String, dynamic>{'role': role};

    if (role == 'student') {
      final attendance = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: uid)
          .get();

      int present = 0;
      int absent = 0;

      for (final doc in attendance.docs) {
        final status = doc.data()['status'];

        if (status == 'present') {
          present++;
        } else if (status == 'absent') {
          absent++;
        }
      }

      final total = present + absent;

      result['attendance'] = {
        'present': present,
        'absent': absent,
        'total': total,
        'percentage': total == 0 ? 0 : (present / total) * 100,
      };
    }

    if (role == 'teacher') {
      final attendance = await _firestore.collection('attendance').get();

      int present = 0;
      int absent = 0;

      for (final doc in attendance.docs) {
        final status = doc.data()['status'];

        if (status == 'present') {
          present++;
        } else if (status == 'absent') {
          absent++;
        }
      }

      result['attendance'] = {
        'presentRecords': present,
        'absentRecords': absent,
      };
    }

    if (role == 'admin') {
      final reports = await _firestore.collection('safety_reports').get();

      int open = 0;
      int resolved = 0;

      for (final doc in reports.docs) {
        final status = doc.data()['status'];

        if (status == 'resolved') {
          resolved++;
        } else {
          open++;
        }
      }

      result['safety'] = {
        'totalReports': reports.docs.length,
        'openReports': open,
        'resolvedReports': resolved,
      };
    }

    return result;
  }

  Future<void> _speakReply(String text, String language) async {
    if (!mounted) return;

    setState(() {
      _expression = AIRobotExpression.speaking;
    });

    try {
      await _tts.stop();
      await _tts.setLanguage(language);
      await _tts.speak(text);
    } catch (_) {}
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_lastQuestion.isNotEmpty || _lastReply.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxWidth: 270),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFF11172A).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 22,
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              ],
            ),
            child: Text(
              _lastReply.isNotEmpty ? _lastReply : _lastQuestion,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        GestureDetector(
          onTap: _toggleListening,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: AIRobot(expression: _expression, size: 86),
              ),
              if (_listening)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF070B1A),
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _listening
              ? 'Listening...'
              : _thinking
              ? 'Thinking...'
              : 'Ask CampusX',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
