import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_colors.dart';
import 'shared/ticket_card.dart';
import '../utils/app_notifications.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.changePassword(
        _currentPasswordController.text, 
        _newPasswordController.text,
      );
      
      if (!mounted) return;
      AppNotifications.showNotification(
        context,
        title: 'Sukses',
        message: 'Kata sandi berhasil diubah.',
        isError: false,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showNotification(
        context,
        title: 'Gagal',
        message: e.toString().contains('wrong-password') 
            ? 'Kata sandi saat ini salah.' 
            : 'Gagal mengubah kata sandi. Pastikan Anda masuk menggunakan email.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: c.background,
      appBar: buildSbmAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        titleText: lang.translate('Ubah Kata Sandi', 'Change Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(c.isDark ? 0.15 : 0.04),
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
                Text(
                  lang.translate(
                    'Silakan masukkan kata sandi Anda saat ini dan kata sandi baru untuk akun Anda.',
                    'Please enter your current password and a new password for your account.',
                  ),
                  style: TextStyle(color: c.textSecondary, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 24),
                
                // Kata sandi saat ini
                _buildPasswordField(
                  controller: _currentPasswordController,
                  label: lang.translate('Kata Sandi Saat Ini', 'Current Password'),
                  obscureText: _obscureCurrent,
                  onToggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  validator: (v) => v!.isEmpty ? lang.translate('Harap isi kata sandi saat ini', 'Please enter your current password') : null,
                ),
                const SizedBox(height: 20),
                
                // Kata sandi baru
                _buildPasswordField(
                  controller: _newPasswordController,
                  label: lang.translate('Kata Sandi Baru', 'New Password'),
                  obscureText: _obscureNew,
                  onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                  validator: (v) {
                    if (v!.isEmpty) return lang.translate('Harap isi kata sandi baru', 'Please enter a new password');
                    if (v.length < 6) return lang.translate('Minimal 6 karakter', 'Minimum 6 characters');
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Konfirmasi kata sandi baru
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: lang.translate('Konfirmasi Kata Sandi Baru', 'Confirm New Password'),
                  obscureText: _obscureConfirm,
                  onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) {
                    if (v!.isEmpty) return lang.translate('Harap konfirmasi kata sandi baru', 'Please confirm your new password');
                    if (v != _newPasswordController.text) return lang.translate('Kata sandi tidak cocok', 'Passwords do not match');
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Tombol Simpan
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3A5C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading 
                        ? const SizedBox(
                            width: 24, height: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            lang.translate('Simpan Kata Sandi', 'Save Password'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
  }) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: c.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          style: TextStyle(fontSize: 15, color: c.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: c.surfaceElevated,
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
              borderSide: BorderSide(color: c.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: c.textMuted,
                size: 20,
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ),
      ],
    );
  }
}

