import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  // تدرج الألوان الجديد: من الميدنت الفاتح أعلى الشاشة إلى الأزرق الغامق أسفلها
  // (نفس تدرج mint/blue المستخدم في باقي شاشات التطبيق).
  static const Color backgroundStart = Color(0xFFBFEAE0);
  static const Color backgroundMiddle = Color(0xFF7FB3D9);
  static const Color backgroundEnd = Color(0xFF4A6FB5);
  static const Color accentColor = Color(0xFF5E7FCB);
  static const Color accentSoft = Color(0xFF9FE2D4);
  // لون غامق يستخدم للنص والخطوط عشان يبين بوضوح فوق الخلفية الفاتحة.
  static const Color darkAccent = Color(0xFF243B66);

  static const Duration minSplashDuration = Duration(milliseconds: 3400);

  // Animation timing, grouped here instead of scattered as inline literals.
  static const Duration _logoDuration = Duration(milliseconds: 1050);
  static const Duration _branchDuration = Duration(milliseconds: 1500);
  static const Duration _ambientDuration = Duration(milliseconds: 5200);
  static const Duration _textDuration = Duration(milliseconds: 900);
  static const Duration _branchStartDelay = Duration(milliseconds: 380);
  static const Duration _transitionDuration = Duration(milliseconds: 650);

  // Layout constants, grouped here instead of magic numbers in build().
  static const double _brandMarkSize = 300;
  static const double _branchRadius = 113;
  static const double _logoSize = 114;
  static const double _memberDotSize = 38;
  static const double _orbitSize = 182;
  static const double _glowBaseSize = 146;
  static const double _glowPulseSize = 8;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _branchController;
  late final AnimationController _ambientController;
  late final AnimationController _textController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _branchAnimation;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  final AudioPlayer _audioPlayer = AudioPlayer();

  Timer? _branchTimer;
  Timer? _navigationTimer;
  bool _didPrecache = false;

  final List<_MemberDot> _members = const [
    _MemberDot(angle: -78, delay: 0.00),
    _MemberDot(angle: -38, delay: 0.08),
    _MemberDot(angle: 2, delay: 0.16),
    _MemberDot(angle: 42, delay: 0.24),
    _MemberDot(angle: 98, delay: 0.10),
    _MemberDot(angle: 142, delay: 0.18),
    _MemberDot(angle: 184, delay: 0.26),
    _MemberDot(angle: 226, delay: 0.34),
  ];

  /// Shared wave function used by the background, the glow, and the
  /// loading dots so the "breathing" pulse looks the same everywhere
  /// and the formula lives in exactly one place.
  static double _waveAt(double cycleFraction) =>
      (math.sin(cycleFraction * math.pi * 2) + 1) / 2;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: SplashScreen._logoDuration,
    );

    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    _branchController = AnimationController(
      vsync: this,
      duration: SplashScreen._branchDuration,
    );

    _branchAnimation = CurvedAnimation(
      parent: _branchController,
      curve: Curves.easeOutCubic,
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: SplashScreen._ambientDuration,
    )..repeat();

    _textController = AnimationController(
      vsync: this,
      duration: SplashScreen._textDuration,
    );

    _titleFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    _playIntroSound();
    _logoController.forward();

    _branchTimer = Timer(SplashScreen._branchStartDelay, () {
      if (!mounted) return;
      _branchController.forward();
      _textController.forward();
    });

    _navigateNext();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didPrecache) {
      _didPrecache = true;
      precacheImage(const AssetImage('assets/images/app_icon.png'), context);
    }
  }

  Future<void> _playIntroSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/intro_chime.mp3'));
    } catch (_) {
      // الصوت اختياري، لذلك لا نوقف شاشة البداية عند فشل تشغيله.
    }
  }

  void _navigateNext() {
    _navigationTimer = Timer(SplashScreen.minSplashDuration, () {
      if (!mounted) return;

      final User? currentUser = FirebaseAuth.instance.currentUser;
      final Widget nextScreen =
      currentUser != null ? const HomeScreen() : const WelcomeScreen();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: SplashScreen._transitionDuration,
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _branchTimer?.cancel();
    _navigationTimer?.cancel();

    _logoController.dispose();
    _branchController.dispose();
    _ambientController.dispose();
    _textController.dispose();
    _audioPlayer.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only the gradient needs to repaint on every ambient tick. Everything
    // else (particles, glass circles, brand mark, loading dots) owns its
    // own narrowly-scoped AnimatedBuilder further down the tree, and is
    // passed in here as `child` so it is built exactly once instead of on
    // every animation frame.
    return Scaffold(
      body: AnimatedBuilder(
        animation: _ambientController,
        builder: (context, child) {
          final double wave = _waveAt(_ambientController.value);

          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(
                    SplashScreen.backgroundStart,
                    const Color(0xFFAEE3D6),
                    wave * 0.42,
                  )!,
                  SplashScreen.backgroundMiddle,
                  Color.lerp(
                    SplashScreen.backgroundEnd,
                    const Color(0xFF3E5FA0),
                    (1 - wave) * 0.35,
                  )!,
                ],
                stops: const [0.0, 0.52, 1.0],
              ),
            ),
            child: SizedBox.expand(child: child),
          );
        },
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _ambientController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _AmbientParticlesPainter(
                      progress: _ambientController.value,
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        AnimatedBuilder(
          animation: _ambientController,
          builder: (context, child) {
            final double wave = _waveAt(_ambientController.value);
            return Positioned(
              top: -115 + (18 * wave),
              right: -85,
              child: child!,
            );
          },
          child: _buildGlassCircle(290),
        ),
        AnimatedBuilder(
          animation: _ambientController,
          builder: (context, child) {
            final double wave = _waveAt(_ambientController.value);
            return Positioned(
              bottom: -135 - (14 * wave),
              left: -95,
              child: child!,
            );
          },
          child: _buildGlassCircle(320),
        ),

        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBrandMark(),
                  const SizedBox(height: 14),
                  _buildTitleBlock(),
                  const SizedBox(height: 42),
                  _buildLoadingDots(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandMark() {
    return SizedBox(
      width: SplashScreen._brandMarkSize,
      height: SplashScreen._brandMarkSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _branchAnimation,
                _ambientController,
              ]),
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(
                    SplashScreen._brandMarkSize,
                    SplashScreen._brandMarkSize,
                  ),
                  painter: _BranchLinesPainter(
                    progress: _branchAnimation.value,
                    pulse: _waveAt(_ambientController.value),
                    members: _members,
                  ),
                );
              },
            ),
          ),

          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                final double t = _ambientController.value;
                return Transform.rotate(
                  angle: t * math.pi * 2,
                  child: CustomPaint(
                    size: const Size(
                      SplashScreen._orbitSize,
                      SplashScreen._orbitSize,
                    ),
                    painter: _OrbitPainter(
                      progress: t,
                      pulse: _waveAt(t),
                    ),
                  ),
                );
              },
            ),
          ),

          ..._members.map(_buildMemberDot),

          AnimatedBuilder(
            animation: _ambientController,
            builder: (context, child) {
              final double wave = _waveAt(_ambientController.value);
              final double size = SplashScreen._glowBaseSize +
                  (SplashScreen._glowPulseSize * wave);

              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SplashScreen.accentColor.withOpacity(
                        0.17 + (0.12 * wave),
                      ),
                      blurRadius: 40 + (12 * wave),
                      spreadRadius: 5 + (3 * wave),
                    ),
                  ],
                ),
              );
            },
          ),

          FadeTransition(
            opacity: _logoFade,
            child: ScaleTransition(
              scale: _logoScale,
              child: _buildLogo(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBlock() {
    // Driven only by _textController, so it is safe to build once inside
    // the cached `child` of _buildContent() rather than on ambient ticks.
    return FadeTransition(
      opacity: _titleFade,
      child: SlideTransition(
        position: _titleSlide,
        child: Column(
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white,
                    Colors.white,
                  ],
                ).createShader(bounds);
              },
              child: const Text(
                'اسرة البوعينين',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 31,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'اربط جذورك بأحبابك',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: SplashScreen._logoSize,
      height: SplashScreen._logoSize,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SplashScreen.accentSoft,
            SplashScreen.accentColor,
            Color(0xFF3F5A9E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: SplashScreen.accentColor.withOpacity(0.22),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.96),
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/app_icon.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(
                color: Colors.white,
                child: Icon(
                  Icons.family_restroom_rounded,
                  size: 50,
                  color: SplashScreen.backgroundEnd,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMemberDot(_MemberDot member) {
    return AnimatedBuilder(
      animation: Listenable.merge([_branchAnimation, _ambientController]),
      builder: (context, child) {
        final double t =
        ((_branchAnimation.value - member.delay) / (1 - member.delay))
            .clamp(0.0, 1.0);

        final double pulse = _waveAt(
          _ambientController.value + member.delay * (8 / (2 * math.pi)),
        );

        final double dx =
            SplashScreen._branchRadius * t * math.cos(member.radians);
        final double dy =
            SplashScreen._branchRadius * t * math.sin(member.radians);

        return Opacity(
          opacity: Curves.easeOut.transform(t),
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.scale(
              scale: (0.65 + (0.35 * t)) * (0.97 + 0.04 * pulse),
              child: Container(
                width: SplashScreen._memberDotSize,
                height: SplashScreen._memberDotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.92),
                    ],
                  ),
                  border: Border.all(
                    color: SplashScreen.darkAccent.withOpacity(0.85),
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: SplashScreen.accentColor.withOpacity(0.18 * pulse),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 9,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: SplashScreen.darkAccent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.10),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, _) {
        final double progress = _ambientController.value;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final double phase = (progress + (index * 0.13)) % 1.0;
            final double pulse = _waveAt(phase);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: 0.72 + (0.28 * pulse),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(
                      0.45 + 0.55 * pulse,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.22 * pulse),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _MemberDot {
  final double angle;
  final double delay;

  /// Precomputed once at compile time instead of on every animation frame.
  final double radians;

  const _MemberDot({
    required this.angle,
    required this.delay,
  }) : radians = angle * math.pi / 180;
}

class _BranchLinesPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final List<_MemberDot> members;

  _BranchLinesPainter({
    required this.progress,
    required this.pulse,
    required this.members,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    const double radius = SplashScreen._branchRadius;

    final Paint glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.20 + 0.10 * pulse)
      ..strokeWidth = 4.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final member in members) {
      final double t =
      ((progress - member.delay) / (1 - member.delay)).clamp(0.0, 1.0);

      if (t <= 0) continue;

      final double angle = member.radians;
      final Offset end = Offset(
        center.dx + radius * t * math.cos(angle),
        center.dy + radius * t * math.sin(angle),
      );

      final Offset control = Offset(
        center.dx + (radius * 0.46 * t) * math.cos(angle + 0.16),
        center.dy + (radius * 0.46 * t) * math.sin(angle + 0.16),
      );

      final Path path = Path()
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

      final Paint linePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.30),
            Colors.white.withOpacity(0.95),
          ],
        ).createShader(Rect.fromPoints(center, end))
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BranchLinesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pulse != pulse;
  }
}

class _OrbitPainter extends CustomPainter {
  final double progress;
  final double pulse;

  _OrbitPainter({
    required this.progress,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Rect rect =
    Rect.fromCircle(center: center, radius: size.width / 2 - 4);

    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.55 + 0.15 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const double sweep = math.pi * 0.34;

    for (int i = 0; i < 4; i++) {
      final double start = (i * math.pi / 2) + progress * math.pi * 0.5;
      canvas.drawArc(rect, start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pulse != pulse;
  }
}

class _AmbientParticlesPainter extends CustomPainter {
  final double progress;

  _AmbientParticlesPainter({required this.progress});

  static const List<Offset> _points = [
    Offset(0.10, 0.18),
    Offset(0.22, 0.72),
    Offset(0.36, 0.12),
    Offset(0.50, 0.82),
    Offset(0.66, 0.25),
    Offset(0.80, 0.68),
    Offset(0.92, 0.18),
    Offset(0.88, 0.88),
    Offset(0.16, 0.90),
    Offset(0.72, 0.92),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < _points.length; i++) {
      final Offset p = _points[i];
      final double phase = progress * math.pi * 2 + i * 0.9;
      final double dy = math.sin(phase) * 7;
      final double opacity = 0.05 + ((math.sin(phase + 0.8) + 1) / 2) * 0.07;
      final double radius = 1.3 + (i % 3) * 0.55;

      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height + dy),
        radius,
        paint..color = Colors.white.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}