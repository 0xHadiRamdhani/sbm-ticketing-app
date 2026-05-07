import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pusat Bantuan'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildFaqItem(
            'Bagaimana cara membuat tiket?',
            'Untuk membuat tiket keluhan baru, ketuk tombol "+" pada layar Dashboard Anda, kemudian pilih kategori kerusakan, tingkat prioritas, lokasi masalah, serta detail keluhan Anda.',
          ),
          _buildFaqItem(
            'Apa arti status tiket saya?',
            '• OPEN: Tiket telah masuk ke sistem dan belum ditangani teknisi.\n• IN PROGRESS: Teknisi telah mengambil tiket Anda dan sedang menanganinya.\n• RESOLVED: Masalah Anda telah diselesaikan oleh teknisi.',
          ),
          _buildFaqItem(
            'Bagaimana cara menghubungi teknisi?',
            'Ketika tiket Anda berstatus IN PROGRESS, Anda dapat mengetuk tiket tersebut dan menggunakan fitur Chat di bagian bawah halaman untuk berkomunikasi langsung dengan teknisi yang bertugas.',
          ),
          _buildFaqItem(
            'Saya tidak bisa login, apa yang harus dilakukan?',
            'Pastikan nomor telepon Anda sudah terdaftar di sistem kami dan sinyal internet Anda stabil untuk menerima kode OTP. Jika masih bermasalah, silakan hubungi admin di ruang IT SBM ITB.',
          ),
          SizedBox(height: 32),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masih butuh bantuan?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Anda bisa mendatangi langsung staf IT Support di lantai dasar gedung SBM ITB pada jam operasional kerja.',
                  style: TextStyle(color: Colors.blue[800]),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        iconColor: Colors.blue[800],
        collapsedIconColor: Colors.grey[600],
        childrenPadding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            answer,
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
