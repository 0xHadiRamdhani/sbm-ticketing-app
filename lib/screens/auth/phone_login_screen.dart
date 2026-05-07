import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isNewUser = false;
  // ── Step 1: phone input ──────────────────────────────────────────────────
  String _completePhoneNumber = '';
  final _phoneFormKey = GlobalKey<FormState>();

  // ── Step 2: OTP input ────────────────────────────────────────────────────
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  // ── Step 3: new-user info ────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _infoFormKey = GlobalKey<FormState>();
  String _selectedRole = 'student';

  // ── State ─────────────────────────────────────────────────────────────────
  int _step = 1; // 1 = phone, 2 = otp, 3 = user-info (new user)
  String _verificationId = '';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _nameController.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _nextStep(int step) {
    _animCtrl.forward(from: 0);
    setState(() => _step = step);
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Step 1: kirim OTP ────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    if (_completePhoneNumber.isEmpty) {
      _showError('Masukkan nomor telepon terlebih dahulu');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.verifyPhoneNumber(
      phoneNumber: _completePhoneNumber,
      onCodeSent: (vid) {
        setState(() => _verificationId = vid);
        _nextStep(2);
      },
      onError: _showError,
    );
  }

  // ─── Step 2: verifikasi OTP ───────────────────────────────────────────────

  Future<void> _verifyOtp() async {
    if (_otpCode.length < 6) {
      _showError('Masukkan 6 digit kode OTP');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Coba sign-in, cek apakah user baru
    try {
      authProvider.isLoading; // trigger rebuild via Consumer
      await authProvider.signInWithOtp(
        verificationId: _verificationId,
        smsCode: _otpCode,
      );

      // Jika user baru (tidak ada nama di Firestore), minta data tambahan
      final user = authProvider.user;
      if (user != null && (user.name == user.email || user.name.isEmpty)) {
        setState(() => _isNewUser = true);
        _nextStep(3);
      }
      // Jika user lama, auth wrapper otomatis navigasi ke dashboard
    } catch (e) {
      String msg = e.toString();
      if (msg.contains(']')) msg = msg.split(']').last.trim();
      _showError(msg);
    }
  }

  // ─── Step 3: simpan info user baru ───────────────────────────────────────

  Future<void> _saveUserInfo() async {
    if (!_infoFormKey.currentState!.validate()) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.signInWithOtp(
        verificationId: _verificationId,
        smsCode: _otpCode,
        name: _nameController.text.trim(),
        role: _selectedRole,
      );
    } catch (e) {
      String msg = e.toString();
      if (msg.contains(']')) msg = msg.split(']').last.trim();
      _showError(msg);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: const Color(0xFF1A3A6B)),
        title: Text(
          'Masuk via Telepon',
          style: TextStyle(
            color: const Color(0xFF1A3A6B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProgressIndicator(),
                const SizedBox(height: 32),
                if (_step == 1) _buildPhoneStep(),
                if (_step == 2) _buildOtpStep(),
                if (_step == 3) _buildUserInfoStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Progress indicator ────────────────────────────────────────────────────

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(3, (i) {
        final active = i + 1 <= _step;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF1A3A6B) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }

  // ── Step 1: Phone number ──────────────────────────────────────────────────

  Widget _buildPhoneStep() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader(
            icon: Icons.phone_android_rounded,
            title: 'Nomor Telepon',
            subtitle: 'Kami akan mengirimkan kode OTP ke nomor Anda.',
          ),
          const SizedBox(height: 28),
          IntlPhoneField(
            decoration: InputDecoration(
              labelText: 'Nomor Telepon',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1A3A6B),
                  width: 2,
                ),
              ),
            ),
            initialCountryCode: 'ID',
            keyboardType: TextInputType.phone,
            onChanged: (phone) {
              _completePhoneNumber = phone.completeNumber;
            },
            validator: (val) {
              if (val == null || val.number.isEmpty) {
                return 'Nomor tidak boleh kosong';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          Consumer<AuthProvider>(
            builder: (_, auth, __) => _buildPrimaryButton(
              label: 'Kirim Kode OTP',
              icon: Icons.send_rounded,
              isLoading: auth.isLoading,
              onPressed: _sendOtp,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: OTP ───────────────────────────────────────────────────────────

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          icon: Icons.sms_rounded,
          title: 'Kode OTP',
          subtitle:
              'Masukkan 6 digit kode yang dikirim ke $_completePhoneNumber',
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _buildOtpBox(i)),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _sendOtp,
            child: const Text(
              'Kirim ulang OTP',
              style: TextStyle(color: Color(0xFF1A3A6B)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Consumer<AuthProvider>(
          builder: (_, auth, __) => _buildPrimaryButton(
            label: 'Verifikasi',
            icon: Icons.verified_rounded,
            isLoading: auth.isLoading,
            onPressed: _verifyOtp,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A3A6B),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1A3A6B), width: 2),
          ),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  // ── Step 3: User info (new user) ──────────────────────────────────────────

  Widget _buildUserInfoStep() {
    return Form(
      key: _infoFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader(
            icon: Icons.person_add_rounded,
            title: 'Lengkapi Profil',
            subtitle:
                'Nomor Anda berhasil diverifikasi. Silakan isi data diri.',
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nama Lengkap',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (val) =>
                val == null || val.isEmpty ? 'Nama tidak boleh kosong' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: InputDecoration(
              labelText: 'Peran / Role',
              prefixIcon: const Icon(Icons.badge_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'student', child: Text('Mahasiswa')),
              DropdownMenuItem(value: 'staff', child: Text('Staf / Dosen')),
              DropdownMenuItem(value: 'technician', child: Text('Teknisi IT')),
            ],
            onChanged: (val) => setState(() => _selectedRole = val!),
          ),
          const SizedBox(height: 28),
          Consumer<AuthProvider>(
            builder: (_, auth, __) => _buildPrimaryButton(
              label: 'Simpan & Masuk',
              icon: Icons.login_rounded,
              isLoading: auth.isLoading,
              onPressed: _saveUserInfo,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────────

  Widget _buildStepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1A3A6B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF1A3A6B), size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A3A6B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 20),
      label: Text(
        isLoading ? 'Harap tunggu...' : label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A3A6B),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF1A3A6B).withOpacity(0.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
