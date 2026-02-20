import 'package:flutter/material.dart';
import 'package:medlistapp/models/appuser.dart';
import 'package:medlistapp/models/userrole.dart';
import 'package:medlistapp/services/databaseservice.dart';
import 'package:medlistapp/utils/appcolors.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final DatabaseService _db = DatabaseService();
  List<AppUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final users = await _db.getAllUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _loading = false;
      });
    }
  }

  Future<void> _updateRole(AppUser user, UserRole newRole) async {
    try {
      await _db.updateUser(user.copyWith(role: newRole));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.displayName} is now ${newRole.displayName}')),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
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
        title: const Text('Manage Users'),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, i) {
                final user = _users[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(user.displayName),
                    subtitle: Text(user.email),
                    trailing: DropdownButton<UserRole>(
                      value: user.role,
                      items: UserRole.values.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(r.displayName, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null && v != user.role) {
                          _updateRole(user, v);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
