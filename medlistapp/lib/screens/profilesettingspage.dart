import 'package:flutter/material.dart';
import 'package:medlistapp/services/authservice.dart';
import 'package:medlistapp/utils/appcolors.dart';
import 'package:medlistapp/screens/loginscreen.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _companyCodeController = TextEditingController();
  
  String? _userDisplayName;
  String? _userEmail;
  String? _userPhotoUrl;
  List<String> _companyCodes = [];
  String? _primaryCompanyCode;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isChangingPassword = false;
  bool _isManagingCompanyCodes = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        setState(() {
          _userDisplayName = user.displayName;
          _userEmail = user.email;
          _userPhotoUrl = user.photoURL;
          _displayNameController.text = _userDisplayName ?? '';
          _emailController.text = _userEmail ?? '';
        });

        // Try to get additional info from Firestore
        try {
          final userData = await _authService.getUserProfile();
          if (userData != null) {
            setState(() {
              _userDisplayName = userData['displayName'] as String? ?? _userDisplayName;
              _userPhotoUrl = userData['photoURL'] as String? ?? _userPhotoUrl;
              _displayNameController.text = _userDisplayName ?? '';
              
              // Load company codes
              final companyCodesList = userData['companyCodes'] as List<dynamic>?;
              if (companyCodesList != null) {
                _companyCodes = companyCodesList.map((e) => e.toString()).toList();
              } else {
                // Fallback to old single companyCode
                final oldCode = userData['companyCode'] as String?;
                if (oldCode != null && oldCode.isNotEmpty) {
                  _companyCodes = [oldCode];
                }
              }
              _primaryCompanyCode = userData['primaryCompanyCode'] as String? ?? 
                                   (_companyCodes.isNotEmpty ? _companyCodes.first : null);
            });
          }
        } catch (e) {
          print('Error loading Firestore profile: $e');
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_displayNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name cannot be empty')),
      );
      return;
    }

    try {
      setState(() => _isEditing = true);
      
      // Update display name in Firebase Auth
      final user = _authService.currentUser;
      if (user != null) {
        await user.updateDisplayName(_displayNameController.text.trim());
        await user.reload();
      }

      // Update profile in Firestore
      await _authService.updateUserProfile({
        'displayName': _displayNameController.text.trim(),
        'email': _userEmail,
      });

      setState(() {
        _userDisplayName = _displayNameController.text.trim();
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        _loadUserProfile(); // Reload to get updated data
      }
    } catch (e) {
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all password fields')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    try {
      setState(() => _isChangingPassword = true);
      
      await _authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      setState(() => _isChangingPassword = false);
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
        Navigator.pop(context); // Close password change dialog
      }
    } catch (e) {
      setState(() => _isChangingPassword = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing password: $e')),
        );
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _currentPasswordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isChangingPassword ? null : _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.skyBlue,
              foregroundColor: AppColors.pureWhite,
            ),
            child: _isChangingPassword
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
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
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error signing out: $e')),
          );
        }
      }
    }
  }

  Future<void> _addCompanyCode() async {
    final code = _companyCodeController.text.trim();
    if (code.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company code must be at least 3 characters'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    try {
      setState(() => _isManagingCompanyCodes = true);
      await _authService.addCompanyCode(code);
      _companyCodeController.clear();
      await _loadUserProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company code added successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding company code: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      setState(() => _isManagingCompanyCodes = false);
    }
  }

  Future<void> _removeCompanyCode(String code) async {
    if (_companyCodes.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot remove the last company code'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Company Code'),
        content: Text('Are you sure you want to remove company code "$code"?'),
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isManagingCompanyCodes = true);
        await _authService.removeCompanyCode(code);
        await _loadUserProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company code removed successfully'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing company code: $e'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      } finally {
        setState(() => _isManagingCompanyCodes = false);
      }
    }
  }

  Future<void> _setPrimaryCompanyCode(String code) async {
    try {
      setState(() => _isManagingCompanyCodes = true);
      await _authService.setPrimaryCompanyCode(code);
      await _loadUserProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primary company code updated'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting primary company code: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      setState(() => _isManagingCompanyCodes = false);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _companyCodeController.dispose();
    super.dispose();
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserProfile,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile Header Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Profile Picture
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.pureWhite,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.skyBlue,
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                                  ? Image.network(
                                      _userPhotoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.person,
                                          size: 50,
                                          color: AppColors.skyBlue,
                                        );
                                      },
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 50,
                                      color: AppColors.skyBlue,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _userDisplayName ?? 'User',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_userEmail != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _userEmail!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Profile Information Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _displayNameController,
                            decoration: InputDecoration(
                              labelText: 'Display Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            enabled: true,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            enabled: false, // Email cannot be changed
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.skyBlue,
                                foregroundColor: AppColors.pureWhite,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: _isEditing ? null : _updateProfile,
                              child: _isEditing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.pureWhite),
                                      ),
                                    )
                                  : const Text('Update Profile'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Company Codes Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Company Codes',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage your company memberships. You can belong to multiple companies.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Current Company Codes List
                          if (_companyCodes.isNotEmpty) ...[
                            ..._companyCodes.map((code) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: _primaryCompanyCode == code 
                                  ? AppColors.skyBlue.withOpacity(0.1)
                                  : Colors.grey[50],
                              child: ListTile(
                                leading: Icon(
                                  _primaryCompanyCode == code 
                                      ? Icons.star
                                      : Icons.business_outlined,
                                  color: _primaryCompanyCode == code 
                                      ? AppColors.skyBlue
                                      : Colors.grey[600],
                                ),
                                title: Text(
                                  code,
                                  style: TextStyle(
                                    fontWeight: _primaryCompanyCode == code 
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: _primaryCompanyCode == code
                                    ? const Text('Primary Company')
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_primaryCompanyCode != code)
                                      IconButton(
                                        icon: const Icon(Icons.star_outline),
                                        onPressed: _isManagingCompanyCodes 
                                            ? null 
                                            : () => _setPrimaryCompanyCode(code),
                                        tooltip: 'Set as primary',
                                      ),
                                    if (_companyCodes.length > 1)
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, color: AppColors.errorRed),
                                        onPressed: _isManagingCompanyCodes 
                                            ? null 
                                            : () => _removeCompanyCode(code),
                                        tooltip: 'Remove',
                                      ),
                                  ],
                                ),
                              ),
                            )),
                            const SizedBox(height: 16),
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No company codes added yet',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          // Add Company Code Field
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _companyCodeController,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    labelText: 'Company Code',
                                    hintText: 'Enter company code',
                                    prefixIcon: const Icon(Icons.business_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    helperText: 'Minimum 3 characters',
                                  ),
                                  enabled: !_isManagingCompanyCodes,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isManagingCompanyCodes 
                                    ? null 
                                    : _addCompanyCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.skyBlue,
                                  foregroundColor: AppColors.pureWhite,
                                  padding: const EdgeInsets.all(16),
                                ),
                                child: _isManagingCompanyCodes
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            AppColors.pureWhite,
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Account Settings Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Settings',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.lock_outline),
                            title: const Text('Change Password'),
                            subtitle: const Text('Update your account password'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _showChangePasswordDialog,
                          ),
                          const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.logout, color: AppColors.errorRed),
                            title: Text(
                              'Sign Out',
                              style: TextStyle(color: AppColors.errorRed),
                            ),
                            subtitle: const Text('Sign out of your account'),
                            trailing: Icon(Icons.chevron_right, color: AppColors.errorRed),
                            onTap: _signOut,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

