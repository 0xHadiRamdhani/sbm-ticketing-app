import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_colors.dart';
import 'shared/ticket_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: c.background,
      appBar: buildSbmAppBar(
        context: context,
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        titleText: lang.translate('Tentang Aplikasi', 'About App'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Hero Section ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Logo App Container with Glow
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/itb.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SBM ITB Support',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      lang.translate('Versi 2.1.2', 'Version 2.1.2'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- Deskripsi Singkat ---
            Text(
              lang.translate(
                'Sistem Pelaporan dan Bantuan Terpadu untuk Civitas Akademika SBM ITB. Laporkan masalah Anda, pantau status perbaikan, dan dapatkan bantuan secara real-time dari tim teknisi ahli kami.',
                'Integrated Reporting and Help System for SBM ITB Academic Community. Report your issues, monitor repair status, and get real-time assistance from our expert technician team.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                color: c.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),

            // --- Core Features ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                lang.translate('Layanan Utama', 'Core Services'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context: context,
              icon: Icons.computer_rounded,
              color: const Color(0xFF3B82F6), // Blue
              title: lang.translate('IT Support', 'IT Support'),
              description: lang.translate(
                'Bantuan kendala jaringan, software, email institusi, dan perangkat keras laboratorium.',
                'Assistance for network issues, software, institutional email, and laboratory hardware.',
              ),
            ),
            _buildFeatureCard(
              context: context,
              icon: Icons.domain_rounded,
              color: const Color(0xFF10B981), // Emerald
              title: lang.translate('Fasilitas Gedung', 'Building Facilities'),
              description: lang.translate(
                'Pelaporan kerusakan ruangan kelas, AC, proyektor, dan infrastruktur umum.',
                'Reporting damage to classrooms, AC, projectors, and general infrastructure.',
              ),
            ),
            _buildFeatureCard(
              context: context,
              icon: Icons.school_rounded,
              color: const Color(0xFFF59E0B), // Amber
              title: lang.translate('Layanan Akademik', 'Academic Services'),
              description: lang.translate(
                'Dukungan terkait sistem perkuliahan, akses materi, dan administrasi akademik.',
                'Support related to the lecture system, course materials access, and academic administration.',
              ),
            ),
            const SizedBox(height: 40),

            // --- Developer Info ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: c.isDark ? 0.2 : 0.02,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [c.surfaceElevated, c.surface],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: c.border, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: c.isDark ? 0.2 : 0.05,
                          ),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.code_rounded,
                      color: c.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.translate('Dikembangkan Oleh', 'Developed By'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Praktek Kerja Industri ITB',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      color: c.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // --- Footer ---
            Text(
              lang.translate(
                '© 2026 SBM ITB. Semua Hak Dilindungi.',
                '© 2026 SBM ITB. All rights reserved.',
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Code By Hadi Ramdhani',
              style: TextStyle(
                fontSize: 12,
                color: c.textMuted.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: c.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
