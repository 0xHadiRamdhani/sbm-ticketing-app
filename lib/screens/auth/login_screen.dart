import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/biometric_service.dart';
import '../../services/email_otp_service.dart';
import '../../utils/app_colors.dart';
import 'email_otp_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Controller tambahan untuk Register
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();
  String _selectedRole = 'student';

  final _formKey = GlobalKey<FormState>();

  bool _isObscure = true;
  bool _isLogin = true; // Mode saklar: Login atau Register
  bool _isSendingOtp = false;
  bool _biometricAvailable = false;

  final BiometricService _biometricService = BiometricService();

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
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final isEnabled = await _biometricService.isBiometricEnabled();
    if (mounted) setState(() => _biometricAvailable = isEnabled);
  }

  Future<void> _tryBiometricLogin() async {
    final credentials = await _biometricService.authenticateAndGetCredentials();
    if (credentials == null) return;
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.login(credentials['email']!, credentials['password']!);
    } catch (e) {
      if (!mounted) return;
      String msg = e.toString();
      if (msg.contains(']')) msg = msg.split(']').last.trim();
      _showSnackBar(msg, isError: true);
    }
  }

  @override
  void dispose() {
    _animController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_isLogin) {
      // ── MODE LOGIN ──
      try {
        await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } catch (e) {
        if (!mounted) return;
        String msg = e.toString();
        if (msg.contains(']')) msg = msg.split(']').last.trim();
        _showSnackBar(msg, isError: true);
      }
      return;
    }

    // ── MODE REGISTER: kirim OTP dulu ──
    setState(() => _isSendingOtp = true);
    try {
      final email = _emailController.text.trim();

      final otp = await EmailOtpService().sendOtp(
        email: email,
        name: _nameController.text.trim(),
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmailOtpScreen(
            email: email,
            password: _passwordController.text.trim(),
            name: _nameController.text.trim(),
            role: _selectedRole,
            department: _departmentController.text.trim(),
            sentOtp: otp,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      String msg = e.toString();
      if (msg.contains(']')) msg = msg.split(']').last.trim();
      _showSnackBar('Gagal mengirim OTP: $msg', isError: true);
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          // Background Gradient Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 340,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 30.0,
                  bottom: 24.0,
                ),
                child: _fadeAnimation == null
                    ? _buildContent() // Fallback if hot reloaded without restart
                    : FadeTransition(
                        opacity: _fadeAnimation!,
                        child: _buildContent(),
                      ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                final isDark = themeProvider.isDarkMode;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: Colors.white,
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
    );
  }

  Widget _buildContent() {
    final c = AppColors.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Animated Logo
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: c.isDark ? Colors.transparent : Colors.white,
              shape: BoxShape.circle,
              border: c.isDark
                  ? Border.all(
                      color: c.primary.withValues(alpha: 0.8),
                      width: 2.0,
                    )
                  : Border.all(
                      color: Colors.transparent,
                      width: 0,
                    ),
              boxShadow: [
                if (c.isDark)
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.5),
                    blurRadius: 24,
                    spreadRadius: 4,
                  )
                else
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Image.asset(
              key: ValueKey(c.isDark),
              'assets/sbm.png',
              fit: BoxFit.contain,
              color: c.isDark ? c.primary : null,
              colorBlendMode: c.isDark ? BlendMode.srcIn : null,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.confirmation_num_rounded,
                  size: 60,
                  color: c.isDark ? c.primary : const Color(0xFF1A3A5C),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'SBM ITB Support',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin
              ? 'Silakan masuk ke akun Anda'
              : 'Buat akun baru untuk memulai',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8)),
        ),
        const SizedBox(height: 32),

        // Form Container
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.of(context).surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(AppColors.of(context).isDark ? 0.2 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutBack,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isLogin) ...[
                    _buildLabel('Nama Lengkap'),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Masukkan nama Anda',
                      icon: Icons.person_outline_rounded,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Peran / Role'),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF64748B),
                      ),
                      // Removed prefixIcon to prevent text overlapping in Dropdown
                      decoration: _inputDecoration(hint: '', icon: null),
                      items: const [
                        DropdownMenuItem(
                          value: 'student',
                          child: Text('Mahasiswa'),
                        ),
                        DropdownMenuItem(
                          value: 'staff',
                          child: Text('Staf / Dosen'),
                        ),
                        DropdownMenuItem(
                          value: 'technician',
                          child: Text('Teknisi IT'),
                        ),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Departemen/Angkatan (Opsional)'),
                    _buildTextField(
                      controller: _departmentController,
                      hint: 'Contoh: Manajemen 2024',
                      icon: Icons.apartment_outlined,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildLabel('Alamat Email'),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'nama@example.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty)
                        return 'Email wajib diisi';
                      final emailRegex = RegExp(
                        r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$',
                      );
                      if (!emailRegex.hasMatch(val.trim()))
                        return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Kata Sandi'),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    style: TextStyle(
                      fontSize: 14,
                      color: c.textPrimary,
                    ),
                    decoration:
                        _inputDecoration(
                          hint: 'Masukkan kata sandi',
                          icon: Icons.lock_outline_rounded,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: c.textMuted,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _isObscure = !_isObscure),
                          ),
                        ),
                    validator: (val) {
                      if (val == null || val.isEmpty)
                        return 'Kata sandi wajib diisi';
                      if (!_isLogin && val.length < 6)
                        return 'Minimal 6 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      final busy = auth.isLoading || _isSendingOtp;
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: busy ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A3A5C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: busy
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  _isLogin
                                      ? 'Masuk Sekarang'
                                      : 'Daftar & Kirim OTP',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  // Tombol Biometrik (hanya muncul saat mode Login & biometrik diaktifkan)
                  if (_isLogin && _biometricAvailable) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Divider(color: c.divider)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('atau', style: TextStyle(color: c.textMuted, fontSize: 13)),
                        ),
                        Expanded(child: Divider(color: c.divider)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _tryBiometricLogin,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: c.isDark ? c.border : const Color(0xFFE2E8F0), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: c.isDark ? c.searchBar : const Color(0xFFF8FAFC),
                          foregroundColor: c.isDark ? Colors.white : const Color(0xFF1A3A5C),
                        ),
                        icon: Icon(Icons.fingerprint_rounded, color: c.isDark ? c.primary : const Color(0xFF1A3A5C), size: 26),
                        label: Text(
                          'Masuk dengan Sidik Jari / Face ID',
                          style: TextStyle(
                            color: c.isDark ? Colors.white : const Color(0xFF1A3A5C),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        TextButton(
          onPressed: _toggleMode,
          style: TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14.5,
                color: c.textSecondary,
                fontFamily: 'Inter',
              ),
              children: [
                TextSpan(
                  text: _isLogin ? 'Belum punya akun? ' : 'Sudah punya akun? ',
                ),
                TextSpan(
                  text: _isLogin ? 'Daftar sekarang' : 'Masuk di sini',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: c.isDark ? c.primary : const Color(0xFF1A3A5C),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLabel(String text) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: c.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final c = AppColors.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: 14, color: c.textPrimary),
      decoration: _inputDecoration(hint: hint, icon: icon),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData? icon,
  }) {
    final c = AppColors.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
      prefixIcon: icon != null
          ? Icon(icon, color: c.textMuted, size: 20)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: c.isDark ? c.searchBar : const Color(0xFFF8FAFC),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.isDark ? c.divider : const Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
