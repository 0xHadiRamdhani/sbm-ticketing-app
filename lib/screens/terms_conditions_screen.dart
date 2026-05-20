import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_colors.dart';
import 'shared/ticket_card.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
        titleText: lang.translate('Syarat & Ketentuan', 'Terms & Conditions'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(c.isDark ? 0.4 : 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.gavel_rounded, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                Text(
                  lang.translate('Syarat & Ketentuan Penggunaan', 'Terms & Conditions of Use'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lang.translate('Terakhir diperbarui: 18 Mei 2026', 'Last updated: May 18, 2026'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSection(
            c: c,
            title: lang.translate('1. Ketentuan Umum', '1. General Terms'),
            content: lang.translate(
              'Dengan mengunduh, memasang, dan/atau menggunakan Aplikasi SBM ITB Ticketing Helpdesk ("Aplikasi"), Anda menyatakan bahwa Anda telah membaca, memahami, dan menyetujui untuk terikat oleh seluruh Syarat dan Ketentuan ini. Jika Anda tidak menyetujui bagian mana pun dari ketentuan ini, Anda tidak diperkenankan menggunakan Aplikasi ini.',
              'By downloading, installing, and/or using the SBM ITB Ticketing Helpdesk Application ("Application"), you represent that you have read, understood, and agreed to be bound by all of these Terms and Conditions. If you do not agree with any part of these terms, you are not permitted to use this Application.',
            ),
          ),

          _buildSection(
            c: c,
            title: lang.translate('2. Akun & Keamanan', '2. Account & Security'),
            content: lang.translate(
              '• Pendaftaran akun hanya diperuntukkan bagi civitas akademika SBM ITB yang memiliki alamat email institusi resmi (@itb.ac.id atau @sbm-itb.ac.id) atau nomor telepon yang valid.\n\n'
              '• Anda bertanggung jawab penuh atas kerahasiaan kata sandi dan aktivitas apa pun yang terjadi di bawah akun Anda.\n\n'
              '• Anda wajib segera melaporkan kepada Administrator jika mendeteksi penggunaan akun Anda secara tidak sah atau tanpa izin.',
              '• Account registration is only intended for the SBM ITB academic community with an official institutional email address (@itb.ac.id or @sbm-itb.ac.id) or a valid phone number.\n\n'
              '• You are fully responsible for maintaining the confidentiality of your password and any activities that occur under your account.\n\n'
              '• You must immediately report to the Administrator if you detect unauthorized use of your account.',
            ),
          ),

          _buildSection(
            c: c,
            title: lang.translate('3. Pengajuan Tiket Keluhan', '3. Submitting Support Tickets'),
            content: lang.translate(
              '• Pengguna wajib memberikan informasi yang akurat, jelas, dan benar saat membuat tiket keluhan baru.\n\n'
              '• Dilarang keras mengunggah foto, dokumen, atau konten chat yang mengandung unsur pornografi, SARA, ujaran kebencian, pencemaran nama baik, atau materi yang melanggar hukum.\n\n'
              '• Setiap keluhan akan diproses berdasarkan tingkat prioritas dan ketersediaan teknisi IT Support SBM ITB.',
              '• Users must provide accurate, clear, and true information when creating a new support ticket.\n\n'
              '• It is strictly prohibited to upload photos, documents, or chat content containing pornography, racism, hate speech, defamation, or any illegal materials.\n\n'
              '• Every complaint will be processed based on its priority level and the availability of SBM ITB IT Support technicians.',
            ),
          ),

          _buildSection(
            c: c,
            title: lang.translate('4. Peran dan Tanggung Jawab', '4. Roles & Responsibilities'),
            content: lang.translate(
              '• Pelapor (Mahasiswa/Dosen/Staf): Mengirimkan laporan, merespons chat teknisi jika diperlukan, dan memberikan penilaian kepuasan atas layanan.\n\n'
              '• Teknisi: Menerima tiket, memperbarui status tiket secara berkala, melakukan perbaikan, dan memberikan catatan teknis perbaikan.\n\n'
              '• Administrator: Mengelola hak akses akun pengguna, mengawasi audit log, mengelola templat notifikasi, dan menjaga keberlangsungan sistem.',
              '• Requesters (Students/Lecturers/Staff): Submitting reports, responding to technician chats if necessary, and providing satisfaction ratings for the service.\n\n'
              '• Technicians: Receiving tickets, updating ticket status periodically, performing repairs, and writing repair notes.\n\n'
              '• Administrators: Managing user access roles, monitoring audit logs, managing notification templates, and maintaining system integrity.',
            ),
          ),

          _buildSection(
            c: c,
            title: lang.translate('5. Batasan Tanggung Jawab', '5. Limitation of Liability'),
            content: lang.translate(
              'Aplikasi ini disediakan "sebagaimana adanya" tanpa jaminan dalam bentuk apa pun. SBM ITB tidak bertanggung jawab atas kerugian langsung, tidak langsung, atau konsekuensial yang timbul dari ketidakmampuan pengguna untuk mengakses Aplikasi atau keterlambatan proses perbaikan fisik akibat kendala logistik dan operasional nyata.',
              'This Application is provided "as is" without warranties of any kind. SBM ITB is not liable for any direct, indirect, or consequential damages arising from the inability of users to access the Application or delays in the physical repair process due to real-world logistics and operational constraints.',
            ),
          ),

          _buildSection(
            c: c,
            title: lang.translate('6. Hak Kekayaan Intelektual', '6. Intellectual Property Rights'),
            content: lang.translate(
              'Seluruh logo, merek dagang, desain antarmuka (UI/UX), source code, grafis, dan aset digital yang terdapat dalam Aplikasi adalah milik eksklusif SBM ITB. Anda dilarang mendistribusikan ulang, memodifikasi, atau mendekompilasi bagian apa pun dari Aplikasi tanpa izin tertulis dari pihak SBM ITB.',
              'All logos, trademarks, interface designs (UI/UX), source code, graphics, and digital assets within the Application are the exclusive property of SBM ITB. You are prohibited from redistributing, modifying, or decompiling any part of the Application without written permission from SBM ITB.',
            ),
          ),

          _buildSection(
            c: c,
            title: lang.translate('7. Perubahan Ketentuan', '7. Changes to Terms'),
            content: lang.translate(
              'Kami berhak untuk mengubah atau memperbarui Syarat dan Ketentuan ini kapan saja. Perubahan akan berlaku segera setelah dipublikasikan di Aplikasi. Keaktifan Anda menggunakan Aplikasi setelah perubahan dipublikasikan dianggap sebagai persetujuan Anda terhadap ketentuan baru tersebut.',
              'We reserve the right to modify or update these Terms and Conditions at any time. Changes will be effective immediately upon publication within the Application. Your continued use of the Application after changes are published constitutes your acceptance of the new terms.',
            ),
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.primary.withOpacity(0.2)),
            ),
            child: Text(
              lang.translate(
                'Dengan menggunakan Aplikasi SBM ITB Ticketing, Anda menyatakan telah membaca, memahami, dan menyetujui seluruh ketentuan di atas tanpa pengecualian.',
                'By using the SBM ITB Ticketing Application, you represent that you have read, understood, and agreed to all of the terms above without exception.',
              ),
              style: TextStyle(
                fontSize: 13,
                color: c.textPrimary,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              lang.translate(
                '© 2026 SBM ITB — Semua Hak Dilindungi',
                '© 2026 SBM ITB — All Rights Reserved',
              ),
              style: TextStyle(fontSize: 12, color: c.textMuted),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection({
    required AppColors c,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(c.isDark ? 0.1 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(
                fontSize: 13.5,
                color: c.textSecondary,
                height: 1.65,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
