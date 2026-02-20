import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:medlistapp/models/userrole.dart';
import 'package:medlistapp/services/authservice.dart';
import 'package:medlistapp/services/localauthservice.dart';
import 'package:medlistapp/screens/loadingscreen.dart';
import 'package:medlistapp/screens/registrationscreen.dart';
import 'package:medlistapp/utils/appcolors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _localAuth = LocalAuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showVerifyScreen = false;
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthState());
  }

  Future<void> _checkAuthState() async {
    try {
      if (_authService.currentUser == null) {
        if (mounted) setState(() => _checkingAuth = false);
        return;
      }
      if (kIsWeb) {
        _navigateToMain();
        return;
      }
      final shouldPrompt = await _localAuth.shouldPromptOnLaunch();
      if (!mounted) return;
      if (shouldPrompt) {
        setState(() {
          _showVerifyScreen = true;
          _checkingAuth = false;
        });
      } else {
        _navigateToMain();
      }
    } catch (_) {
      if (mounted) setState(() => _checkingAuth = false);
    }
  }

  Future<void> _verifyAndNavigate() async {
    final biometricAvail = await _localAuth.isBiometricAvailable();
    final biometricEnabled = await _localAuth.isBiometricEnabled();
    final hasPin = await _localAuth.hasPin();

    if (biometricEnabled && biometricAvail) {
      final ok = await _localAuth.authenticate(reason: 'Verify identity to open MedList');
      if (mounted && ok) _navigateToMain();
      return;
    }
    if (hasPin) {
      _showPinDialog();
    } else {
      _navigateToMain();
    }
  }

  void _showPinDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: 'Enter your PIN',
          ),
          onSubmitted: (v) async {
            final ok = await _localAuth.verifyPin(v);
            if (!mounted) return;
            Navigator.pop(ctx);
            if (ok) _navigateToMain();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await _localAuth.verifyPin(controller.text);
              if (!mounted) return;
              Navigator.pop(ctx);
              if (ok) _navigateToMain();
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _maybeVerifyThenNavigate() async {
    if (kIsWeb) {
      _navigateToMain();
      return;
    }
    final shouldPrompt = await _localAuth.shouldPromptOnLaunch();
    if (!shouldPrompt) {
      _navigateToMain();
      return;
    }
    final biometricAvail = await _localAuth.isBiometricAvailable();
    final biometricEnabled = await _localAuth.isBiometricEnabled();
    final hasPin = await _localAuth.hasPin();

    if (biometricEnabled && biometricAvail) {
      final ok = await _localAuth.authenticate(reason: 'Verify identity to continue');
      if (mounted && ok) _navigateToMain();
      return;
    }
    if (hasPin) {
      _showPinDialog();
    } else {
      _navigateToMain();
    }
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoadingScreen()),
    );
  }

  Future<void> _signOutAndShowLogin() async {
    await _authService.signOut();
    if (mounted) setState(() => _showVerifyScreen = false);
  }

  Future<void> _signInWithEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _authService.ensureAppUserExists(role: UserRole.pharmacist);
      if (mounted) await _maybeVerifyThenNavigate();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthService.getErrorMessage(e)),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      await _authService.ensureAppUserExists(role: UserRole.pharmacist);
      if (mounted) await _maybeVerifyThenNavigate();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthService.getErrorMessage(e)),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPassword() {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email address',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your email')),
                );
                return;
              }
              try {
                await _authService.sendPasswordResetEmail(email);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password reset email sent. Check your inbox.',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AuthService.getErrorMessage(e)),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return Scaffold(
        backgroundColor: AppColors.aliceBlue,
        body: Center(child: CircularProgressIndicator(color: AppColors.skyBlue)),
      );
    }
    if (_showVerifyScreen) {
      return Scaffold(
        backgroundColor: AppColors.aliceBlue,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medication, size: 80, color: AppColors.skyBlue),
                const SizedBox(height: 24),
                Text(
                  'Verify identity',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepNavy,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You are signed in. Verify to continue.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.mediumGray,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                FutureBuilder<bool>(
                  future: _localAuth.isBiometricAvailable(),
                  builder: (ctx, snap) {
                    if (snap.data != true) {
                      return ElevatedButton(
                        onPressed: () => _showPinDialog(),
                        child: const Text('Enter PIN'),
                      );
                    }
                    return Column(
                      children: [
                        IconButton(
                          iconSize: 64,
                          icon: const Icon(Icons.fingerprint),
                          color: AppColors.skyBlue,
                          onPressed: _isLoading ? null : () async {
                            setState(() => _isLoading = true);
                            await _verifyAndNavigate();
                            if (mounted) setState(() => _isLoading = false);
                          },
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _showPinDialog(),
                          child: const Text('Use PIN instead'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _signOutAndShowLogin,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.aliceBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Icon(
                  Icons.medication,
                  size: 80,
                  color: AppColors.skyBlue,
                ),
                const SizedBox(height: 16),
                Text(
                  'MedList App',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepNavy,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.mediumGray,
                      ),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value.trim())) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signInWithEmail(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _showForgotPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _signInWithEmail,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Sign in'),
                  ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('Sign in with Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegistrationScreen(),
                                ),
                              );
                            },
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
