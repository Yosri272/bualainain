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

  // خلفية الشاشة (رمادي فاتح)
  static const Color backgroundColor = Color(0xFFE3E0E0);

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
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SplashScreen.backgroundColor,
      body: SafeArea(
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

                    // الشعار في المنتصف
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.family_restroom,
                                  size: 50,
                                  color: SplashScreen.backgroundColor,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'شجرة العائلة',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'اربط جذورك بأحبابك',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
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
                  color: Colors.white.withOpacity(0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  size: 18,
                  color: SplashScreen.backgroundColor,
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
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.5
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