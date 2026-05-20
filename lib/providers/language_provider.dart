import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'id'; // default to Indonesian

  String get currentLanguage => _currentLanguage;
  bool get isEnglish => _currentLanguage == 'en';

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'id';
    notifyListeners();
  }

  Future<void> toggleLanguage(String lang) async {
    if (_currentLanguage != lang) {
      _currentLanguage = lang;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', lang);
      notifyListeners();
    }
  }

  // Helper method for translations
  String translate(String id, String en) {
    return isEnglish ? en : id;
  }
}
