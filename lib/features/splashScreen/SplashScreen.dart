import 'package:flutter/material.dart';
import 'dart:math' as math;

class RentifySplashScreen extends StatefulWidget {
  const RentifySplashScreen({super.key});

  @override
  State<RentifySplashScreen> createState() => _RentifySplashScreenState();
}

class _RentifySplashScreenState extends State<RentifySplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _illustrationController;
  late AnimationController _textController;
  late AnimationController _loaderController;
  late AnimationController _fadeController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<Offset> _illustrationSlide;
  late Animation<double> _illustrationFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Illustration animation
    _illustrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _illustrationSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _illustrationController, curve: Curves.easeOutCubic),
    );
    _illustrationFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _illustrationController, curve: Curves.easeOut),
    );

    // Text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Loader animation
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 350));
    _illustrationController.forward();
    await Future.delayed(const Duration(milliseconds: 280));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _illustrationController.dispose();
    _textController.dispose();
    _loaderController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF8F9FC),
              Color(0xFFF3F4F8),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: topPadding > 0 ? 8 : 24),

              // ========== LOGO ==========
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Column(
                    children: [
                      // Logo mark
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF6C63FF),
                              Color(0xFF00C2FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C63FF).withOpacity(0.28),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // House
                            const Icon(
                              Icons.home_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            // Location pin overlay
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF22C55E).withOpacity(0.4),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // App name
                      const Text(
                        'Rentify',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                          letterSpacing: -0.4,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // ========== ILLUSTRATION ==========
              FadeTransition(
                opacity: _illustrationFade,
                child: SlideTransition(
                  position: _illustrationSlide,
                  child: SizedBox(
                    height: size.height * 0.32,
                    width: size.width * 0.88,
                    child: CustomPaint(
                      painter: _SplashIllustrationPainter(),
                      size: Size(size.width * 0.88, size.height * 0.32),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // ========== WELCOME TEXT ==========
              FadeTransition(
                opacity: _textFade,
                child: SlideTransition(
                  position: _textSlide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const Text(
                          'Find Your\nPerfect Home',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            height: 1.15,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Discover apartments, rooms, villas, and studios near you.\nBook easily and connect directly with property owners.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF111827).withOpacity(0.55),
                            height: 1.55,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // ========== LOADING ==========
              FadeTransition(
                opacity: _loaderFade,
                child: Column(
                  children: [
                    // Premium loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: AnimatedBuilder(
                        animation: _loaderController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _PremiumLoaderPainter(
                              progress: _loaderController.value,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading your experience...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF111827).withOpacity(0.4),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: bottomPadding > 0 ? bottomPadding + 16 : 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== PREMIUM LOADER ==========
class _PremiumLoaderPainter extends CustomPainter {
  final double progress;

  _PremiumLoaderPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFF6C63FF).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active arc
    final sweep = 0.65 * 2 * math.pi;
    final start = progress * 2 * math.pi;

    final activePaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF6C63FF),
          Color(0xFF00C2FF),
          Color(0xFF6C63FF),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start - math.pi / 2,
      sweep,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PremiumLoaderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ========== ILLUSTRATION ==========
class _SplashIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft ground
    final groundPaint = Paint()
      ..color = const Color(0xFFE8F0FE).withOpacity(0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.92),
        width: w * 0.92,
        height: h * 0.18,
      ),
      groundPaint,
    );

    // ========== BUILDINGS ==========
    // Left building
    _drawBuilding(
      canvas,
      rect: Rect.fromLTWH(w * 0.06, h * 0.28, w * 0.18, h * 0.52),
      color: const Color(0xFFD1D5DB),
      windowColor: const Color(0xFF6C63FF).withOpacity(0.25),
      floors: 5,
    );

    // Center-left taller building
    _drawBuilding(
      canvas,
      rect: Rect.fromLTWH(w * 0.22, h * 0.12, w * 0.20, h * 0.68),
      color: const Color(0xFF9CA3AF),
      windowColor: const Color(0xFF00C2FF).withOpacity(0.3),
      floors: 7,
    );

    // Center-right building
    _drawBuilding(
      canvas,
      rect: Rect.fromLTWH(w * 0.58, h * 0.18, w * 0.18, h * 0.62),
      color: const Color(0xFFD1D5DB),
      windowColor: const Color(0xFF6C63FF).withOpacity(0.22),
      floors: 6,
    );

    // Right building
    _drawBuilding(
      canvas,
      rect: Rect.fromLTWH(w * 0.74, h * 0.32, w * 0.16, h * 0.48),
      color: const Color(0xFF9CA3AF),
      windowColor: const Color(0xFF00C2FF).withOpacity(0.28),
      floors: 4,
    );

    // ========== LOCATION PINS ==========
    _drawPin(canvas, Offset(w * 0.15, h * 0.22), const Color(0xFF6C63FF));
    _drawPin(canvas, Offset(w * 0.32, h * 0.08), const Color(0xFF00C2FF));
    _drawPin(canvas, Offset(w * 0.67, h * 0.12), const Color(0xFF22C55E));
    _drawPin(canvas, Offset(w * 0.82, h * 0.26), const Color(0xFF6C63FF));

    // ========== PERSON ==========
    final personX = w * 0.48;
    final personY = h * 0.55;

    // Soft shadow under person
    final shadowPaint = Paint()
      ..color = const Color(0xFF6C63FF).withOpacity(0.08);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(personX, h * 0.88),
        width: 56,
        height: 14,
      ),
      shadowPaint,
    );

    // Legs
    final legPaint = Paint()..color = const Color(0xFF374151);
    // Left leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(personX - 14, personY + 38, 11, 28),
        const Radius.circular(5),
      ),
      legPaint,
    );
    // Right leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(personX + 3, personY + 38, 11, 28),
        const Radius.circular(5),
      ),
      legPaint,
    );

    // Shoes
    final shoePaint = Paint()..color = const Color(0xFF1F2937);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(personX - 16, personY + 62, 14, 7),
        const Radius.circular(3.5),
      ),
      shoePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(personX + 2, personY + 62, 14, 7),
        const Radius.circular(3.5),
      ),
      shoePaint,
    );

    // Body (hoodie)
    final bodyPaint = Paint()..color = const Color(0xFF6C63FF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(personX - 18, personY - 4, 36, 46),
        const Radius.circular(12),
      ),
      bodyPaint,
    );

    // Hoodie detail
    final hoodieAccent = Paint()..color = const Color(0xFF5B54E0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(personX - 8, personY + 8, 16, 22),
        const Radius.circular(6),
      ),
      hoodieAccent,
    );

    // Arms holding phone
    final armPaint = Paint()..color = const Color(0xFFFBBF24).withOpacity(0.9);
    // Left arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(personX - 28, personY + 6, 14, 10),
        const Radius.circular(5),
      ),
      armPaint,
    );
    // Right arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(personX + 14, personY + 6, 14, 10),
        const Radius.circular(5),
      ),
      armPaint,
    );

    // Phone
    final phonePaint = Paint()..color = const Color(0xFF111827);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(personX - 10, personY + 2, 20, 28),
        const Radius.circular(4),
      ),
      phonePaint,
    );
    // Phone screen
    final screenPaint = Paint()..color = const Color(0xFF00C2FF).withOpacity(0.85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(personX - 7, personY + 5, 14, 20),
        const Radius.circular(2),
      ),
      screenPaint,
    );

    // Head
    final headPaint = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawCircle(Offset(personX, personY - 18), 16, headPaint);

    // Hair
    final hairPaint = Paint()..color = const Color(0xFF1F2937);
    final hairPath = Path()
      ..moveTo(personX - 16, personY - 20)
      ..quadraticBezierTo(personX - 18, personY - 36, personX, personY - 38)
      ..quadraticBezierTo(personX + 18, personY - 36, personX + 16, personY - 20)
      ..quadraticBezierTo(personX + 10, personY - 28, personX, personY - 26)
      ..quadraticBezierTo(personX - 10, personY - 28, personX - 16, personY - 20)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Soft glow around person
    final glowPaint = Paint()
      ..color = const Color(0xFF6C63FF).withOpacity(0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(personX, personY + 10), 42, glowPaint);
  }

  void _drawBuilding(
      Canvas canvas, {
        required Rect rect,
        required Color color,
        required Color windowColor,
        required int floors,
      }) {
    final paint = Paint()..color = color;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        const Radius.circular(6),
      ),
      paint,
    );

    // Windows
    final windowPaint = Paint()..color = windowColor;

    final windowW = rect.width * 0.22;
    final windowH = rect.height / (floors + 1) * 0.55;
    final gapX = (rect.width - windowW * 2) / 3;
    final startY = rect.top + rect.height * 0.12;

    for (int floor = 0; floor < floors; floor++) {
      final y = startY + floor * (rect.height / floors * 0.85);

      // Left window
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            rect.left + gapX,
            y,
            windowW,
            windowH,
          ),
          const Radius.circular(2),
        ),
        windowPaint,
      );

      // Right window
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            rect.left + gapX * 2 + windowW,
            y,
            windowW,
            windowH,
          ),
          const Radius.circular(2),
        ),
        windowPaint,
      );
    }
  }

  void _drawPin(Canvas canvas, Offset center, Color color) {
    final pinPaint = Paint()..color = color;
    // Pin body
    final path = Path()
      ..moveTo(center.dx, center.dy + 10)
      ..quadraticBezierTo(center.dx - 9, center.dy - 2, center.dx - 7, center.dy - 8)
      ..quadraticBezierTo(center.dx - 5, center.dy - 14, center.dx, center.dy - 14)
      ..quadraticBezierTo(center.dx + 5, center.dy - 14, center.dx + 7, center.dy - 8)
      ..quadraticBezierTo(center.dx + 9, center.dy - 2, center.dx, center.dy + 10)
      ..close();
    canvas.drawPath(path, pinPaint);

    // Inner circle
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(center.dx, center.dy - 7), 3.5, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}