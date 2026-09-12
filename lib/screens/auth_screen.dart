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

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _collegeIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _loginPromptStarted = false;

  AIRobotExpression _robotExpression = AIRobotExpression.idle;

  @override
  void initState() {
    super.initState();
    _setupTts();
  }

  Future<void> _setupTts() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);

    await _tts.awaitSpeakCompletion(true);

    await _speakLoginMessage();
  }

  Future<void> _speakLoginMessage() async {
    if (!_isLogin || _loginPromptStarted) return;

    _loginPromptStarted = true;

    if (!mounted) return;

    setState(() {
      _robotExpression = AIRobotExpression.speaking;
    });

    for (int i = 0; i < 10; i++) {
      if (!_isLogin || !mounted) break;

      await _speak('Welcome to CampusX. Please login to continue.', 'en-IN');

      if (!_isLogin || !mounted) break;

      await Future.delayed(const Duration(milliseconds: 300));

      await _speak(
        'CampusX mein aapka swagat hai. Kripya login kijiye.',
        'hi-IN',
      );

      if (!_isLogin || !mounted) break;

      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (mounted) {
      setState(() {
        _robotExpression = AIRobotExpression.idle;
      });
    }
  }

  Future<void> _speak(String text, String language) async {
    try {
      await _tts.setLanguage(language);

      if (mounted) {
        setState(() {
          _robotExpression = AIRobotExpression.speaking;
        });
      }

      await _tts.speak(text);
    } catch (_) {
      // If the selected voice is unavailable, continue silently.
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    await _tts.stop();

    if (mounted) {
      setState(() {
        _robotExpression = AIRobotExpression.thinking;
        _loading = true;
      });
    }

    try {
      if (_isLogin) {
        await _login();
      } else {
        await _register();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _robotExpression = AIRobotExpression.error;
      });

      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;

        case 'wrong-password':
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;

        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;

        case 'weak-password':
          message = 'Password is too weak.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        default:
          message = e.message ?? 'Authentication failed.';
      }

      _showMessage(message);
      await _speak(message, 'en-IN');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _robotExpression = AIRobotExpression.error;
      });

      _showMessage('Something went wrong. Please try again.');
      await _speak('Something went wrong. Please try again.', 'en-IN');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _robotExpression = AIRobotExpression.idle;
        });
      }
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'invalid-user',
        message: 'Unable to login.',
      );
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      _showMessage('User profile not found.');
      return;
    }

    final data = userDoc.data() ?? {};
    final role = data['role'] ?? 'student';

    if (!mounted) return;

    if (role == 'admin') {
      await _speak('Welcome Admin. Opening your dashboard.', 'en-IN');

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/admin');
    } else if (role == 'teacher') {
      await _speak('Welcome Teacher. Opening your dashboard.', 'en-IN');

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/teacher');
    } else {
      await _speak('Welcome Student. Opening CampusX.', 'en-IN');

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final rollNumber = _rollController.text.trim();
    final collegeId = _collegeIdController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Unable to create account.',
      );
    }

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'rollNumber': rollNumber,
      'collegeId': collegeId,
      'email': email,
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    _showMessage('Account created successfully!');

    await _speak(
      'Your CampusX account has been created successfully.',
      'en-IN',
    );

    if (!mounted) return;

    setState(() {
      _isLogin = true;
      _loginPromptStarted = false;
    });

    _clearForm();

    await _speakLoginMessage();
  }

  void _clearForm() {
    _nameController.clear();
    _rollController.clear();
    _collegeIdController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  void _toggleAuthMode() async {
    await _tts.stop();

    if (!mounted) return;

    setState(() {
      _isLogin = !_isLogin;
      _loading = false;
      _robotExpression = AIRobotExpression.idle;

      if (!_isLogin) {
        _loginPromptStarted = true;
      } else {
        _loginPromptStarted = false;
      }
    });

    if (_isLogin) {
      await _speakLoginMessage();
    }
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
  void dispose() {
    _tts.stop();

    _nameController.dispose();
    _rollController.dispose();
    _collegeIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // --------------------------------------------------
                    // ROBOT
                    // --------------------------------------------------
                    Center(
                      child: AIRobot(expression: _robotExpression, size: 190),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'CampusX',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _isLogin
                          ? 'Welcome back to your smart campus.'
                          : 'Create your CampusX student account.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // --------------------------------------------------
                    // LOGIN / REGISTER CARD
                    // --------------------------------------------------
                    Card(
                      elevation: 0,
                      color: isDark ? const Color(0xFF11172A) : theme.cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isLogin ? 'Login' : 'Create Account',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ------------------------------------------------
                            // REGISTER FIELDS
                            // ------------------------------------------------
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (!_isLogin &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _rollController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Roll Number',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: (value) {
                                  if (!_isLogin &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Please enter roll number';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _collegeIdController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'College ID',
                                  prefixIcon: Icon(Icons.school_outlined),
                                ),
                                validator: (value) {
                                  if (!_isLogin &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Please enter college ID';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 14),
                            ],

                            // ------------------------------------------------
                            // EMAIL
                            // ------------------------------------------------
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';

                                if (email.isEmpty) {
                                  return 'Please enter email';
                                }

                                if (!email.contains('@') ||
                                    !email.contains('.')) {
                                  return 'Please enter a valid email';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            // ------------------------------------------------
                            // PASSWORD
                            // ------------------------------------------------
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: _isLogin
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                              onFieldSubmitted: (_) {
                                if (_isLogin && !_loading) {
                                  _submit();
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter password';
                                }

                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }

                                return null;
                              },
                            ),

                            // ------------------------------------------------
                            // CONFIRM PASSWORD
                            // ------------------------------------------------
                            if (!_isLogin) ...[
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: const Icon(Icons.lock_reset),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm password';
                                  }

                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }

                                  return null;
                                },
                              ),
                            ],

                            const SizedBox(height: 22),

                            // ------------------------------------------------
                            // SUBMIT BUTTON
                            // ------------------------------------------------
                            SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _loading ? null : _submit,
                                icon: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        _isLogin
                                            ? Icons.login_rounded
                                            : Icons.person_add_alt_1_rounded,
                                      ),
                                label: Text(
                                  _loading
                                      ? 'Please wait...'
                                      : (_isLogin ? 'Login' : 'Create Account'),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ------------------------------------------------
                            // SWITCH LOGIN / REGISTER
                            // ------------------------------------------------
                            TextButton(
                              onPressed: _loading ? null : _toggleAuthMode,
                              child: Text(
                                _isLogin
                                    ? "Don't have an account? Register"
                                    : 'Already have an account? Login',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // --------------------------------------------------
                    // ROBOT STATUS
                    // --------------------------------------------------
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        _robotExpression == AIRobotExpression.thinking
                            ? '🤖 Thinking...'
                            : _robotExpression == AIRobotExpression.speaking
                            ? '🤖 Speaking...'
                            : _robotExpression == AIRobotExpression.error
                            ? '🤖 Something went wrong'
                            : '🤖 CampusX AI Assistant',
                        key: ValueKey(_robotExpression),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'CampusX • AI-Powered Smart Campus',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
