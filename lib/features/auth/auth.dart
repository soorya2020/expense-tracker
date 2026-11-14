import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Keeps a salted hash of the PIN or password in the phone's secure storage
/// and tracks whether the app is locked.
class Auth extends ChangeNotifier {
  Auth({FlutterSecureStorage? storage}) : _store = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _store;
  final _local = LocalAuthentication();

  bool _locked = true;
  bool get locked => _locked;

  DateTime? _backgroundedAt;
  static const autoLockAfter = Duration(minutes: 1);

  static String _hash(String salt, String secret) =>
      sha256.convert(utf8.encode('$salt:$secret')).toString();

  Future<void> setSecret(String secret) async {
    final r = Random.secure();
    final salt = base64Url.encode(List.generate(16, (_) => r.nextInt(256)));
    await _store.write(key: 'salt', value: salt);
    await _store.write(key: 'hash', value: _hash(salt, secret));
  }

  Future<bool> verify(String secret) async {
    final salt = await _store.read(key: 'salt');
    final hash = await _store.read(key: 'hash');
    if (salt == null || hash == null) return false;
    return _hash(salt, secret) == hash;
  }

  Future<bool> canUseBiometrics() async {
    try {
      return await _local.canCheckBiometrics && await _local.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> biometricUnlock() async {
    try {
      final ok = await _local.authenticate(
        localizedReason: 'Unlock Tally',
        biometricOnly: true,
      );
      if (ok) unlock();
      return ok;
    } catch (_) {
      return false;
    }
  }

  void unlock() {
    _locked = false;
    notifyListeners();
  }

  void lock() {
    _locked = true;
    notifyListeners();
  }

  void onBackground() => _backgroundedAt = DateTime.now();

  void onForeground() {
    final t = _backgroundedAt;
    _backgroundedAt = null;
    if (t != null && DateTime.now().difference(t) > autoLockAfter) lock();
  }
}
