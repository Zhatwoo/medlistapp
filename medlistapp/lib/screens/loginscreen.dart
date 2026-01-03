import 'package:flutter/material.dart';
import 'package:medlistapp/utils/appcolors.dart';
import 'package:medlistapp/screens/mainnavigation.dart';
import 'package:medlistapp/screens/registrationscreen.dart';
import 'package:medlistapp/services/authservice.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _usePinLogin = false;
  bool _isBiometricAvailable = false;
  bool _canCheckBiometrics = false;
  
  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
    _loadSavedCredentials();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isAvailable = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      setState(() {
        _canCheckBiometrics = canCheck;
        _isBiometricAvailable = isAvailable && availableBiometrics.isNotEmpty;
      });
    } catch (e) {
      // Biometric not available
      setState(() {
        _isBiometricAvailable = false;
        _canCheckBiometrics = false;
      });
    }
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedRememberMe = prefs.getBool('remember_me') ?? false;
    
    if (savedEmail != null && savedRememberMe) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signInWithGoogle();
      
      // Check if this is a new user or existing user without company code
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      
      if (isNewUser) {
        // New user - prompt for company code
        if (mounted) {
          setState(() => _isLoading = false);
          final companyCode = await _showCompanyCodeDialog(true);
          if (companyCode != null && companyCode.isNotEmpty) {
            await _authService.addCompanyCode(companyCode);
            if (mounted) {
              _navigateToMainApp();
            }
          } else {
            // User cancelled, sign them out
            await _authService.signOut();
          }
        }
      } else {
        // Existing user - check if they have company codes
        final companyCodes = await _authService.getUserCompanyCodes();
        if (companyCodes.isEmpty) {
          // Existing user without company code, prompt for it
          if (mounted) {
            setState(() => _isLoading = false);
            final companyCode = await _showCompanyCodeDialog(false);
            if (companyCode != null && companyCode.isNotEmpty) {
              await _authService.addCompanyCode(companyCode);
              if (mounted) {
                _navigateToMainApp();
              }
            } else {
              // User cancelled, but don't sign them out for existing users
              if (mounted) {
                setState(() => _isLoading = false);
              }
            }
          }
        } else {
          // Existing user with company code(s), proceed automatically
          if (mounted) {
            _navigateToMainApp();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign in failed: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<String?> _showCompanyCodeDialog(bool isNewUser) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isNewUser ? 'Company Code Required' : 'Update Company Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isNewUser
                  ? 'Please enter your company code to continue. All users with the same code will share data.'
                  : 'Your account doesn\'t have a company code. Please enter one to continue.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Company Code',
                hintText: 'Enter your company code',
                prefixIcon: Icon(Icons.business_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (!isNewUser)
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
          ElevatedButton(
            onPressed: () {
              final code = controller.text.trim();
              if (code.length >= 3) {
                Navigator.pop(context, code);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Company code must be at least 3 characters'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
            },
            child: Text(isNewUser ? 'Continue' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to login to MedList App',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
      // Biometric authentication successful
      // Try to login with saved credentials
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final savedPassword = prefs.getString('saved_password');
      
      if (savedEmail != null && savedPassword != null) {
        try {
          await _authService.signInWithEmailAndPassword(
            email: savedEmail,
            password: savedPassword,
          );
          if (mounted) {
            _navigateToMainApp();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Login failed: $e'),
                backgroundColor: AppColors.errorRed,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No saved credentials found. Please login with email first.'),
              backgroundColor: AppColors.warningOrange,
            ),
          );
        }
      }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric authentication failed: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _loginWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Login with Firebase Authentication
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Save credentials if remember me is checked
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_email', _emailController.text.trim());
        await prefs.setBool('remember_me', true);
        // Save password for PIN login (in production, use flutter_secure_storage)
        await _authService.savePasswordForPinLogin(_passwordController.text);
      } else {
        await prefs.remove('saved_email');
        await prefs.setBool('remember_me', false);
        await prefs.remove('saved_password');
      }

      if (mounted) {
        _navigateToMainApp();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _loginWithPin() async {
    if (_pinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a 4-digit PIN'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Login with PIN
      await _authService.signInWithPin(_pinController.text);

      if (mounted) {
        _navigateToMainApp();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PIN authentication failed: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _navigateToMainApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  void _navigateToRegistration() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
    );
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first'),
          backgroundColor: AppColors.warningOrange,
        ),
      );
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Please check your inbox.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset email: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aliceBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo/App Name
                Icon(
                  Icons.medical_services_rounded,
                  size: 80,
                  color: AppColors.skyBlue,
                ),
                const SizedBox(height: 16),
                Text(
                  'MedList App',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.skyBlue,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Medication Management System',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Login Method Toggle
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildLoginMethodButton(
                            'Email',
                            Icons.email_rounded,
                            !_usePinLogin,
                            () => setState(() => _usePinLogin = false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildLoginMethodButton(
                            'PIN',
                            Icons.pin_rounded,
                            _usePinLogin,
                            () => setState(() => _usePinLogin = true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Form
                if (!_usePinLogin) ...[
                  // Email Field
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
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _loginWithEmailPassword(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
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
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Remember Me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() => _rememberMe = value ?? false);
                            },
                            activeColor: AppColors.skyBlue,
                          ),
                          Text(
                            'Remember me',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _forgotPassword,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: AppColors.skyBlue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  // PIN Field
                  TextFormField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Enter 4-digit PIN',
                      hintText: '••••',
                      counterText: '',
                      prefixIcon: const Icon(Icons.pin_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.length == 4) {
                        _loginWithPin();
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Google Sign-In Button
                if (!_usePinLogin) ...[
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loginWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.deepNavy,
                      side: const BorderSide(color: AppColors.mediumGray, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Biometric Login Button (if available)
                if (_isBiometricAvailable && !_usePinLogin) ...[
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _authenticateWithBiometrics,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('Login with Biometric'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.skyBlue,
                      side: const BorderSide(color: AppColors.skyBlue, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_usePinLogin ? _loginWithPin : _loginWithEmailPassword),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    foregroundColor: AppColors.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.pureWhite,
                            ),
                          ),
                        )
                      : Text(
                          _usePinLogin ? 'Login with PIN' : 'Login',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _navigateToRegistration,
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: AppColors.skyBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildLoginMethodButton(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.skyBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.pureWhite : AppColors.mediumGray,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.pureWhite : AppColors.mediumGray,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

