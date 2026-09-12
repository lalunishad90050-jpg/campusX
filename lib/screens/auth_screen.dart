import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../widgets/ai_robot.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterTts _tts = FlutterTts();

  final _nameController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _collegeIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  AIRobotExpression _robotExpression = AIRobotExpression.happy;

  @override
  void initState() {
    super.initState();

    _setupTts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _speakLoginMessage();
    });
  }

  Future<void> _setupTts() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);
  }

  Future<void> _speakLoginMessage() async {
    try {
      await _tts.setLanguage('en-IN');

      await _tts.speak(
        _isLogin
            ? 'Welcome to CampusX. Please login to continue.'
            : 'Welcome to CampusX. Create your student account.',
      );
    } catch (_) {
      // Voice failure should not stop authentication.
    }
  }

  Future<void> _speak(String text) async {
    try {
      if (mounted) {
        setState(() {
          _robotExpression = AIRobotExpression.speaking;
        });
      }

      await _tts.setLanguage('en-IN');
      await _tts.speak(text);

      if (!mounted) return;

      setState(() {
        _robotExpression = AIRobotExpression.happy;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _robotExpression = AIRobotExpression.idle;
      });
    }
  }

  @override
  void dispose() {
    _tts.stop();

    _nameController.dispose();
    _rollNumberController.dispose();
    _collegeIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final rollNumber = _rollNumberController.text.trim();
    final collegeId = _collegeIdController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!_isLogin && name.isEmpty) {
      _showMessage('Please enter your name.', isError: true);
      return;
    }

    if (!_isLogin && rollNumber.isEmpty) {
      _showMessage('Please enter your roll number.', isError: true);
      return;
    }

    if (collegeId.isEmpty) {
      _showMessage('Please enter your college ID.', isError: true);
      return;
    }

    if (email.isEmpty) {
      _showMessage('Please enter your email.', isError: true);
      return;
    }

    if (password.isEmpty) {
      _showMessage('Please enter your password.', isError: true);
      return;
    }

    if (!_isLogin && _confirmPasswordController.text != password) {
      _showMessage('Passwords do not match.', isError: true);
      return;
    }

    if (!mounted) return;

    setState(() {
      _loading = true;
      _robotExpression = AIRobotExpression.thinking;
    });

    try {
      if (_isLogin) {
        await _login(
          email: email,
          password: password,
          collegeId: collegeId,
          rollNumber: rollNumber,
        );
      } else {
        await _register(
          name: name,
          rollNumber: rollNumber,
          collegeId: collegeId,
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email.';
          break;

        case 'weak-password':
          message = 'Password is too weak.';
          break;

        case 'user-not-found':
          message = 'No account found with this email.';
          break;

        case 'wrong-password':
        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;

        case 'too-many-requests':
          message = 'Too many attempts. Try again later.';
          break;

        default:
          message = e.message ?? 'Authentication failed.';
      }

      setState(() {
        _robotExpression = AIRobotExpression.error;
      });

      _showMessage(message, isError: true);

      await _speak(message);
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      setState(() {
        _robotExpression = AIRobotExpression.error;
      });

      _showMessage(message, isError: true);

      await _speak(message);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _register({
    required String name,
    required String rollNumber,
    required String collegeId,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Unable to create account.');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'name': name,
      'rollNumber': rollNumber,
      'collegeId': collegeId,
      'email': email,
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _speak('Registration successful. Welcome to CampusX.');

    if (!mounted) return;

    _showMessage('Registration successful!', isError: false);

    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Future<void> _login({
    required String email,
    required String password,
    required String collegeId,
    required String rollNumber,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Unable to login.');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      await _auth.signOut();

      throw Exception('User profile not found. Please contact admin.');
    }

    final data = userDoc.data() ?? {};

    final savedCollegeId = (data['collegeId'] ?? '').toString().trim();

    final savedRollNumber = (data['rollNumber'] ?? '').toString().trim();

    final role = (data['role'] ?? 'student').toString().toLowerCase();

    if (savedCollegeId != collegeId) {
      await _auth.signOut();

      throw Exception('College ID does not match.');
    }

    if (role == 'student') {
      if (rollNumber.isEmpty) {
        await _auth.signOut();

        throw Exception('Roll number is required for student login.');
      }

      if (savedRollNumber != rollNumber) {
        await _auth.signOut();

        throw Exception('Roll number does not match.');
      }
    }

    await _speak(
      role == 'admin'
          ? 'Welcome admin.'
          : role == 'teacher'
          ? 'Welcome teacher.'
          : 'Welcome back. Your CampusX dashboard is ready.',
    );

    if (!mounted) return;

    if (role == 'admin') {
      Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
    } else if (role == 'teacher') {
      Navigator.pushNamedAndRemoveUntil(context, '/teacher', (route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  void _toggleAuthMode() {
    if (_loading) return;

    setState(() {
      _isLogin = !_isLogin;
      _robotExpression = AIRobotExpression.happy;
      _rollNumberController.clear();
    });

    _speakLoginMessage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  Center(
                    child: AIRobot(expression: _robotExpression, size: 145),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'CampusX',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _isLogin
                        ? 'Your Smart Campus Assistant'
                        : 'Create your student account',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17),
                  ),

                  const SizedBox(height: 28),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isLogin ? 'Login' : 'Student Registration',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 20),

                          if (!_isLogin) ...[
                            TextField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Full Name *',
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          if (!_isLogin) ...[
                            TextField(
                              controller: _rollNumberController,
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                labelText: 'Roll Number *',
                                hintText: 'e.g. 141',
                                prefixIcon: Icon(Icons.badge),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          if (_isLogin) ...[
                            TextField(
                              controller: _rollNumberController,
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                labelText: 'Roll Number (Student only)',
                                hintText: 'Leave empty for Teacher/Admin',
                                prefixIcon: Icon(Icons.badge),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          TextField(
                            controller: _collegeIdController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'College ID *',
                              hintText: 'e.g. BIT-26/CSE/D/141',
                              prefixIcon: Icon(Icons.school),
                            ),
                          ),

                          const SizedBox(height: 14),

                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email *',
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),

                          const SizedBox(height: 14),

                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password *',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                          ),

                          if (!_isLogin) ...[
                            const SizedBox(height: 14),

                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password *',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 22),

                          ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _isLogin
                                        ? 'Login'
                                        : 'Create Student Account',
                                  ),
                          ),

                          const SizedBox(height: 12),

                          TextButton(
                            onPressed: _loading ? null : _toggleAuthMode,
                            child: Text(
                              _isLogin
                                  ? 'Create a new student account'
                                  : 'Already have an account? Login',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.smart_toy_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'CampusX AI Assistant is ready to help. '
                              'Students can register themselves. '
                              'Teacher and Admin accounts are managed separately.',
                            ),
                          ),
                        ],
                      ),
                    ),
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
