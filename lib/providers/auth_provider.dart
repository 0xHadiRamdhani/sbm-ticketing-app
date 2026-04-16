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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
