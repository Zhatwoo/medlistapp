import 'package:medlistapp/models/appuser.dart';
import 'package:medlistapp/models/userrole.dart';

/// Web stub: avoids Firebase Auth to prevent JS interop TypeError.
/// Auth is disabled on web; use mobile app for sign-in.
class AuthService {
  Object? get currentUser => null;

  Future<AppUser?> getAppUser() async => null;

  Future<UserRole> getUserRole() async => UserRole.pharmacist;

  Future<void> setUserRole(UserRole role) async {
    throw UnsupportedError('User roles are not available on web. Use the mobile app.');
  }

  Future<void> ensureAppUserExists({UserRole role = UserRole.pharmacist}) async {}

  Future<String?> getCurrentUserCompanyCode() async => null;

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw UnsupportedError('Sign in is not available on web. Use the mobile app.');
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    throw UnsupportedError('Registration is not available on web. Use the mobile app.');
  }

  Future<void> signInWithGoogle() async {
    throw UnsupportedError('Google sign-in is not available on web. Use the mobile app.');
  }

  Future<void> sendPasswordResetEmail(String email) async {
    throw UnsupportedError('Password reset is not available on web. Use the mobile app.');
  }

  Future<void> signOut() async {}

  static String getErrorMessage(Object e) => e.toString();
}
