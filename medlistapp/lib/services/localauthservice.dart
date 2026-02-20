import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

/// Keys for SharedPreferences
const _keyBiometricEnabled = 'biometric_enabled';
const _keyPinHash = 'pin_hash';

class LocalAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric (fingerprint/face) is available on this device.
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Get list of available biometric types (fingerprint, face, etc).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return [];
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Authenticate via biometric or device PIN.
  Future<bool> authenticate({String reason = 'Verify your identity'}) async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Whether biometric lock is enabled (requires verification on app start).
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  /// Enable or disable biometric lock.
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
  }

  /// Whether a PIN has been set.
  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPinHash) != null;
  }

  /// Set or change PIN. Hashes the PIN with SHA256 before storing.
  Future<void> setPin(String pin) async {
    if (pin.length < 4) {
      throw ArgumentError('PIN must be at least 4 digits');
    }
    final hash = sha256.convert(utf8.encode(pin)).toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPinHash, hash);
  }

  /// Remove stored PIN.
  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPinHash);
  }

  /// Verify PIN against stored hash. Returns true if correct.
  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyPinHash);
    if (stored == null) return false;
    final hash = sha256.convert(utf8.encode(pin)).toString();
    return hash == stored;
  }

  /// Whether app should prompt for biometric/PIN on launch.
  Future<bool> shouldPromptOnLaunch() async {
    final biometricEnabled = await isBiometricEnabled();
    final hasPinSet = await hasPin();
    return biometricEnabled || hasPinSet;
  }
}
