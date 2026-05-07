import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  bool _isLoading = true;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _authService.userStream.listen((firebaseUser) async {
      try {
        if (firebaseUser == null) {
          _user = null;
        } else {
          _user = await _authService.getCurrentUser();
        }
      } catch (e) {
        debugPrint("Error fetching user data from Firestore: $e");
        _user = null; // Terjadi error (misal Firestore permissions)
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });

    // Menambah failsafe timeout. Jika stream firebase tidak memancarkan nilai apa pun awalannya karena suatu delay
    Future.delayed(Duration(seconds: 4), () {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _authService.loginWithEmail(email, password);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(String email, String password, String name, String role, String department) async {
    _setLoading(true);
    try {
      _user = await _authService.registerWithEmail(email, password, name, role, department);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  /// Kirim OTP ke nomor telepon.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    _setLoading(true);
    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (vid) {
          _setLoading(false);
          onCodeSent(vid);
        },
        onError: (err) {
          _setLoading(false);
          onError(err);
        },
      );
    } catch (e) {
      _setLoading(false);
      onError(e.toString());
    }
  }

  /// Verifikasi OTP & login via nomor telepon.
  Future<void> signInWithOtp({
    required String verificationId,
    required String smsCode,
    String? name,
    String? role,
    String? department,
  }) async {
    _setLoading(true);
    try {
      _user = await _authService.signInWithOtp(
        verificationId: verificationId,
        smsCode: smsCode,
        name: name,
        role: role,
        department: department,
      );
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
