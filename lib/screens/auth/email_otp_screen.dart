import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/email_otp_service.dart';

class EmailOtpScreen extends StatefulWidget {
  final String email;
  final String password;
  final String name;
  final String role;
  final String department;
  final String sentOtp;

  const EmailOtpScreen({
    Key? key,
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    required this.department,
    required this.sentOtp,
  }) : super(key: key);

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen>
    with SingleTickerProviderStateMixin {
  // 6 field OTP
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  String _currentOtp = '';
  int _resendCountdown = 60;
  Timer? _countdownTimer;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _currentOtp = widget.sentOtp;
    _startCountdown();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _countdownTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown == 0) {
        t.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  String get _enteredOtp =>
      _controllers.map((c) => c.text).join();

  void _onOtpDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    // Auto-verify when all 6 digits entered
    if (_enteredOtp.length == 6) {
      _verify();
    }
  }

  Future<void> _verify() async {
    if (_isVerifying) return;
    final entered = _enteredOtp;
    if (entered.length < 6) {
      _showError('Masukkan 6 digit kode OTP');
      return;
    }

    if (entered != _currentOtp) {
      _shakeController.forward(from: 0);
      _showError('Kode OTP salah. Periksa kembali email Anda.');
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.register(
        widget.email,
        widget.password,
        widget.name,
        widget.role,
        widget.department,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      // Registrasi berhasil, AuthWrapper berubah ke Dashboard, tapi kita harus pop layar OTP ini
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().toLowerCase();

      // Tangani: email sudah terdaftar di Firebase Auth
      if (raw.contains('email-already-in-use') ||
          raw.contains('email already in use')) {
        _loginExistingAccount();
      } else {
        String msg = e.toString();
        if (msg.contains(']')) msg = msg.split(']').last.trim();
        _showError(msg);
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  /// Login otomatis saat email sudah terdaftar di Firebase Auth
  Future<void> _loginExistingAccount() async {
    if (!mounted) return;

    // Tampilkan loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Email sudah terdaftar, sedang masuk...'),
        ]),
        backgroundColor: Color(0xFF1A3A5C),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(widget.email, widget.password);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      // Login berhasil, pop layar OTP untuk melihat Dashboard
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      // Password salah — minta user login manual
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Email sudah terdaftar. Kata sandi tidak cocok, silakan login manual.',
              ),
            ),
          ]),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
      // Segera kembali ke halaman login tanpa menunggu
      Navigator.of(context).pop();
    }
  }

  Future<void> _resendOtp() async {
    if (_isResending || _resendCountdown > 0) return;
    setState(() => _isResending = true);
    try {
      final newOtp = await EmailOtpService().sendOtp(
        email: widget.email,
        name: widget.name,
      );
      setState(() => _currentOtp = newOtp);
      _startCountdown();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode OTP baru telah dikirim ke email Anda.'),
          backgroundColor: Color(0xFF1A3A5C),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Gagal mengirim ulang OTP: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maskedEmail = _maskEmail(widget.email);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A3A5C)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ilustrasi
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A3A5C), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A3A5C).withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Verifikasi Email',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A5C),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Kami telah mengirimkan kode 6 digit ke',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    maskedEmail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A5C),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // OTP Input Fields
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      final offset = _shakeController.isAnimating
                          ? (8 * (0.5 - (_shakeAnimation.value - 0.5).abs()) * 2)
                              .clamp(-8.0, 8.0)
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(offset * 4, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) {
                        return SizedBox(
                          width: 44,
                          height: 56,
                          child: TextFormField(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3A5C),
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF1A3A5C), width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1), width: 1.5),
                              ),
                            ),
                            onChanged: (val) => _onOtpDigitChanged(i, val),
                            onTap: () {
                              _controllers[i].selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _controllers[i].text.length,
                              );
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Tombol Verifikasi
                  SizedBox(
                    width: double.infinity,
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        final busy = _isVerifying || auth.isLoading;
                        return ElevatedButton(
                          onPressed: busy ? null : _verify,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF1A3A5C),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                              : const Text(
                                  'Verifikasi & Buat Akun',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Kirim Ulang
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Tidak menerima kode? ',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                      _resendCountdown > 0
                          ? Text(
                              'Kirim ulang (${_resendCountdown}s)',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : GestureDetector(
                              onTap: _isResending ? null : _resendOtp,
                              child: _isResending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF1A3A5C),
                                      ),
                                    )
                                  : const Text(
                                      'Kirim Ulang',
                                      style: TextStyle(
                                        color: Color(0xFF1A3A5C),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '⚠️ Kode OTP berlaku selama 10 menit',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 3) return '***@$domain';
    final visible = local.substring(0, 3);
    final masked = '*' * (local.length - 3);
    return '$visible$masked@$domain';
  }
}
