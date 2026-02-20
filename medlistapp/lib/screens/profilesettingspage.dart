import 'package:flutter/material.dart';
import 'package:medlistapp/models/appuser.dart';
import 'package:medlistapp/models/userrole.dart';
import 'package:medlistapp/services/authservice.dart';
import 'package:medlistapp/screens/loginscreen.dart';
import 'package:medlistapp/screens/usermanagementpage.dart';
import 'package:medlistapp/utils/appcolors.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final AuthService _authService = AuthService();

  String get _displayName {
    final user = _authService.currentUser;
    if (user == null) return 'Guest';
    try {
      final name = (user as dynamic).displayName as String?;
      return (name != null && name.isNotEmpty) ? name : 'User';
    } catch (_) {
      return 'User';
    }
  }

  String get _email {
    final user = _authService.currentUser;
    if (user == null) return '';
    try {
      final email = (user as dynamic).email as String?;
      return email ?? '';
    } catch (_) {
      return '';
    }
  }

  bool get _isSignedIn => _authService.currentUser != null;

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: AppColors.pureWhite,
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aliceBlue,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.softBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: AppColors.skyBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepNavy,
                          ),
                    ),
                    if (_email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.mediumGray,
                            ),
                      ),
                    ],
                    if (_isSignedIn) ...[
                      const SizedBox(height: 12),
                      FutureBuilder<AppUser?>(
                        future: _authService.getAppUser(),
                        builder: (context, snap) {
                          final appUser = snap.data;
                          if (appUser == null) return const SizedBox.shrink();
                          return Chip(
                            label: Text(
                              appUser.role.displayName,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: AppColors.softBlue,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_isSignedIn)
              FutureBuilder<Object>(
                future: _authService.getUserRole(),
                builder: (context, snap) {
                  if (snap.data != UserRole.admin) return const SizedBox.shrink();
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.people, color: AppColors.skyBlue),
                          title: const Text('Manage users'),
                          subtitle: const Text('Change user roles'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UserManagementPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (_isSignedIn)
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.errorRed),
                      title: const Text(
                        'Log out',
                        style: TextStyle(
                          color: AppColors.errorRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: _logout,
                    )
                  else
                    ListTile(
                      leading: const Icon(Icons.login, color: AppColors.skyBlue),
                      title: const Text('Sign in to your account'),
                      onTap: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
