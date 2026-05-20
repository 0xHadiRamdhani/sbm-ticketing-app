import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../services/biometric_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_notifications.dart';
import 'about_screen.dart';
import 'help_center_screen.dart';
import 'privacy_policy_screen.dart';
import 'shared/ticket_card.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'my_devices_screen.dart';
import 'terms_conditions_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;
  bool _biometricSupported = false;
  String _cacheSizeStr = '0.0 MB';

  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _checkBiometric();
    _calculateCacheSize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final themeProvider = context.read<ThemeProvider>();
      setState(() => _darkModeEnabled = themeProvider.isDarkMode);
    });
  }

  Future<void> _checkBiometric() async {
    bool supported = await _biometricService.isBiometricAvailable();
    bool enabled = await _biometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricSupported = supported;
        _biometricEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final c = AppColors.of(context);

    if (user?.email == null || user!.email!.isEmpty) {
      AppNotifications.showNotification(
        context,
        title: 'Biometrik',
        message: 'Hanya pengguna email yang dapat menggunakan fitur biometrik.',
        isError: true,
      );
      return;
    }

    if (value) {
      // Minta kata sandi untuk disimpan secara aman
      final passwordController = TextEditingController();
      bool? confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Aktifkan Biometrik'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Masukkan kata sandi Anda saat ini untuk mengaktifkan login menggunakan sidik jari/Face ID.',
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: passwordController,
                placeholder: 'Kata Sandi',
                obscureText: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: c.isDark
                      ? const Color(0xFF253347)
                      : CupertinoColors.extraLightBackgroundGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                style: TextStyle(color: c.isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      );

      if (confirmed == true && passwordController.text.isNotEmpty) {
        await _biometricService.saveCredentials(
          user.email!,
          passwordController.text,
        );
        await _biometricService.setBiometricEnabled(true);
        setState(() => _biometricEnabled = true);
        if (mounted) {
          AppNotifications.showNotification(
            context,
            title: 'Sukses',
            message: 'Login biometrik diaktifkan.',
            isError: false,
          );
        }
      }
    } else {
      await _biometricService.setBiometricEnabled(false);
      setState(() => _biometricEnabled = false);
      if (mounted) {
        AppNotifications.showNotification(
          context,
          title: 'Sukses',
          message: 'Login biometrik dinonaktifkan.',
          isError: false,
        );
      }
    }
  }

  void _showLanguagePicker(BuildContext context, LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final c = AppColors.of(ctx);
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.translate(
                  'Pilih Bahasa ( belum sempurna )',
                  'Select Language',
                ),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Text('🇮🇩', style: TextStyle(fontSize: 24)),
                title: Text(
                  'Bahasa Indonesia',
                  style: TextStyle(color: c.textPrimary),
                ),
                trailing: !lang.isEnglish
                    ? Icon(Icons.check_circle_rounded, color: c.primary)
                    : null,
                onTap: () {
                  lang.toggleLanguage('id');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                title: Text('English', style: TextStyle(color: c.textPrimary)),
                trailing: lang.isEnglish
                    ? Icon(Icons.check_circle_rounded, color: c.primary)
                    : null,
                onTap: () {
                  lang.toggleLanguage('en');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showComingSoon() {
    AppNotifications.showNotification(
      context,
      title: 'Info',
      message: 'Fitur ini sedang dalam pengembangan.',
      isError: false,
    );
  }

  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int tempDirSize = await _getDirSize(tempDir);
      if (mounted) {
        setState(() {
          _cacheSizeStr = _formatSize(tempDirSize);
        });
      }
    } catch (e) {
      debugPrint("Error calculating cache size: $e");
    }
  }

  Future<int> _getDirSize(Directory dir) async {
    int size = 0;
    try {
      if (await dir.exists()) {
        await for (final FileSystemEntity entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (e) {
      debugPrint("Error getting directory size: $e");
    }
    return size;
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0.0 MB';
    double mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (final FileSystemEntity entity in tempDir.list(
          recursive: true,
          followLinks: false,
        )) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } catch (e) {
            // Ignore failure to delete locked files
          }
        }
      }
      await _calculateCacheSize();
      if (mounted) {
        AppNotifications.showNotification(
          context,
          title: 'Sukses',
          message: context.read<LanguageProvider>().translate(
            'Cache berhasil dibersihkan.',
            'Cache cleared successfully.',
          ),
          isError: false,
        );
      }
    } catch (e) {
      debugPrint("Error clearing cache: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: c.background,

      // ── AppBar ───────────────────────────────────────────────────────
      appBar: buildSbmAppBar(
        context: context,
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        titleText: lang.translate('Pengaturan', 'Settings'),
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          await auth.refreshUserData();
          setState(() {}); // Trigger rebuild
          AppNotifications.showNotification(
            context,
            title: 'Sukses',
            message: lang.translate(
              'Data berhasil diperbarui',
              'Data updated successfully',
            ),
            isError: false,
          );
        },
        color: c.primary,
        backgroundColor: c.surface,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            // ── Profil Card ────────────────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A3A5C), Color(0xFF11273E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A3A5C).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                        image: (user?.photoUrl?.isNotEmpty == true)
                            ? DecorationImage(
                                image: NetworkImage(user!.photoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (user?.photoUrl?.isEmpty ?? true)
                          ? Center(
                              child: Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Pengguna',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '-',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _roleLabel(
                                user?.role ?? '',
                                context.read<LanguageProvider>(),
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Akun & Keamanan ─────────────────────────────────────────────
            _SectionLabel(
              lang.translate('Akun & Keamanan', 'Account & Security'),
            ),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _NavTile(
                  icon: Icons.lock_outline_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  bgColor: const Color(0xFFFEF3C7),
                  label: lang.translate('Ubah Kata Sandi', 'Change Password'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  ),
                ),
                const _TileDivider(),
                if (_biometricSupported) ...[
                  _SwitchTile(
                    icon: Icons.fingerprint_rounded,
                    iconColor: const Color(0xFF10B981),
                    bgColor: const Color(0xFFD1FAE5),
                    label: lang.translate('Login Biometrik', 'Biometric Login'),
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                  ),
                  const _TileDivider(),
                ],
                _NavTile(
                  icon: Icons.devices_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  bgColor: const Color(0xFFEDE9FE),
                  label: lang.translate('Perangkat Aktif', 'Active Devices'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyDevicesScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Preferensi ──────────────────────────────────────────────────
            _SectionLabel(
              lang.translate('Preferensi Aplikasi', 'App Preferences'),
            ),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _SwitchTile(
                  icon: Icons.notifications_none_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  bgColor: const Color(0xFFDBEAFE),
                  label: lang.translate(
                    'Pemberitahuan Push',
                    'Push Notifications',
                  ),
                  value: _notificationsEnabled,
                  onChanged: (v) {
                    setState(() => _notificationsEnabled = v);
                    AppNotifications.showNotification(
                      context,
                      title: 'Info',
                      message: v
                          ? lang.translate(
                              'Pemberitahuan diaktifkan',
                              'Notifications enabled',
                            )
                          : lang.translate(
                              'Pemberitahuan dimatikan',
                              'Notifications disabled',
                            ),
                      isError: false,
                    );
                  },
                ),
                const _TileDivider(),
                _SwitchTile(
                  icon: Icons.dark_mode_outlined,
                  iconColor: const Color(0xFF6366F1),
                  bgColor: const Color(0xFFE0E7FF),
                  label: lang.translate(
                    'Tema Gelap ( Light Mode Recommended )',
                    'Dark Mode ( Light Mode Recommended )',
                  ),
                  value: _darkModeEnabled,
                  onChanged: (v) async {
                    setState(() => _darkModeEnabled = v);
                    await context.read<ThemeProvider>().toggleTheme(v);
                  },
                ),
                const _TileDivider(),
                _NavTile(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF06B6D4),
                  bgColor: const Color(0xFFCFFAFE),
                  label: lang.translate('Bahasa', 'Language'),
                  trailingText: lang.isEnglish ? 'English' : 'Indonesia',
                  onTap: () => _showLanguagePicker(context, lang),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Data & Penyimpanan ──────────────────────────────────────────
            _SectionLabel(
              lang.translate('Data & Penyimpanan', 'Data & Storage'),
            ),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _NavTile(
                  icon: Icons.folder_delete_outlined,
                  iconColor: const Color(0xFFEC4899),
                  bgColor: const Color(0xFFFCE7F3),
                  label: lang.translate('Bersihkan Cache', 'Clear Cache'),
                  trailingText: _cacheSizeStr,
                  onTap: _clearCache,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Bantuan & Info ─────────────────────────────────────────────
            _SectionLabel(
              lang.translate('Bantuan & Informasi', 'Help & Information'),
            ),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _NavTile(
                  icon: Icons.help_outline_rounded,
                  iconColor: const Color(0xFF14B8A6),
                  bgColor: const Color(0xFFCCFBF1),
                  label: lang.translate('Pusat Bantuan', 'Help Center'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HelpCenterScreen()),
                  ),
                ),
                const _TileDivider(),
                _NavTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: const Color(0xFF64748B),
                  bgColor: const Color(0xFFF1F5F9),
                  label: lang.translate('Kebijakan Privasi', 'Privacy Policy'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  ),
                ),
                const _TileDivider(),
                _NavTile(
                  icon: Icons.article_outlined,
                  iconColor: const Color(0xFF64748B),
                  bgColor: const Color(0xFFF1F5F9),
                  label: lang.translate(
                    'Syarat & Ketentuan',
                    'Terms & Conditions',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsConditionsScreen(),
                    ),
                  ),
                ),
                const _TileDivider(),
                _NavTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF1A3A5C),
                  bgColor: const Color(0xFFE0E8F0),
                  label: lang.translate(
                    'Tentang Aplikasi',
                    'About Application',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Logout ─────────────────────────────────────────────────────
            GestureDetector(
              onTap: () => _confirmLogout(context, auth, lang),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.red.shade600,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      lang.translate('Keluar Akun', 'Log Out'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── App version ────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Image.asset('assets/itb.png', width: 54, height: 54),
                  const SizedBox(height: 12),
                  const Text(
                    'SBM ITB Support',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Versi 2.0.1 (Build 42)',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role, LanguageProvider lang) {
    switch (role) {
      case 'student':
        return lang.translate('Mahasiswa', 'Student');
      case 'staff':
        return lang.translate('Staf / Dosen', 'Staff / Lecturer');
      case 'technician':
        return lang.translate('Teknisi', 'Technician');
      case 'admin':
        return 'Admin';
      default:
        return role;
    }
  }

  void _confirmLogout(
    BuildContext ctx,
    AuthProvider auth,
    LanguageProvider lang,
  ) async {
    final confirmed = await AppNotifications.showConfirmDialog(
      ctx,
      title: lang.translate('Keluar Akun?', 'Log Out?'),
      message: lang.translate(
        'Apakah Anda yakin ingin keluar dari akun ini? Anda harus masuk kembali untuk menggunakan aplikasi.',
        'Are you sure you want to log out from your account? You will need to log in again to use the application.',
      ),
      confirmLabel: lang.translate('Keluar', 'Log Out'),
      cancelLabel: lang.translate('Batal', 'Cancel'),
      isDestructive: true,
    );
    if (confirmed) {
      auth.logout();
      Navigator.of(ctx).popUntil((route) => route.isFirst);
    }
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: c.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(c.isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final String? trailingText;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    this.trailingText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText!,
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.chevron_right_rounded, color: c.textMuted, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: c.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: c.border,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Divider(
      height: 1,
      thickness: 1,
      indent: 72,
      endIndent: 16,
      color: c.divider,
    );
  }
}
