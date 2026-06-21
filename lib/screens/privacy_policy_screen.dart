import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_colors.dart';
import 'shared/ticket_card.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
        titleText: lang.translate('Kebijakan Privasi', 'Privacy Policy'),
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
                  color: const Color(
                    0xFF0F172A,
                  ).withValues(alpha: c.isDark ? 0.4 : 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.privacy_tip_outlined,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  lang.translate('Kebijakan Privasi', 'Privacy Policy'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lang.translate(
                    'Terakhir diperbarui: 20 Mei 2026',
                    'Last updated: May 20, 2026',
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSection(
            context: context,
            title: lang.translate('1. Pendahuluan', '1. Introduction'),
            content: lang.translate(
              'Aplikasi SBM ITB Ticketing Helpdesk ("Aplikasi") dikembangkan oleh tim pengembang School of Business and Management Institut Teknologi Bandung (SBM ITB). Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, dan melindungi informasi pribadi Anda saat menggunakan Aplikasi ini.\n\nDengan menggunakan Aplikasi ini, Anda menyetujui praktik pengumpulan dan penggunaan data sebagaimana yang diuraikan dalam kebijakan ini.',
              'The SBM ITB Ticketing Helpdesk Application ("Application") is developed by the School of Business and Management Institut Teknologi Bandung (SBM ITB) development team. This Privacy Policy explains how we collect, use, and protect your personal information when using this Application.\n\nBy using this Application, you agree to the collection and use of data practice as described in this policy.',
            ),
          ),

          _buildSection(
            context: context,
            title: lang.translate(
              '2. Informasi yang Kami Kumpulkan',
              '2. Information We Collect',
            ),
            content: lang.translate(
              'Kami dapat mengumpulkan informasi berikut saat Anda menggunakan Aplikasi:\n\n'
                  '• Informasi Identitas: Nama lengkap, alamat email institusional (@itb.ac.id atau @sbm-itb.ac.id), dan nomor telepon.\n\n'
                  '• Data Tiket: Kategori keluhan, deskripsi masalah, lokasi, prioritas, dan status penyelesaian yang Anda atau teknisi masukkan.\n\n'
                  '• Lampiran Foto: Gambar yang Anda unggah sebagai bukti kerusakan atau perbaikan fasilitas.\n\n'
                  '• Data Komunikasi: Pesan yang dikirimkan melalui fitur obrolan (chat) antara pelapor dan teknisi.\n\n'
                  '• Data Penggunaan: Informasi teknis seperti jenis perangkat dan waktu akses untuk keperluan diagnostik sistem.',
              'We may collect the following information when you use the Application:\n\n'
                  '• Identity Information: Full name, institutional email address (@itb.ac.id or @sbm-itb.ac.id), and phone number.\n\n'
                  '• Ticket Data: Complaint category, issue description, location, priority, and resolution status entered by you or the technician.\n\n'
                  '• Photo Attachments: Images you upload as proof of damage or facility repair.\n\n'
                  '• Communication Data: Messages sent through the chat feature between the requester and the technician.\n\n'
                  '• Usage Data: Technical information such as device type and access time for system diagnostic purposes.',
            ),
          ),

          _buildSection(
            context: context,
            title: lang.translate(
              '3. Cara Penggunaan Informasi',
              '3. How We Use Information',
            ),
            content: lang.translate(
              'Informasi yang kami kumpulkan digunakan untuk tujuan-tujuan berikut:\n\n'
                  '• Memproses dan mengelola laporan tiket keluhan fasilitas.\n\n'
                  '• Memverifikasi identitas pengguna melalui kode OTP yang dikirimkan ke email terdaftar menggunakan layanan EmailJS.\n\n'
                  '• Memfasilitasi komunikasi antara pemohon dan teknisi yang ditugaskan.\n\n'
                  '• Mengirimkan notifikasi pembaruan status tiket kepada pengguna yang bersangkutan.\n\n'
                  '• Menghasilkan laporan statistik agregat (tanpa data identitas) untuk keperluan manajemen fasilitas SBM ITB.',
              'The information we collect is used for the following purposes:\n\n'
                  '• Processing and managing facility complaint ticket reports.\n\n'
                  '• Verifying user identity through OTP code sent to the registered email using the EmailJS service.\n\n'
                  '• Facilitating communication between the requester and the assigned technician.\n\n'
                  '• Sending ticket status update notifications to the respective users.\n\n'
                  '• Generating aggregated statistical reports (without identity data) for SBM ITB facility management purposes.',
            ),
          ),

          _buildSection(
            context: context,
            title: lang.translate(
              '4. Penyimpanan dan Keamanan Data',
              '4. Data Storage and Security',
            ),
            content: lang.translate(
              'Data Anda disimpan menggunakan infrastruktur Google Firebase yang aman dan terenkripsi, mencakup Cloud Firestore untuk data tiket serta Firebase Storage untuk gambar lampiran.\n\nKami menerapkan langkah-langkah keamanan teknis dan organisasi yang wajar untuk melindungi data Anda dari akses, pengungkapan, atau penghancuran yang tidak sah. Namun, tidak ada metode transmisi data melalui internet yang sepenuhnya aman.',
              'Your data is stored using a secure and encrypted Google Firebase infrastructure, including Cloud Firestore for ticket data and Firebase Storage for attachment images.\n\nWe implement reasonable technical and organizational security measures to protect your data from unauthorized access, disclosure, or destruction. However, no method of transmitting data over the internet is completely secure.',
            ),
          ),

          _buildSection(
            context: context,
            title: lang.translate(
              '5. Berbagi Informasi dengan Pihak Ketiga',
              '5. Sharing Information with Third Parties',
            ),
            content: lang.translate(
              'Kami tidak menjual, memperdagangkan, atau menyewakan informasi pribadi Anda kepada pihak ketiga untuk tujuan komersial.\n\nInformasi dapat dibagikan kepada:\n\n'
                  '• Layanan Firebase (Google): Untuk autentikasi, penyimpanan database, penyimpanan gambar (Firebase Storage), dan sinkronisasi data.\n\n'
                  '• EmailJS: Untuk pengiriman kode verifikasi OTP ke alamat email Anda.\n\nLayanan pihak ketiga ini memiliki kebijakan privasi masing-masing yang mengatur penggunaan informasi Anda.',
              'We do not sell, trade, or rent your personal information to third parties for commercial purposes.\n\nInformation may be shared with:\n\n'
                  '• Firebase Services (Google): For authentication, database storage, image storage (Firebase Storage), and data synchronization.\n\n'
                  '• EmailJS: For sending OTP verification codes to your email address.\n\nThese third-party services have their own privacy policies governing the use of your information.',
            ),
          ),

          _buildSection(
            context: context,
            title: lang.translate('6. Hak Pengguna', '6. User Rights'),
            content: lang.translate(
              'Sebagai pengguna Aplikasi, Anda memiliki hak untuk:\n\n'
                  '• Mengakses data pribadi Anda yang tersimpan di Aplikasi.\n\n'
                  '• Meminta koreksi atas data yang tidak akurat.\n\n'
                  '• Meminta penghapusan akun dan data terkait dengan menghubungi administrator sistem.\n\n'
                  '• Menolak menerima notifikasi dengan menyesuaikan pengaturan pada menu Pengaturan > Pemberitahuan.',
              'As a user of the Application, you have the right to:\n\n'
                  '• Access your personal data stored in the Application.\n\n'
                  '• Request correction of inaccurate data.\n\n'
                  '• Request deletion of your account and related data by contacting the system administrator.\n\n'
                  '• Decline to receive notifications by adjusting settings in Settings > Notifications menu.',
            ),
          ),

          _buildSection(
            context: context,
            title: lang.translate('7. Retensi Data', '7. Data Retention'),
            content: lang.translate(
              'Data tiket dan riwayat komunikasi disimpan selama diperlukan untuk keperluan operasional dan audit internal SBM ITB. Data akun pengguna yang tidak aktif selama lebih dari 24 bulan dapat dihapus secara berkala oleh administrator sistem.',
              'Ticket data and communication history are retained as long as needed for operational purposes and internal audits by SBM ITB. User account data inactive for more than 24 months may be periodically deleted by the system administrator.',
            ),
          ),

          _buildSection(
            context: context,
            title: lang.translate(
              '8. Perubahan Kebijakan',
              '8. Policy Changes',
            ),
            content: lang.translate(
              'Kami berhak untuk memperbarui Kebijakan Privasi ini sewaktu-waktu. Perubahan signifikan akan diberitahukan melalui notifikasi aplikasi atau email terdaftar. Penggunaan berkelanjutan atas Aplikasi setelah perubahan diterbitkan merupakan persetujuan Anda terhadap ketentuan yang telah diperbarui.',
              'We reserve the right to update this Privacy Policy at any time. Significant changes will be notified via app notifications or registered email. Continued use of the Application after changes are published constitutes your acceptance of the updated terms.',
            ),
          ),

          _buildSection(
            context: context,
            title: lang.translate('9. Hubungi Kami', '9. Contact Us'),
            content: lang.translate(
              'Jika Anda memiliki pertanyaan atau kekhawatiran mengenai Kebijakan Privasi ini, silakan menghubungi tim pengembang SBM ITB melalui saluran resmi institusi.',
              'If you have any questions or concerns regarding this Privacy Policy, please contact the SBM ITB development team through the official institution channels.',
            ),
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: c.isDark ? c.border : const Color(0xFFBFD0FF),
              ),
            ),
            child: Text(
              lang.translate(
                'Dengan menggunakan Aplikasi SBM ITB Ticketing, Anda menyatakan telah membaca, memahami, dan menyetujui seluruh ketentuan dalam Kebijakan Privasi ini.',
                'By using the SBM ITB Ticketing Application, you declare that you have read, understood, and agreed to all of the provisions in this Privacy Policy.',
              ),
              style: TextStyle(
                fontSize: 13,
                color: c.isDark ? c.textSecondary : const Color(0xFF1A3A5C),
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
    required BuildContext context,
    required String title,
    required String content,
  }) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: c.isDark ? 0.2 : 0.03),
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
