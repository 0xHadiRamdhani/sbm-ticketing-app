import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xFF1A3A5C),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tentang Aplikasi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A3A5C),
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo App Container
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Image.asset(
                'assets/sbm.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.confirmation_num_rounded,
                    size: 60,
                    color: Color(0xFF1A3A5C),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'SBM ITB Support',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Versi 1.9.1',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1A73E8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Info Box
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Aplikasi SBM ITB Support dirancang khusus untuk mempermudah civitas akademika SBM ITB dalam melaporkan berbagai kendala seperti keluhan Fasilitas, IT Support, maupun Akademik.\n\nDengan sistem pelacakan tiket yang terintegrasi, Anda dapat memonitor status penyelesaian masalah secara real-time dan memastikan tim teknisi segera memberikan solusi terbaik.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Footer
            const Text(
              '© 2026 SBM ITB. All rights reserved.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Code by Hadi Ramdhani',
              style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
            ),
          ],
        ),
      ),
    );
  }
}
