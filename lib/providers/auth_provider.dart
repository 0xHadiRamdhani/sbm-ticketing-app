import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final DeviceService _deviceService = DeviceService();

  UserModel? _user;
  UserModel? _originalAdminUser;
  bool _isLoading = true;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isImpersonating => _originalAdminUser != null;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _authService.userStream.listen((firebaseUser) async {
      if (isImpersonating) return;
      try {
        if (firebaseUser == null) {
          _user = null;
        } else {
          UserModel? fetchedUser = await _authService.getCurrentUser();
          if (fetchedUser != null) {
            _user = fetchedUser;
            // Daftarkan perangkat saat ini secara otomatis
            _deviceService.registerCurrentDevice(_user!.uid);
          } else {
            if (_user == null || _user!.uid != firebaseUser.uid) {
              _user = null;
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching user data from Firestore: $e");
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

  Future<void> signInAsGuest() async {
    _setLoading(true);
    try {
      _user = await _authService.signInAsGuest();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(
    String email,
    String password,
    String name,
    String role,
    String department,
  ) async {
    _setLoading(true);
    try {
      _user = await _authService.registerWithEmail(
        email,
        password,
        name,
        role,
        department,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _originalAdminUser = null;
    _user = null;
    await _authService.logout();
    notifyListeners();
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

  Future<void> updateProfile({
    required String name,
    required String photoUrl,
  }) async {
    if (_user == null) return;
    _setLoading(true);
    try {
      await _authService.updateProfile(
        uid: _user!.uid,
        name: name,
        photoUrl: photoUrl,
      );
      // Update local user object
      _user = UserModel(
        uid: _user!.uid,
        name: name,
        email: _user!.email,
        role: _user!.role,
        department: _user!.department,
        phoneNumber: _user!.phoneNumber,
        photoUrl: photoUrl,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshUserData() async {
    if (isImpersonating || _user == null) return;
    try {
      UserModel? fetchedUser = await _authService.getCurrentUser();
      if (fetchedUser != null) {
        _user = fetchedUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error refreshing user data: $e");
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _setLoading(true);
    try {
      await _authService.changePassword(currentPassword, newPassword);
    } finally {
      _setLoading(false);
    }
  }

  void impersonateUser(UserModel targetUser) {
    if (_originalAdminUser == null) {
      _originalAdminUser = _user;
    }
    _user = targetUser;
    notifyListeners();
  }

  void stopImpersonating() {
    if (_originalAdminUser != null) {
      _user = _originalAdminUser;
      _originalAdminUser = null;
      notifyListeners();
    }
  }

  /// Set mock user for development (bypass authentication)
  void setMockUser(UserModel mockUser) {
    _user = mockUser;
    _isLoading = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
