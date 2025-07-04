import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/auth_service.dart';
import '../models/user.dart';
import 'login_screen.dart';
// import 'admin_dashboard.dart'; // TEMPORARILY DISABLED
import 'bayi_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _waveController;
  late AnimationController _particleController;
  late AnimationController _progressController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _progressAnimation;
  late Animation<Color?> _backgroundAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _backgroundAnimation = ColorTween(
      begin: const Color(0xFF1A237E),
      end: const Color(0xFF2C3E50),
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    // Logo animasyonu
    _logoController.forward();

    // Wave animasyonu (tekrarlayan)
    _waveController.repeat();

    // 600ms bekle, sonra particle animasyonu
    await Future.delayed(const Duration(milliseconds: 600));
    _particleController.forward();

    // 800ms bekle, sonra metin animasyonu
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();

    // 1000ms bekle, sonra progress animasyonu
    await Future.delayed(const Duration(milliseconds: 1000));
    _progressController.forward();

    // 3.5 saniye bekle, sonra yönlendir
    await Future.delayed(const Duration(milliseconds: 3500));
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser != null) {
      // Kullanıcı giriş yapmış
      if (currentUser.role == UserRole.admin) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            // Admin dashboard is temporarily disabled, redirect to BayiDashboard as fallback
            pageBuilder: (context, animation, secondaryAnimation) =>
                const BayiDashboard(),
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const BayiDashboard(),
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } else {
      // Kullanıcı giriş yapmamış
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  Widget _buildFloatingParticle(
      double size, double left, double top, double delay, Color color) {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        double animationValue =
            (_particleAnimation.value + delay).clamp(0.0, 1.0);
        return Positioned(
          left: left,
          top: top + (math.sin(animationValue * math.pi * 2) * 20),
          child: Opacity(
            opacity: (math.sin(animationValue * math.pi) * 0.6).clamp(0.0, 1.0),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveBackground() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, double.infinity),
          painter: WavePainter(_waveAnimation.value),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _backgroundAnimation.value ?? const Color(0xFF1A237E),
                      const Color(0xFF34495E),
                      const Color(0xFF2C3E50),
                      const Color(0xFF1A252F),
                    ],
                  ),
                ),
              );
            },
          ),

          // Wave Background
          _buildWaveBackground(),

          // Floating Particles
          _buildFloatingParticle(8, 50, 150, 0.0, Colors.white),
          _buildFloatingParticle(12, 300, 200, 0.3, Colors.blue.shade200),
          _buildFloatingParticle(6, 100, 400, 0.6, Colors.white),
          _buildFloatingParticle(10, 280, 450, 0.2, Colors.indigo.shade200),
          _buildFloatingParticle(14, 200, 300, 0.8, Colors.white),
          _buildFloatingParticle(8, 350, 180, 0.5, Colors.blue.shade100),

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with professional animations
                AnimatedBuilder(
                  animation: Listenable.merge([_logoScale, _logoOpacity]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 30,
                                spreadRadius: 0,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: const Color(0xFF6A1B9A).withOpacity(0.2),
                                blurRadius: 50,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.casino_outlined,
                            size: 80,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),

                // Professional text animations
                AnimatedBuilder(
                  animation: _textAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textAnimation.value,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            // Professional title
                            Text(
                              'piyangox',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                letterSpacing: 4,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Professional subtitle
                            Text(
                              'PROFESYONEL PIYANGO YÖNETİMİ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w400,
                                letterSpacing: 2,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Version info
                            Text(
                              'v1.0.0',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.5),
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 80),

                // Professional progress indicator
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _progressAnimation.value,
                      child: Column(
                        children: [
                          // Custom progress bar
                          Container(
                            width: 200,
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  width: 200 * _progressAnimation.value,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6A1B9A),
                                        Color(0xFF8E24AA),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            'Yükleniyor...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 100),

                // Professional feature list
                AnimatedBuilder(
                  animation: _textAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textAnimation.value * 0.6,
                      child: Column(
                        children: [
                          _buildProfessionalFeature('Yönetim Sistemi', 0.0),
                          const SizedBox(height: 12),
                          _buildProfessionalFeature('Bilet Takip', 0.2),
                          const SizedBox(height: 12),
                          _buildProfessionalFeature('Finansal Kontrol', 0.4),
                          const SizedBox(height: 12),
                          _buildProfessionalFeature('Güvenli Giriş', 0.6),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalFeature(String text, double delay) {
    return AnimatedBuilder(
      animation: _textAnimation,
      builder: (context, child) {
        double opacity = (_textAnimation.value - delay).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _waveController.dispose();
    _particleController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Create subtle wave pattern
    for (int i = 0; i <= 3; i++) {
      path.reset();

      double waveHeight = 40.0;
      double waveLength = size.width / 2;
      double dy = size.height * 0.7 + (i * 30);

      path.moveTo(0, dy);

      for (double x = 0; x <= size.width; x += 1) {
        double y = dy +
            math.sin(((x / waveLength) + (animationValue * 2 * math.pi)) +
                    (i * 0.5)) *
                waveHeight *
                (1 - i * 0.2);
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      paint.color = Colors.white.withOpacity(0.03 - (i * 0.008));
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
