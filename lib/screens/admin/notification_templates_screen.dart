import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/ticket_card.dart';
import '../../utils/app_colors.dart';

class NotificationTemplatesScreen extends StatelessWidget {
  const NotificationTemplatesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: buildSbmAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        titleText: 'Manajemen Templat',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('notification_templates').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: c.primary),
                  );
                }
                final templates = snapshot.data!.docs;
                
                if (templates.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_notifications_outlined, size: 64, color: c.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada templat notifikasi.',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Klik tombol di bawah untuk membuat templat standar sistem.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: c.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _initializeDefaultTemplates(),
                            icon: const Icon(Icons.auto_awesome, size: 18),
                            label: const Text('Inisialisasi Templat Standar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final data = templates[index].data() as Map<String, dynamic>;
                    final id = templates[index].id;
                    return _buildTemplateCard(context, id, data, c);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeDefaultTemplates() async {
    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance.collection('notification_templates');

    final defaults = {
      'ticket_created': {
        'title': 'Tiket Baru Berhasil Dibuat',
        'body': 'Halo {name}, tiket #{id} Anda untuk kategori {category} telah masuk ke sistem kami.',
      },
      'ticket_assigned': {
        'title': 'Teknisi Telah Ditugaskan',
        'body': 'Tiket #{id} Anda sekarang ditangani oleh tim teknis kami. Harap tunggu pembaruan selanjutnya.',
      },
      'ticket_resolved': {
        'title': 'Masalah Selesai Diperbaiki',
        'body': 'Tiket #{id} telah dinyatakan SELESAI. Silakan cek detail perbaikan di aplikasi.',
      },
      'new_message': {
        'title': 'Pesan Baru di Tiket #{id}',
        'body': 'Anda menerima pesan baru terkait kendala {category}. Silakan buka chat untuk membalas.',
      },
    };

    defaults.forEach((key, value) {
      batch.set(collection.doc(key), {
        ...value,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();
  }

  Widget _buildTemplateCard(BuildContext context, String id, Map<String, dynamic> data, AppColors c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.isDark ? c.primaryLight : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.description_outlined, size: 18, color: c.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c.textMuted),
                    ),
                    Text(
                      data['title'] ?? 'No Title',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.textPrimary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _editTemplate(context, id, data),
                icon: Icon(Icons.edit_outlined, color: c.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data['body'] ?? 'No Body',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  void _editTemplate(BuildContext context, String id, Map<String, dynamic> data) {
    final titleController = TextEditingController(text: data['title']);
    final bodyController = TextEditingController(text: data['body']);
    final c = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Templat: ${id.replaceAll('_', ' ').toUpperCase()}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c.textPrimary),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: TextStyle(color: c.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Judul Notifikasi',
                  labelStyle: TextStyle(color: c.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyController,
                maxLines: 5,
                style: TextStyle(color: c.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Isi Pesan',
                  labelStyle: TextStyle(color: c.textSecondary),
                  hintText: 'Gunakan {name}, {id}, {category}, {status} sebagai variabel',
                  hintStyle: TextStyle(color: c.textMuted),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('notification_templates').doc(id).set({
                    'title': titleController.text,
                    'body': bodyController.text,
                    'updated_at': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
