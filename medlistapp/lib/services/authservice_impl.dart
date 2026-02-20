import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:medlistapp/models/appuser.dart';
import 'package:medlistapp/models/userrole.dart';
import 'package:medlistapp/services/databaseservice.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  dynamic get currentUser => _auth.currentUser;

  final _db = DatabaseService();

  /// Get current user's AppUser record (includes role).
  Future<AppUser?> getAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _db.getUserByFirebaseUid(user.uid);
  }

  /// Get current user's role.
  Future<UserRole> getUserRole() async {
    final appUser = await getAppUser();
    return appUser?.role ?? UserRole.pharmacist;
  }

  /// Set current user's role. Creates AppUser record if missing.
  Future<void> setUserRole(UserRole role) async {
    final user = _auth.currentUser;
    if (user == null) return;
    var appUser = await _db.getUserByFirebaseUid(user.uid);
    if (appUser == null) {
      appUser = AppUser(
        firebaseUid: user.uid,
        displayName: user.displayName ?? user.email ?? 'User',
        email: user.email ?? '',
        role: role,
        createdAt: DateTime.now(),
      );
      await _db.insertUser(appUser);
    } else {
      await _db.updateUser(appUser.copyWith(role: role));
    }
  }

  /// Ensure AppUser exists for current Firebase user. Called after sign-in.
  Future<void> ensureAppUserExists({UserRole role = UserRole.pharmacist}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    var appUser = await _db.getUserByFirebaseUid(user.uid);
    if (appUser == null) {
      appUser = AppUser(
        firebaseUid: user.uid,
        displayName: user.displayName ?? user.email ?? 'User',
        email: user.email ?? '',
        role: role,
        createdAt: DateTime.now(),
      );
      await _db.insertUser(appUser);
    }
  }

  /// Get current user's company code for multi-tenant filtering.
  /// Returns null when no company is associated (single-tenant or all data visible).
  Future<String?> getCurrentUserCompanyCode() async {
    return null;
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception(getErrorMessage(e));
    }
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (displayName != null &&
          displayName.isNotEmpty &&
          credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
      }
    } catch (e) {
      throw Exception(getErrorMessage(e));
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw _AuthException('Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } catch (e) {
      if (e is _AuthException) rethrow;
      throw Exception(getErrorMessage(e));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception(getErrorMessage(e));
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  static String getErrorMessage(Object e) {
    try {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-credential':
            return 'Invalid email or password.';
          case 'email-already-in-use':
            return 'An account already exists with this email.';
          case 'weak-password':
            return 'Password is too weak. Use at least 6 characters.';
          case 'invalid-email':
            return 'Please enter a valid email address.';
          case 'user-disabled':
            return 'This account has been disabled.';
          case 'too-many-requests':
            return 'Too many attempts. Please try again later.';
          case 'operation-not-allowed':
            return 'This sign-in method is not enabled.';
          case 'network-request-failed':
            return 'Network error. Check your connection.';
          default:
            return e.message ?? 'Authentication failed.';
        }
      }
    } catch (_) {}
    final s = e.toString();
    if (s.contains('invalid-credential') ||
        s.contains('wrong-password') ||
        s.contains('user-not-found')) {
      return 'Invalid email or password.';
    }
    if (s.contains('email-already-in-use')) {
      return 'An account already exists with this email.';
    }
    if (s.contains('weak-password')) return 'Password is too weak. Use at least 6 characters.';
    if (s.contains('network')) return 'Network error. Check your connection.';
    if (s.startsWith('Exception: ')) return s.substring(11);
    return s.length > 80 ? 'Authentication failed. Please try again.' : s;
  }
}

class _AuthException implements Exception {
  final String message;
  _AuthException(this.message);
  @override
  String toString() => message;
}
