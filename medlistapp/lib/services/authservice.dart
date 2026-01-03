import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Use web client ID for better compatibility
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '296137057306-6u05jgggb9ndm9eed2aqe14989tbsfmq.apps.googleusercontent.com',
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update last login time
      if (userCredential.user != null) {
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .collection('profile')
            .doc('data')
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String companyCode,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);

        // Create user profile in Firestore with multiple companies support
        final normalizedCode = companyCode.trim().toUpperCase();
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .collection('profile')
            .doc('data')
            .set({
          'email': email.trim(),
          'displayName': displayName,
          'companyCodes': [normalizedCode],
          'primaryCompanyCode': normalizedCode,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Helper method to update user profile in Firestore with retry
  Future<void> _updateUserProfileInFirestore({
    required String userId,
    required String email,
    String? displayName,
    String? photoURL,
    required bool isNewUser,
  }) async {
    try {
      // Retry logic with exponential backoff
      int maxRetries = 3;
      int retryDelay = 1; // seconds
      
      for (int attempt = 0; attempt < maxRetries; attempt++) {
        try {
          if (isNewUser) {
            // Try to get existing document first
            final userDoc = await _firestore
                .collection('users')
                .doc(userId)
                .collection('profile')
                .doc('data')
                .get();
            
            if (!userDoc.exists) {
              // Create new profile
              // Check if user already has company code
              final existingDoc = await _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('profile')
                  .doc('data')
                  .get();
              
              final existingData = existingDoc.data();
              // Check for new structure first
              final existingCompanyCodes = existingData?['companyCodes'] as List<dynamic>?;
              final existingPrimaryCode = existingData?['primaryCompanyCode'] as String?;
              // Fallback to old structure
              final existingCompanyCode = existingData?['companyCode'] as String?;
              
              // Preserve existing company codes
              if (existingCompanyCodes != null && existingCompanyCodes.isNotEmpty) {
                await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('profile')
                    .doc('data')
                    .set({
                  'email': email,
                  'displayName': displayName ?? '',
                  'photoURL': photoURL,
                  'companyCodes': existingCompanyCodes,
                  'primaryCompanyCode': existingPrimaryCode ?? existingCompanyCodes.first,
                  'createdAt': FieldValue.serverTimestamp(),
                  'lastLogin': FieldValue.serverTimestamp(),
                  'authProvider': 'google',
                }, SetOptions(merge: true));
              } else if (existingCompanyCode != null && existingCompanyCode.isNotEmpty) {
                // Migrate old structure
                await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('profile')
                    .doc('data')
                    .set({
                  'email': email,
                  'displayName': displayName ?? '',
                  'photoURL': photoURL,
                  'companyCodes': [existingCompanyCode],
                  'primaryCompanyCode': existingCompanyCode,
                  'createdAt': FieldValue.serverTimestamp(),
                  'lastLogin': FieldValue.serverTimestamp(),
                  'authProvider': 'google',
                }, SetOptions(merge: true));
              } else {
                // No existing company code
                await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('profile')
                    .doc('data')
                    .set({
                  'email': email,
                  'displayName': displayName ?? '',
                  'photoURL': photoURL,
                  'createdAt': FieldValue.serverTimestamp(),
                  'lastLogin': FieldValue.serverTimestamp(),
                  'authProvider': 'google',
                }, SetOptions(merge: true));
              }
            } else {
              // Update existing profile
              await _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('profile')
                  .doc('data')
                  .update({
                'lastLogin': FieldValue.serverTimestamp(),
              });
            }
          } else {
            // Update last login for existing user
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('profile')
                .doc('data')
                .update({
              'lastLogin': FieldValue.serverTimestamp(),
            });
          }
          // Success - exit retry loop
          return;
        } on FirebaseException catch (e) {
          // If it's unavailable error and we have retries left, retry
          if (e.code == 'unavailable' && attempt < maxRetries - 1) {
            await Future.delayed(Duration(seconds: retryDelay));
            retryDelay *= 2; // Exponential backoff
            continue;
          }
          // If it's a different error or no retries left, rethrow
          rethrow;
        }
      }
    } catch (e) {
      // Log error but don't fail the sign-in process
      // Firestore operations are non-critical for authentication
      print('Warning: Failed to update user profile in Firestore: $e');
      // Don't throw - allow sign-in to succeed even if Firestore fails
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Check if this is a new user or existing user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      // Update user profile in Firestore (non-blocking, with retry)
      // This won't fail the sign-in if Firestore is unavailable
      if (userCredential.user != null) {
        // Call without await to make it non-blocking
        // Errors are handled inside _updateUserProfileInFirestore
        _updateUserProfileInFirestore(
          userId: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName,
          photoURL: userCredential.user!.photoURL,
          isNewUser: isNewUser,
        ).catchError((error) {
          // Silently handle errors - don't fail sign-in
          print('Warning: Firestore profile update failed: $error');
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Provide more helpful error messages
      final errorString = e.toString();
      if (errorString.contains('ApiException: 10') || 
          errorString.contains('DEVELOPER_ERROR') ||
          errorString.contains('sign_in_failed') ||
          errorString.contains('12500') ||
          errorString.contains('SIGN_IN_FAILED')) {
        throw Exception(
          'Google Sign-In configuration error.\n\n'
          'CRITICAL: Enable Google Sign-In in Firebase Console!\n'
          '1. Go to Firebase Console → Authentication → Sign-in method\n'
          '2. Click "Google" → Toggle "Enable" to ON\n'
          '3. Enter Project support email → Save\n\n'
          'Also verify:\n'
          '• SHA-1 fingerprint is added in Firebase Console\n'
          '• Updated google-services.json is in android/app/\n'
          '• App is rebuilt: flutter clean && flutter run\n\n'
          'Current error: ${e.toString()}'
        );
      }
      if (errorString.contains('cloud_firestore/unavailable') || 
          errorString.contains('unavailable')) {
        throw Exception(
          'Firestore service is temporarily unavailable.\n\n'
          'This is usually a temporary issue. Please:\n'
          '1. Check your internet connection\n'
          '2. Verify Firestore is enabled in Firebase Console\n'
          '3. Try again in a few moments\n\n'
          'Note: Your Google Sign-In was successful, but profile update failed.'
        );
      }
      if (errorString.contains('network') || errorString.contains('Network')) {
        throw Exception('Network error. Please check your internet connection.');
      }
      if (errorString.contains('cancelled') || errorString.contains('CANCELLED')) {
        throw Exception('Google sign in was cancelled.');
      }
      throw Exception('Google sign in failed: ${e.toString().replaceAll(RegExp(r'Exception: '), '')}');
    }
  }

  // Sign in with PIN
  Future<void> signInWithPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      
      if (savedEmail == null) {
        throw Exception('No saved email found. Please login with email first.');
      }

      // Hash the PIN
      final pinHash = _hashPin(pin);
      final savedPinHash = prefs.getString('saved_pin_hash');

      if (savedPinHash == null || savedPinHash != pinHash) {
        throw Exception('Invalid PIN');
      }

      // Get password from secure storage (in a real app, use flutter_secure_storage)
      final savedPassword = prefs.getString('saved_password');
      if (savedPassword == null) {
        throw Exception('No saved password found. Please login with email first.');
      }

      // Sign in with email and saved password
      await signInWithEmailAndPassword(
        email: savedEmail,
        password: savedPassword,
      );
    } catch (e) {
      throw Exception('PIN login failed: $e');
    }
  }

  // Set PIN for user
  Future<void> setPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pinHash = _hashPin(pin);
      await prefs.setString('saved_pin_hash', pinHash);
    } catch (e) {
      throw Exception('Failed to set PIN: $e');
    }
  }

  // Save password for PIN login (in production, use flutter_secure_storage)
  Future<void> savePasswordForPinLogin(String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_password', password);
    } catch (e) {
      throw Exception('Failed to save password: $e');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_password');
      await prefs.remove('saved_pin_hash');
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('data')
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Check if document exists
      final profileDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('data')
          .get();

      // Get user info from Firebase Auth for initial profile creation
      final user = currentUser;
      final userEmail = user?.email ?? '';
      final userDisplayName = user?.displayName ?? '';
      final userPhotoUrl = user?.photoURL;

      // Use set with merge to create document if it doesn't exist
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('data')
          .set({
        'email': userEmail,
        'displayName': userDisplayName,
        'photoURL': userPhotoUrl,
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!profileDoc.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Get current user's company code (returns primary company code)
  // Supports both old single companyCode and new multiple companies structure
  Future<String?> getCurrentUserCompanyCode() async {
    try {
      final profile = await getUserProfile();
      if (profile == null) return null;
      
      // Check for primary company code (new structure)
      final primaryCompanyCode = profile['primaryCompanyCode'] as String?;
      if (primaryCompanyCode != null && primaryCompanyCode.isNotEmpty) {
        return primaryCompanyCode;
      }
      
      // Check for companyCodes array (new structure)
      final companyCodes = profile['companyCodes'] as List<dynamic>?;
      if (companyCodes != null && companyCodes.isNotEmpty) {
        // Return first company code as primary if no primary is set
        return companyCodes.first.toString();
      }
      
      // Fallback to old single companyCode field (backward compatibility)
      final companyCode = profile['companyCode'] as String?;
      if (companyCode != null && companyCode.isNotEmpty) {
        // Migrate old structure to new structure
        await _migrateToMultipleCompanies(companyCode);
        return companyCode;
      }
      
      return null;
    } catch (e) {
      print('Error getting company code: $e');
      return null;
    }
  }

  // Get all company codes for current user
  Future<List<String>> getUserCompanyCodes() async {
    try {
      final profile = await getUserProfile();
      if (profile == null) return [];
      
      final companyCodes = profile['companyCodes'] as List<dynamic>?;
      if (companyCodes != null && companyCodes.isNotEmpty) {
        return companyCodes.map((e) => e.toString()).toList();
      }
      
      // Fallback to old single companyCode
      final companyCode = profile['companyCode'] as String?;
      if (companyCode != null && companyCode.isNotEmpty) {
        return [companyCode];
      }
      
      return [];
    } catch (e) {
      print('Error getting company codes: $e');
      return [];
    }
  }

  // Add a company code to user's list
  Future<void> addCompanyCode(String companyCode) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final normalizedCode = companyCode.trim().toUpperCase();
      if (normalizedCode.length < 3) {
        throw Exception('Company code must be at least 3 characters');
      }

      // Check if profile document exists
      final profileDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('data')
          .get();

      final existingCodes = await getUserCompanyCodes();
      
      if (existingCodes.contains(normalizedCode)) {
        throw Exception('Company code already exists');
      }

      // Add to companyCodes array
      final updatedCodes = [...existingCodes, normalizedCode];
      
      // If no primary company code, set this as primary
      final profile = profileDoc.data();
      final primaryCompanyCode = profile?['primaryCompanyCode'] as String?;
      final newPrimaryCode = primaryCompanyCode ?? normalizedCode;

      // Get user info from Firebase Auth for initial profile creation
      final user = currentUser;
      final userEmail = user?.email ?? '';
      final userDisplayName = user?.displayName ?? '';
      final userPhotoUrl = user?.photoURL;

      // Use set with merge to create document if it doesn't exist
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('data')
          .set({
        'email': userEmail,
        'displayName': userDisplayName,
        'photoURL': userPhotoUrl,
        'companyCodes': updatedCodes,
        'primaryCompanyCode': newPrimaryCode,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!profileDoc.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to add company code: $e');
    }
  }

  // Remove a company code from user's list
  Future<void> removeCompanyCode(String companyCode) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final normalizedCode = companyCode.trim().toUpperCase();
      final existingCodes = await getUserCompanyCodes();
      
      if (!existingCodes.contains(normalizedCode)) {
        throw Exception('Company code not found');
      }

      if (existingCodes.length == 1) {
        throw Exception('Cannot remove the last company code');
      }

      final updatedCodes = existingCodes.where((c) => c != normalizedCode).toList();
      
      // If removing primary company code, set first remaining as primary
      final profile = await getUserProfile();
      final primaryCompanyCode = profile?['primaryCompanyCode'] as String?;
      final newPrimaryCode = (primaryCompanyCode == normalizedCode) 
          ? updatedCodes.first 
          : primaryCompanyCode;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('data')
          .update({
        'companyCodes': updatedCodes,
        'primaryCompanyCode': newPrimaryCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove company code: $e');
    }
  }

  // Set primary company code
  Future<void> setPrimaryCompanyCode(String companyCode) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final normalizedCode = companyCode.trim().toUpperCase();
      final existingCodes = await getUserCompanyCodes();
      
      if (!existingCodes.contains(normalizedCode)) {
        throw Exception('Company code not found in your list');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('data')
          .update({
        'primaryCompanyCode': normalizedCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to set primary company code: $e');
    }
  }

  // Migrate old single companyCode to new multiple companies structure
  Future<void> _migrateToMultipleCompanies(String companyCode) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      final normalizedCode = companyCode.trim().toUpperCase();
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('data')
          .update({
        'companyCodes': [normalizedCode],
        'primaryCompanyCode': normalizedCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error migrating company code: $e');
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Delete user data from Firestore
      final userId = user.uid;
      await _firestore.collection('users').doc(userId).delete();

      // Delete user from Firebase Auth
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Hash PIN for storage
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please login again.';
      default:
        return e.message ?? 'An error occurred: ${e.code}';
    }
  }
}

