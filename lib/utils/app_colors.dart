import 'package:flutter/material.dart';

/// Kelas helper untuk mendapatkan warna yang sesuai dengan tema aktif.
/// Gunakan: `AppColors.of(context).background` dll.
class AppColors {
  final bool isDark;
  const AppColors._(this.isDark);

  factory AppColors.of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return AppColors._(brightness == Brightness.dark);
  }

  // ── Backgrounds ──────────────────────────────────────────────────────────────
  Color get background       => isDark ? const Color(0xFF18222E) : const Color(0xFFF7F9FC);
  Color get surface          => isDark ? const Color(0xFF1E2836) : Colors.white;
  Color get surfaceElevated  => isDark ? const Color(0xFF253347) : const Color(0xFFF9FAFB);
  Color get cardHeader       => isDark ? const Color(0xFF1A2F42) : const Color(0xFFF0F4FF);
  Color get searchBar        => isDark ? const Color(0xFF253347) : const Color(0xFFF3F4F6);

  // ── App Bar ──────────────────────────────────────────────────────────────────
  Color get appBarBg         => isDark ? const Color(0xFF1A2A3F) : Colors.white;
  Color get appBarFg         => isDark ? const Color(0xFFE8EDF2) : const Color(0xFF1A3A5C);
  Color get appBarShadow     => isDark ? Colors.black26          : Colors.black12;

  // ── Text ─────────────────────────────────────────────────────────────────────
  Color get textPrimary      => isDark ? const Color(0xFFE8EDF2) : const Color(0xFF1F2937);
  Color get textSecondary    => isDark ? const Color(0xFF8FAFC7) : const Color(0xFF6B7280);
  Color get textMuted        => isDark ? const Color(0xFF5B7A96) : const Color(0xFF9CA3AF);
  Color get textLabel        => isDark ? const Color(0xFF6B8299) : const Color(0xFF9CA3AF);

  // ── Brand Colors ─────────────────────────────────────────────────────────────
  Color get primary          => isDark ? const Color(0xFF4A90D9) : const Color(0xFF1A3A5C);
  Color get primaryLight     => isDark ? const Color(0xFF1A3F5E) : const Color(0xFFEEF2FF);
  Color get accent           => isDark ? const Color(0xFF60A5FA) : const Color(0xFF1A73E8);
  Color get accentLight      => isDark ? const Color(0xFF1A3252) : const Color(0xFFEEF2FF);

  // ── Dividers & Borders ───────────────────────────────────────────────────────
  Color get divider          => isDark ? const Color(0xFF2E3F52) : const Color(0xFFF3F4F6);
  Color get border           => isDark ? const Color(0xFF384D63) : const Color(0xFFE5E7EB);

  // ── Bottom Nav ───────────────────────────────────────────────────────────────
  Color get navBg            => isDark ? const Color(0xFF1A2A3F) : Colors.white;
  Color get navSelected      => isDark ? const Color(0xFF4A90D9) : const Color(0xFF1A3A5C);
  Color get navUnselected    => isDark ? const Color(0xFF5B7A96) : const Color(0xFF9CA3AF);

  // ── Filter Chips ─────────────────────────────────────────────────────────────
  Color get chipSelected     => isDark ? const Color(0xFF4A90D9) : const Color(0xFF1A3A5C);
  Color get chipUnselected   => isDark ? const Color(0xFF253347) : Colors.white;
  Color get chipBorder       => isDark ? const Color(0xFF384D63) : const Color(0xFFE5E7EB);
}
