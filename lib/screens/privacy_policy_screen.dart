import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: Color(0xFF1A3A5C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kebijakan Privasi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A3A5C),
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A5C),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A3A5C).withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.privacy_tip_outlined,
                    color: Colors.white, size: 32),
                const SizedBox(height: 12),
                const Text(
                  'Kebijakan Privasi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Terakhir diperbarui: 12 Mei 2026',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSection(
            title: '1. Pendahuluan',
            content:
                'Aplikasi SBM ITB Ticketing Helpdesk ("Aplikasi") dikembangkan oleh tim pengembang School of Business and Management Institut Teknologi Bandung (SBM ITB). Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, dan melindungi informasi pribadi Anda saat menggunakan Aplikasi ini.\n\nDengan menggunakan Aplikasi ini, Anda menyetujui praktik pengumpulan dan penggunaan data sebagaimana yang diuraikan dalam kebijakan ini.',
          ),

          _buildSection(
            title: '2. Informasi yang Kami Kumpulkan',
            content:
                'Kami dapat mengumpulkan informasi berikut saat Anda menggunakan Aplikasi:\n\n'
                '• Informasi Identitas: Nama lengkap, alamat email institusional (@itb.ac.id atau @sbm-itb.ac.id), dan nomor telepon.\n\n'
                '• Data Tiket: Kategori keluhan, deskripsi masalah, lokasi, prioritas, dan status penyelesaian yang Anda atau teknisi masukkan.\n\n'
                '• Lampiran Foto: Gambar yang Anda unggah sebagai bukti kerusakan atau perbaikan fasilitas.\n\n'
                '• Data Komunikasi: Pesan yang dikirimkan melalui fitur obrolan (chat) antara pelapor dan teknisi.\n\n'
                '• Data Penggunaan: Informasi teknis seperti jenis perangkat dan waktu akses untuk keperluan diagnostik sistem.',
          ),

          _buildSection(
            title: '3. Cara Penggunaan Informasi',
            content:
                'Informasi yang kami kumpulkan digunakan untuk tujuan-tujuan berikut:\n\n'
                '• Memproses dan mengelola laporan tiket keluhan fasilitas.\n\n'
                '• Memverifikasi identitas pengguna melalui kode OTP yang dikirimkan ke email terdaftar menggunakan layanan EmailJS.\n\n'
                '• Memfasilitasi komunikasi antara pemohon dan teknisi yang ditugaskan.\n\n'
                '• Mengirimkan notifikasi pembaruan status tiket kepada pengguna yang bersangkutan.\n\n'
                '• Menghasilkan laporan statistik agregat (tanpa data identitas) untuk keperluan manajemen fasilitas SBM ITB.',
          ),

          _buildSection(
            title: '4. Penyimpanan dan Keamanan Data',
            content:
                'Data Anda disimpan menggunakan infrastruktur Google Firebase Cloud Firestore yang aman dan terenkripsi. Gambar lampiran disimpan menggunakan layanan pihak ketiga ImgBB dengan enkripsi standar industri.\n\nKami menerapkan langkah-langkah keamanan teknis dan organisasi yang wajar untuk melindungi data Anda dari akses, pengungkapan, atau penghancuran yang tidak sah. Namun, tidak ada metode transmisi data melalui internet yang sepenuhnya aman.',
          ),

          _buildSection(
            title: '5. Berbagi Informasi dengan Pihak Ketiga',
            content:
                'Kami tidak menjual, memperdagangkan, atau menyewakan informasi pribadi Anda kepada pihak ketiga untuk tujuan komersial.\n\nInformasi dapat dibagikan kepada:\n\n'
                '• Layanan Firebase (Google): Untuk autentikasi, penyimpanan database, dan sinkronisasi data.\n\n'
                '• EmailJS: Untuk pengiriman kode verifikasi OTP ke alamat email Anda.\n\n'
                '• ImgBB: Untuk penyimpanan foto lampiran tiket yang diunggah.\n\nLayanan pihak ketiga ini memiliki kebijakan privasi masing-masing yang mengatur penggunaan informasi Anda.',
          ),

          _buildSection(
            title: '6. Hak Pengguna',
            content:
                'Sebagai pengguna Aplikasi, Anda memiliki hak untuk:\n\n'
                '• Mengakses data pribadi Anda yang tersimpan di Aplikasi.\n\n'
                '• Meminta koreksi atas data yang tidak akurat.\n\n'
                '• Meminta penghapusan akun dan data terkait dengan menghubungi administrator sistem.\n\n'
                '• Menolak menerima notifikasi dengan menyesuaikan pengaturan pada menu Pengaturan > Pemberitahuan.',
          ),

          _buildSection(
            title: '7. Retensi Data',
            content:
                'Data tiket dan riwayat komunikasi disimpan selama diperlukan untuk keperluan operasional dan audit internal SBM ITB. Data akun pengguna yang tidak aktif selama lebih dari 24 bulan dapat dihapus secara berkala oleh administrator sistem.',
          ),

          _buildSection(
            title: '8. Perubahan Kebijakan',
            content:
                'Kami berhak untuk memperbarui Kebijakan Privasi ini sewaktu-waktu. Perubahan signifikan akan diberitahukan melalui notifikasi aplikasi atau email terdaftar. Penggunaan berkelanjutan atas Aplikasi setelah perubahan diterbitkan merupakan persetujuan Anda terhadap ketentuan yang telah diperbarui.',
          ),

          _buildSection(
            title: '9. Hubungi Kami',
            content:
                'Jika Anda memiliki pertanyaan atau kekhawatiran mengenai Kebijakan Privasi ini, silakan menghubungi tim pengembang SBM ITB melalui saluran resmi institusi.',
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFD0FF)),
            ),
            child: const Text(
              'Dengan menggunakan Aplikasi SBM ITB Ticketing, Anda menyatakan telah membaca, memahami, dan menyetujui seluruh ketentuan dalam Kebijakan Privasi ini.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1A3A5C),
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              '© 2026 SBM ITB — Semua Hak Dilindungi',
              style: TextStyle(fontSize: 12, color: Color(0xFFB0B8C1)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF475569),
                height: 1.65,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
