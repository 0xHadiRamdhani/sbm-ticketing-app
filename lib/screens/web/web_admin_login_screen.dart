import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_notifications.dart';

/// Web Admin Login Screen - Khusus untuk admin login di web
class WebAdminLoginScreen extends StatefulWidget {
  const WebAdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<WebAdminLoginScreen> createState() => _WebAdminLoginScreenState();
}

class _WebAdminLoginScreenState extends State<WebAdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isObscure = true;
  bool _isLoading = false;

  AnimationController? _animController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController!,
      curve: Curves.easeOut,
    );
    _animController!.forward();
  }

  @override
  void dispose() {
    _animController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Check if user is admin
      if (authProvider.user?.role != 'admin') {
        await authProvider.logout();
        if (!mounted) return;
        AppNotifications.showNotification(
          context,
          title: 'Akses Ditolak',
          message: 'Hanya admin yang dapat mengakses halaman ini.',
          isError: true,
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      String msg = e.toString();
      if (msg.contains(']')) msg = msg.split(']').last.trim();
      AppNotifications.showNotification(
        context,
        title: 'Login Gagal',
        message: msg,
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    
    return Scaffold(
      backgroundColor: c.background,
      body: Row(
        children: [
          // Left Panel: Branding & Illustration
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -50,
                    left: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80,
                    right: -80,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  
                  // Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with shield badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 32,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(28),
                              child: Image.asset(
                                'assets/sbm.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.confirmation_num_rounded,
                                    size: 80,
                                    color: Color(0xFF1A3A5C),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A3A5C),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.shield_outlined,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                        const Text(
                          'SBM ITB Admin',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Panel Administrasi Sistem',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.85),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.security_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Akses Terbatas - Admin Only',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right Panel: Login Form
          Expanded(
            flex: 4,
            child: Container(
              color: c.background,
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 32,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: _fadeAnimation == null
                            ? _buildFormContent(c)
                            : FadeTransition(
                                opacity: _fadeAnimation!,
                                child: _buildFormContent(c),
                              ),
                      ),
                    ),
                  ),
                  
                  // Theme toggle button (top right)
                  Positioned(
                    top: 24,
                    right: 24,
                    child: Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        final isDark = themeProvider.isDarkMode;
                        return Container(
                          decoration: BoxDecoration(
                            color: c.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: c.border,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  c.isDark ? 0.2 : 0.06,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              isDark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              color: c.textSecondary,
                              size: 22,
                            ),
                            onPressed: () => themeProvider.toggleTheme(!isDark),
                            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(AppColors c) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3A5C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Color(0xFF1A3A5C),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Login',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Masukkan kredensial admin Anda',
                      style: TextStyle(
                        fontSize: 14,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          
          // Email Field
          Text(
            'Email Admin',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontSize: 15, color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'admin@sbm.itb.ac.id',
              hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: c.textMuted,
                size: 22,
              ),
              filled: true,
              fillColor: c.searchBar,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: c.border, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF1A3A5C),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Email wajib diisi';
              final emailRegex = RegExp(
                r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$',
              );
              if (!emailRegex.hasMatch(val.trim())) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Password Field
          Text(
            'Password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _isObscure,
            style: TextStyle(fontSize: 15, color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'Masukkan password admin',
              hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: c.textMuted,
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: c.textMuted,
                  size: 22,
                ),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              ),
              filled: true,
              fillColor: c.searchBar,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: c.border, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF1A3A5C),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Password wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 36),

          // Login Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A5C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor:
                    const Color(0xFF1A3A5C).withOpacity(0.5),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.login_rounded, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Masuk ke Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Info Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFCD34D),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFD97706),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hanya akun dengan role Admin yang dapat mengakses halaman ini.',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF92400E),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
