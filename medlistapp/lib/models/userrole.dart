enum UserRole {
  pharmacist,
  doctor,
  inventoryManager,
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.pharmacist:
        return 'Pharmacist';
      case UserRole.doctor:
        return 'Doctor / Clinician';
      case UserRole.inventoryManager:
        return 'Inventory Manager';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.pharmacist,
    );
  }
}
