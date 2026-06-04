import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import 'shared/ticket_card.dart';
import '../utils/app_notifications.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  XFile? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _nameController.text = user.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                    maxWidth: 512,
                    maxHeight: 512,
                  );
                  if (image != null) setState(() => _selectedImage = image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil dari Kamera'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final image = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70,
                    maxWidth: 512,
                    maxHeight: 512,
                  );
                  if (image != null) setState(() => _selectedImage = image);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _uploadToImgBB(XFile imageFile) async {
    try {
      final bytes = await File(imageFile.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {'key': '639f57d0cc80d6da8ddb0c1927ea1a8a', 'image': base64Image},
      ).timeout(const Duration(seconds: 45), onTimeout: () {
        throw Exception('Koneksi unggah foto profil habis (Timeout).');
      });
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data']['url'];
      }
    } catch (e) {
      debugPrint('ImgBB Upload Error: $e');
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      AppNotifications.showNotification(
        context,
        title: 'Nama Wajib',
        message: 'Nama tidak boleh kosong.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      String finalPhotoUrl = auth.user?.photoUrl ?? '';

      // Upload image if a new one is selected
      if (_selectedImage != null) {
        final url = await _uploadToImgBB(_selectedImage!);
        if (url != null) {
          finalPhotoUrl = url;
        } else {
          throw Exception('Gagal mengunggah foto profil.');
        }
      }

      await auth.updateProfile(
        name: _nameController.text.trim(),
        photoUrl: finalPhotoUrl,
      );

      if (mounted) {
        AppNotifications.showNotification(
          context,
          title: 'Sukses',
          message: 'Profil berhasil diperbarui.',
          isError: false,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppNotifications.showNotification(
          context,
          title: 'Gagal',
          message: 'Gagal memperbarui profil: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    if (user == null) return const SizedBox.shrink();
    final c = AppColors.of(context);

    // Determine current photo to show
    ImageProvider? imageProvider;
    if (_selectedImage != null) {
      imageProvider = FileImage(File(_selectedImage!.path));
    } else if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(user.photoUrl!);
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: buildSbmAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        titleText: 'Edit Profil',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // --- Profile Picture Edit ---
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: c.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.surface, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(c.isDark ? 0.2 : 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: imageProvider != null
                        ? Image(
                            image: imageProvider,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.withOpacity(0.3),
                                child: const Center(
                                  child: SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(strokeWidth: 3),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: c.textMuted,
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: c.textMuted,
                              ),
                            ),
                          ),
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A3A5C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- Form Edit Name ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nama Lengkap',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: c.textPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: c.surface,
                    prefixIcon: Icon(Icons.person_outline, color: c.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.primary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Fixed Info Fields (Email / Role)
            _buildReadOnlyField(context, 'Email', user.email.isEmpty ? user.phoneNumber : user.email, Icons.email_outlined),
            const SizedBox(height: 24),
            _buildReadOnlyField(context, 'Peran (Role)', user.role.toUpperCase(), Icons.badge_outlined),

            const SizedBox(height: 48),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3A5C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(BuildContext context, String label, String value, IconData icon) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: c.surfaceElevated, // Light grey indicating read-only
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: c.textMuted, size: 20),
              const SizedBox(width: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
