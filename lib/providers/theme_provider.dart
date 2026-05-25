import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
  }

  static const _premiumPageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _PremiumPageTransitionsBuilder(),
      TargetPlatform.iOS: _PremiumPageTransitionsBuilder(),
      TargetPlatform.macOS: _PremiumPageTransitionsBuilder(),
    },
  );

  // ── Light Theme ─────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1A3A5C),
          secondary: Color(0xFF2563EB),
          surface: Color(0xFFFFFFFF),
          surfaceContainerHighest: Color(0xFFF7F9FC),
          onPrimary: Colors.white,
          onSurface: Color(0xFF1F2937),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF1A3A5C),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A3A5C),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A3A5C), width: 1.5),
          ),
        ),
        dividerColor: const Color(0xFFF3F4F6),
        pageTransitionsTheme: _premiumPageTransitions,
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? Colors.white : Colors.white),
          trackColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? const Color(0xFF1A3A5C) : const Color(0xFFE5E7EB)),
        ),
      );

  // ── Dark Theme (premium dark with subtle gradients) ──────
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4A90D9), // Royal Blue accent
          secondary: Color(0xFF60A5FA), // Light blue accent
          surface: Color(0xFF1E2836), // Card surface
          background: Color(0xFF0F111A), // Deep navy background for scaffold
          surfaceContainerHighest: Color(0xFF253347), // Elevated surfaces
          onPrimary: Colors.white,
          onSurface: Color(0xFFE8EDF2),
          onBackground: Color(0xFFE8EDF2),
        ),
        // Scaffold background with subtle gradient
        scaffoldBackgroundColor: const Color(0xFF0F111A),
        // Card color uses surface color, add slight elevation for depth
        cardColor: const Color(0xFF1E2836),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF0F111A),
          foregroundColor: Color(0xFFE8EDF2),
          elevation: 0,
          // Add a subtle bottom border gradient for visual interest
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90D9),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF253347),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF384D63)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF384D63)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4A90D9), width: 1.5),
          ),
          hintStyle: const TextStyle(color: Color(0xFF6B8299)),
          labelStyle: const TextStyle(color: Color(0xFF8FAFC7)),
        ),
        dividerColor: const Color(0xFF2E3F52),
        pageTransitionsTheme: _premiumPageTransitions,
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? Colors.white : const Color(0xFF8FAFC7)),
          trackColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? const Color(0xFF4A90D9) : const Color(0xFF2E3F52)),
        ),
        listTileTheme: const ListTileThemeData(
          tileColor: Color(0xFF1E2836),
          textColor: Color(0xFFE8EDF2),
          iconColor: Color(0xFF8FAFC7),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE8EDF2)),
          bodyMedium: TextStyle(color: Color(0xFFCDD8E3)),
          bodySmall: TextStyle(color: Color(0xFF8FAFC7)),
          titleLarge: TextStyle(color: Color(0xFFE8EDF2), fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Color(0xFFE8EDF2), fontWeight: FontWeight.w600),
        ),
      );
}

// ── Custom Page Transitions Builder ─────────────────────────────────────────
class _PremiumPageTransitionsBuilder extends PageTransitionsBuilder {
  const _PremiumPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slide = Tween<Offset>(
      begin: const Offset(0.06, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));
    final fade = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return SlideTransition(
      position: slide,
      child: FadeTransition(opacity: fade, child: child),
    );
  }
}
