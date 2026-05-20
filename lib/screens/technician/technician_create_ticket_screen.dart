import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../shared/ticket_card.dart'; // untuk buildSbmAppBar
import '../shared/ios_glass_dropdown.dart';
import '../settings_screen.dart';
import '../../utils/app_notifications.dart';
import '../../utils/app_colors.dart';

class TechnicianCreateTicketScreen extends StatefulWidget {
  @override
  _TechnicianCreateTicketScreenState createState() => _TechnicianCreateTicketScreenState();
}

class _TechnicianCreateTicketScreenState extends State<TechnicianCreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  String? _category;
  final _locationController = TextEditingController();
  final _descController = TextEditingController();

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }



  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;

      if (_category == null) {
        AppNotifications.showNotification(
          context,
          title: 'Kategori Wajib',
          message: 'Pilih kategori masalah terlebih dahulu',
          isError: true,
        );
        return;
      }

      // Menggabungkan Judul dan Deskripsi
      final combinedDesc = "Judul: ${_titleController.text}\n\nDetail:\n${_descController.text}";

      try {
        await Provider.of<TicketProvider>(context, listen: false).submitTicket(
          requesterId: user.uid,
          category: _category!,
          description: combinedDesc,
          priority: 'Medium', // Default prioritas
          location: _locationController.text.isNotEmpty ? _locationController.text : 'Tidak ditentukan',
          imageFile: _imageFile,
        );
        if (!mounted) return;
        Navigator.pop(context);
        AppNotifications.showNotification(
          context,
          title: 'Sukses',
          message: 'Tiket berhasil dibuat!',
          isError: false,
        );
      } catch (e) {
        if (!mounted) return;
        AppNotifications.showNotification(
          context,
          title: 'Gagal',
          message: 'Gagal membuat tiket: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<TicketProvider>(context).isLoading;
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: buildSbmAppBar(
        onSettingsTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SettingsScreen()),
          );
        }
      ),
      // Menghapus bottomNavigationBar sesuai permintaan sebelumnya (hanya inbox)
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengajuan Tiket Baru',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Silakan isi formulir di bawah ini untuk melaporkan masalah atau mengajukan permintaan layanan terkait IT Support, Fasilitas, atau Akademik.',
              style: TextStyle(
                fontSize: 14,
                color: c.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(c.isDark ? 0.15 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Judul Masalah', c),
                    _buildTextField(
                      controller: _titleController,
                      hint: 'Contoh: Kerusakan AC di Ruang Kelas',
                      c: c,
                      validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 18),
                    
                    _buildLabel('Kategori', c),
                    IosGlassDropdownFormField<String>(
                      value: ['IT', 'Fasilitas', 'Akademik', 'Lainnya'].contains(_category) ? _category : null,
                      hint: 'Pilih kategori masalah',
                      items: const ['IT', 'Fasilitas', 'Akademik', 'Lainnya'],
                      itemLabelBuilder: (e) => e,
                      onChanged: (val) => setState(() => _category = val),
                      validator: (val) => val == null ? 'Wajib dipilih' : null,
                    ),
                    const SizedBox(height: 18),
                    
                    _buildLabel('Lokasi / Ruangan (Opsional)', c),
                    _buildTextField(
                      controller: _locationController,
                      hint: 'Contoh: Gedung SBM Lantai 2',
                      c: c,
                    ),
                    const SizedBox(height: 18),
                    
                    _buildLabel('Deskripsi Detail', c),
                    _buildTextField(
                      controller: _descController,
                      hint: 'Jelaskan masalah secara detail, termasuk langkah-langkah yang sudah Anda coba atau pesan error yang muncul...',
                      maxLines: 5,
                      c: c,
                      validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 18),
                    
                    _buildLabel('Lampiran (Opsional)', c),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: c.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          // Simulated dashed border using a light solid border
                          border: Border.all(
                            color: c.border,
                            width: 1.5,
                          ),
                        ),
                        child: _imageFile != null
                             ? Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_imageFile!.path),
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text('Ketuk untuk mengganti foto', style: TextStyle(fontSize: 12, color: c.textSecondary)),
                                ],
                              )
                            : Column(
                                children: [
                                  Icon(Icons.cloud_upload_outlined, size: 36, color: c.textPrimary),
                                  const SizedBox(height: 12),
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.5),
                                      children: [
                                        TextSpan(text: 'Klik untuk mengunggah\n', style: TextStyle(fontWeight: FontWeight.bold, color: c.primary)),
                                        const TextSpan(text: 'atau seret dan lepas file di sini.\n(Maks. 5MB, format: JPG, PNG, PDF)'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: c.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: Text('Batal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        icon: isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          isLoading ? 'Mengirim...' : 'Kirim Tiket',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required AppColors c,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(fontSize: 14, color: c.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: c.surfaceElevated,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}
