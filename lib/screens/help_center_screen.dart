import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/language_provider.dart';
import '../utils/app_colors.dart';
import 'shared/ticket_card.dart';

class HelpCenterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lp = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: buildSbmAppBar(
        context: context,
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        titleText: lp.translate('Pusat Bantuan', 'Help Center'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          Text(
            lp.translate('Pertanyaan yang Sering Diajukan', 'Frequently Asked Questions'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lp.translate(
              'Temukan jawaban atas pertanyaan yang paling sering diajukan mengenai layanan IT Support SBM ITB.',
              'Find answers to the most frequently asked questions about IT Support services at SBM ITB.',
            ),
            style: TextStyle(fontSize: 14, color: c.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),

          _buildFaqItem(
            context,
            lp.translate('Bagaimana cara membuat tiket?', 'How to create a ticket?'),
            lp.translate(
              'Untuk membuat tiket keluhan baru, ketuk tombol "Buat Tiket" pada layar Dashboard Anda, kemudian pilih kategori masalah, isi lokasi, dan jelaskan detail keluhan Anda.',
              'To create a new complaint ticket, tap the "Create Ticket" button on your Dashboard screen, then select a category, enter the location, and describe your complaint details.',
            ),
          ),
          _buildFaqItem(
            context,
            lp.translate('Apa arti status tiket saya?', 'What does my ticket status mean?'),
            lp.translate(
              '• OPEN: Tiket masuk dan belum diambil teknisi.\n• IN PROGRESS: Teknisi sedang menangani tiket Anda.\n• RESOLVED: Masalah Anda telah diselesaikan oleh teknisi.',
              '• OPEN: Ticket submitted and not yet assigned to a technician.\n• IN PROGRESS: A technician is handling your ticket.\n• RESOLVED: Your issue has been resolved by the technician.',
            ),
          ),
          _buildFaqItem(
            context,
            lp.translate('Berapa lama tiket saya akan ditangani?', 'How long will it take to handle my ticket?'),
            lp.translate(
              'Tim IT Support SBM ITB akan merespons tiket Anda dalam waktu 1x24 jam pada hari kerja (Senin-Jumat, 08.00-16.00 WIB).',
              'The SBM ITB IT Support team will respond to your ticket within 1x24 hours on working days (Monday-Friday, 08.00-16.00 WIB).',
            ),
          ),
          _buildFaqItem(
            context,
            lp.translate('Saya tidak bisa login, apa yang harus dilakukan?', 'I cannot log in, what should I do?'),
            lp.translate(
              'Pastikan email Anda sudah benar dan sinyal internet Anda stabil untuk menerima kode OTP via email. Jika masih bermasalah, silakan hubungi admin di ruang IT SBM.',
              'Make sure your email is correct and your internet connection is stable to receive the OTP code via email. If issues persist, please contact the admin at the SBM IT room.',
            ),
          ),

          const SizedBox(height: 32),

          // Kontak Bantuan Langsung
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3A5C), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A3A5C).withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        lp.translate('Masih butuh bantuan?', 'Still need help?'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  lp.translate(
                    'Jika kendala Anda mendesak, Anda dapat langsung menemui staf IT Support di lantai 3 gedung SBM ITB Freeport pada jam operasional kerja.',
                    'If your issue is urgent, you can directly meet the IT Support staff on the 3rd floor of the SBM ITB Freeport building during working hours.',
                  ),
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final uri = Uri.parse('https://wa.me/6283199456915');
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1A3A5C),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      lp.translate('Hubungi Pengembang Aplikasi', 'Contact App Developer'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.1 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: c.textPrimary,
            ),
          ),
          iconColor: c.primary,
          collapsedIconColor: c.textMuted,
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              answer,
              style: TextStyle(
                color: c.textSecondary,
                height: 1.6,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
