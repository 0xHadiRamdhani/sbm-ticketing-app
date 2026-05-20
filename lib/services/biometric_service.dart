import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _biometricEnabledKey = 'isBiometricEnabled';
  static const String _emailKey = 'biometric_email';
  static const String _passwordKey = 'biometric_password';

  // Cek apakah perangkat mendukung biometrik
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      return false;
    }
  }

  // Cek apakah fitur biometrik diaktifkan oleh pengguna
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  // Setel status fitur biometrik
  Future<void> setBiometricEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, isEnabled);
    if (!isEnabled) {
      // Hapus kredensial jika fitur dimatikan
      await _storage.delete(key: _emailKey);
      await _storage.delete(key: _passwordKey);
    }
  }

  // Simpan kredensial secara aman (dipanggil saat fitur diaktifkan dan sandi diverifikasi)
  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
  }

  // Otentikasi biometrik dan ambil kredensial untuk login
  Future<Map<String, String>?> authenticateAndGetCredentials() async {
    try {
      bool authenticated = await _auth.authenticate(
        localizedReason: 'Gunakan biometrik Anda untuk masuk ke aplikasi',
      );

      if (authenticated) {
        String? email = await _storage.read(key: _emailKey);
        String? password = await _storage.read(key: _passwordKey);
        
        if (email != null && password != null) {
          return {'email': email, 'password': password};
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
