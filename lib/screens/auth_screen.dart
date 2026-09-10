import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _collegeIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _collegeIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        await _login();
      } else {
        await _register();
      }
    } on FirebaseAuthException catch (e) {
      _showError(_firebaseAuthError(e));
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
      throw Exception('User account not found.');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      _showError('User profile not found in Firebase.');
      return;
    }

    final data = userDoc.data() ?? {};
    final role = data['role']?.toString().toLowerCase() ?? 'student';

    if (!mounted) {
      return;
    }

    switch (role) {
      case 'admin':
        Navigator.pushReplacementNamed(context, '/admin');
        break;

      case 'teacher':
        Navigator.pushReplacementNamed(context, '/teacher');
        break;

      case 'student':
      default:
        Navigator.pushReplacementNamed(context, '/');
        break;
    }
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final collegeId = _collegeIdController.text.trim();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Account creation failed.');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'collegeId': collegeId,
      'email': email,
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student account created successfully.')),
    );

    Navigator.pushReplacementNamed(context, '/');
  }

  String _firebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
        return 'Email or password is incorrect.';

      case 'user-not-found':
        return 'No account found with this email.';

      case 'wrong-password':
        return 'Incorrect password.';

      case 'email-already-in-use':
        return 'This email is already registered.';

      case 'weak-password':
        return 'Password is too weak.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Network error. Check your internet connection.';

      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),

                    const SizedBox(height: 32),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isLogin
                                  ? 'Welcome Back'
                                  : 'Create Student Account',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              _isLogin
                                  ? 'Login to continue to CampusX.'
                                  : 'Create your CampusX student account.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),

                            const SizedBox(height: 24),

                            _buildCollegeIdField(),

                            const SizedBox(height: 16),

                            _buildEmailField(),

                            const SizedBox(height: 16),

                            _buildPasswordField(),

                            if (!_isLogin) ...[
                              const SizedBox(height: 16),
                              _buildConfirmPasswordField(),
                            ],

                            const SizedBox(height: 24),

                            ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(_isLogin ? 'Login' : 'Create Account'),
                            ),

                            const SizedBox(height: 12),

                            TextButton(
                              onPressed: _isLoading ? null : _toggleMode,
                              child: Text(
                                _isLogin
                                    ? 'New student? Create account'
                                    : 'Already have an account? Login',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildRoleInfo(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 78,
          width: 78,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.school_rounded,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'CampusX',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 6),

        Text(
          'Smart Campus Management Platform',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildCollegeIdField() {
    return TextFormField(
      controller: _collegeIdController,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'College ID',
        hintText: 'Enter your college ID',
        prefixIcon: Icon(Icons.badge_outlined),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'College ID is required';
        }

        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'Enter your email',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Email is required';
        }

        if (!value.contains('@')) {
          return 'Enter a valid email address';
        }

        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: (_) {
        if (_isLogin && !_isLoading) {
          _submit();
        }
      },
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
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
          return 'Password is required';
        }

        if (!_isLogin && value.length < 6) {
          return 'Password must be at least 6 characters';
        }

        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) {
        if (!_isLoading) {
          _submit();
        }
      },
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        hintText: 'Re-enter your password',
        prefixIcon: const Icon(Icons.lock_reset_outlined),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
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
          return 'Please confirm your password';
        }

        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }

        return null;
      },
    );
  }

  Widget _buildRoleInfo(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.security_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'CampusX uses role-based access. '
                'Students, teachers and admins see different '
                'features according to their authorized role.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
