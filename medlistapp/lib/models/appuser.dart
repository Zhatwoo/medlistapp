import 'package:medlistapp/models/userrole.dart';

class AppUser {
  final int? id;
  final String firebaseUid;
  final String displayName;
  final String email;
  final UserRole role;
  final DateTime createdAt;

  AppUser({
    this.id,
    required this.firebaseUid,
    required this.displayName,
    required this.email,
    required this.role,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'display_name': displayName,
      'email': email,
      'role': role.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      firebaseUid: map['firebase_uid'] as String,
      displayName: map['display_name'] as String,
      email: map['email'] as String,
      role: UserRoleExtension.fromString(map['role'] as String? ?? 'pharmacist'),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  AppUser copyWith({
    int? id,
    String? firebaseUid,
    String? displayName,
    String? email,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
