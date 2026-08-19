import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';

// عدّل هذول المسارات حسب هيكلة مشروعك
import 'welcome_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  // تدرج خلفية أنيق (كحلي - أزرق) بدل الرمادي الباهت
  static const Color backgroundStart = Color(0xFF1E2A4A);
  static const Color backgroundEnd = Color(0xFF3A5A8C);

  // لون مميز للتفاصيل (ذهبي دافئ) يعطي إحساس بالانتماء والأصالة
  static const Color accentColor = Color(0xFFE8C170);

  static const Duration logoAnimationDuration = Duration(milliseconds: 900);
  static const Duration branchAnimationDuration = Duration(milliseconds: 1400);
  static const Duration branchStartDelay = Duration(milliseconds: 400);
  static const Duration minSplashDuration = Duration(seconds: 3);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller; // للوجو (fade + scale)
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  late AnimationController _branchController; // لتفرّع "أفراد القبيلة"
  late Animation<double> _branchAnimation;

  late AnimationController _glowController; // نبض خفيف حول اللوجو
  late Animation<double> _glowAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer();

  Timer? _branchStartTimer;
  Timer? _navigationTimer;
  bool _didPrecache = false;

  // مواقع بسيطة تمثل أفراد العائلة يتفرعوا حوالين الشعار
  final List<_MemberDot> _members = const [
    _MemberDot(angle: -60, delay: 0.0),
    _MemberDot(angle: -20, delay: 0.1),
    _MemberDot(angle: 20, delay: 0.2),
    _MemberDot(angle: 60, delay: 0.3),
    _MemberDot(angle: 140, delay: 0.15),
    _MemberDot(angle: 180, delay: 0.25),
    _MemberDot(angle: 220, delay: 0.35),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: SplashScreen.logoAnimationDuration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // كنترولر التفرّع: الأفراد بيظهروا ويبعدوا عن المركز بالتدريج
    _branchController = AnimationController(
      vsync: this,
      duration: SplashScreen.branchAnimationDuration,
    );
    _branchAnimation = CurvedAnimation(
      parent: _branchController,
      curve: Curves.easeOutCubic,
    );

    // نبضة توهج خفيفة ومستمرة حول الشعار تعطي حيوية للتصميم
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _playIntroSound();

    _controller.forward();

    // نبدأ حركة التفرّع بعد ما اللوجو يظهر شوية
    _branchStartTimer = Timer(SplashScreen.branchStartDelay, () {
      if (mounted) _branchController.forward();
    });

    _navigateNext();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // نحمّل الصورة مسبقًا عشان تظهر فورًا بدون وميض
    if (!_didPrecache) {
      _didPrecache = true;
      precacheImage(const AssetImage('assets/images/app_icon.png'), context);
    }
  }

  Future<void> _playIntroSound() async {
    try {
      // حط ملف صوت خفيف (نغمة ترحيب/جرس بسيط) في assets/sounds/
      await _audioPlayer.play(AssetSource('sounds/intro_chime.mp3'));
    } catch (_) {
      // لو الصوت مش موجود أو الجهاز مكتوم، نكمل عادي من غير ما نوقف التطبيق
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
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, animation, __) => nextScreen,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _branchStartTimer?.cancel();
    _navigationTimer?.cancel();
    _controller.dispose();
    _branchController.dispose();
    _glowController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              SplashScreen.backgroundStart,
              SplashScreen.backgroundEnd,
            ],
          ),
        ),
        child: Stack(
          children: [
            // زخرفة دائرية خفيفة في الخلفية تعطي عمق للتصميم
            Positioned(
              top: -80,
              right: -60,
              child: _buildBackgroundCircle(220),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: _buildBackgroundCircle(260),
            ),

            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // منطقة اللوجو + الأفراد المتفرعة حواليه
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // الأفراد بيتفرعوا ويظهروا حوالين المركز
                          ..._members.map((m) => _buildMemberDot(m)),

                          // الخط الواصل (يمثل روابط النسب) بيتحرك مع نفس الأنيميشن
                          AnimatedBuilder(
                            animation: _branchAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                size: const Size(260, 260),
                                painter: _BranchLinesPainter(
                                  progress: _branchAnimation.value,
                                  members: _members,
                                ),
                              );
                            },
                          ),

                          // توهج ذهبي نابض خلف الشعار
                          AnimatedBuilder(
                            animation: _glowAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: SplashScreen.accentColor
                                          .withOpacity(
                                          0.35 * _glowAnimation.value),
                                      blurRadius: 40,
                                      spreadRadius: 6,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // الشعار في المنتصف
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                width: 104,
                                height: 104,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      SplashScreen.accentColor,
                                      SplashScreen.accentColor
                                          .withOpacity(0.4),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Container(
                                    color: Colors.white,
                                    child: Image.asset(
                                      'assets/images/app_icon.png',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.family_restroom,
                                          size: 46,
                                          color:
                                          SplashScreen.backgroundEnd,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            SplashScreen.accentColor,
                            Colors.white,
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'قبيلة آل عوينين',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'اربط جذورك بأحبابك',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.75),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 44),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: SplashScreen.accentColor,
                          strokeWidth: 2.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.04),
      ),
    );
  }

  // ينشئ نقطة/أيقونة فرد بتتحرك من المركز لموقعها بزاوية معينة
  Widget _buildMemberDot(_MemberDot member) {
    return AnimatedBuilder(
      animation: _branchAnimation,
      builder: (context, child) {
        // تأخير بسيط لكل فرد عشان الظهور يبقى متتابع مش دفعة واحدة
        final double t =
        ((_branchAnimation.value - member.delay) / (1 - member.delay))
            .clamp(0.0, 1.0);

        const double radius = 100;
        final double dx = radius * t * math.cos(member.angle * math.pi / 180);
        final double dy = radius * t * math.sin(member.angle * math.pi / 180);

        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.scale(
              scale: 0.6 + (0.4 * t),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: SplashScreen.accentColor.withOpacity(0.7),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  size: 18,
                  color: SplashScreen.backgroundEnd,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// موديل بسيط يمثل موقع/توقيت ظهور فرد حوالين اللوجو
class _MemberDot {
  final double angle; // بالدرجات
  final double delay; // من 0 لـ 1، وقت بدء ظهور الفرد نسبة لمدة الأنيميشن
  const _MemberDot({required this.angle, required this.delay});
}

// يرسم خطوط رفيعة بتوصل كل فرد بالمركز، بتطول تدريجيًا مع الأنيميشن
class _BranchLinesPainter extends CustomPainter {
  final double progress;
  final List<_MemberDot> members;

  _BranchLinesPainter({required this.progress, required this.members});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Paint paint = Paint()
      ..color = SplashScreen.accentColor.withOpacity(0.45)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    const double radius = 100;

    for (final m in members) {
      final double t = ((progress - m.delay) / (1 - m.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final Offset end = Offset(
        center.dx + radius * t * math.cos(m.angle * math.pi / 180),
        center.dy + radius * t * math.sin(m.angle * math.pi / 180),
      );

      canvas.drawLine(center, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BranchLinesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}