// lib/screens/splash_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ──────────────────────────────────────────────────
  late AnimationController _bgController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _particleController;

  // ── Animations ─────────────────────────────────────────────────────────────
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoGlow;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _dividerWidth;
  late Animation<double> _progressValue;
  late Animation<double> _bgOpacity;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Background
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bgOpacity = CurvedAnimation(parent: _bgController, curve: Curves.easeIn);

    // Particle / ring rotation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Logo
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _logoGlow = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    // Text
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );
    _titleOpacity = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );
    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _textController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _subtitleOpacity = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
    );
    _dividerWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
      ),
    );

    // Progress
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _progressValue = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _startSequence() async {
    // 1. Fade-in background
    await _bgController.forward();

    // 2. Bounce-in logo
    await Future.delayed(const Duration(milliseconds: 100));
    await _logoController.forward();

    // 3. Slide-up text
    await Future.delayed(const Duration(milliseconds: 200));
    _textController.forward();

    // 4. Progress bar
    await Future.delayed(const Duration(milliseconds: 300));
    await _progressController.forward();

    // 5. Navigate
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => DashboardWrapper(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: FadeTransition(
        opacity: _bgOpacity,
        child: Stack(
          children: [
            // ── Gradient Background ───────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A1628),
                    Color(0xFF0D2040),
                    Color(0xFF0A1628),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // ── Rotating Ring Decoration ──────────────────────────────────
            Positioned(
              top: size.height * 0.15,
              left: size.width * 0.5 - 160,
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (_, __) {
                  return Transform.rotate(
                    angle: _particleController.value * 2 * math.pi,
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2563EB).withOpacity(0.08),
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: size.height * 0.15 + 30,
              left: size.width * 0.5 - 130,
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (_, __) {
                  return Transform.rotate(
                    angle: -_particleController.value * 2 * math.pi * 0.7,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF60A5FA).withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Glow orb behind logo ──────────────────────────────────────
            Positioned(
              top: size.height * 0.17,
              left: size.width * 0.5 - 110,
              child: AnimatedBuilder(
                animation: _logoGlow,
                builder: (_, __) {
                  return Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF1A4DA8,
                          ).withOpacity(0.45 * _logoGlow.value),
                          blurRadius: 90,
                          spreadRadius: 30,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Main Content ──────────────────────────────────────────────
            Column(
              children: [
                SizedBox(height: size.height * 0.22),

                // ITB Logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (_, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 180,
                    height: 180,
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      // ITB biru solid — sama persis dengan warna latar logo
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF1A4DA8),
                          blurRadius: 0,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        // White solid stroke ring
                        color: Colors.transparent,
                      ),
                      child: Image.asset('assets/itb.png', fit: BoxFit.contain),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Title
                ClipRect(
                  child: SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleOpacity,
                      child: const Text(
                        'SBM ITB',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 3,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Animated divider
                AnimatedBuilder(
                  animation: _dividerWidth,
                  builder: (_, __) {
                    return Container(
                      width: 200 * _dividerWidth.value,
                      height: 1.5,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF60A5FA),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // Subtitle
                ClipRect(
                  child: SlideTransition(
                    position: _subtitleSlide,
                    child: FadeTransition(
                      opacity: _subtitleOpacity,
                      child: const Text(
                        'Ticketing & Support System',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF93C5FD),
                          letterSpacing: 0.5,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                ClipRect(
                  child: FadeTransition(
                    opacity: _subtitleOpacity,
                    child: const Text(
                      'School of Business & Management',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.3,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _progressValue,
                        builder: (_, __) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _progressValue.value,
                              backgroundColor: Colors.white.withOpacity(0.08),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF3B82F6),
                              ),
                              minHeight: 3,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      FadeTransition(
                        opacity: _titleOpacity,
                        child: const Text(
                          'Memuat aplikasi...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF475569),
                            letterSpacing: 0.5,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Footer
                FadeTransition(
                  opacity: _titleOpacity,
                  child: const Text(
                    'Institut Teknologi Bandung · 1920',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF334155),
                      letterSpacing: 1,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
