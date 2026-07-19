import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const Color blue = Color(0xff5E7FCB);
  static const Color mint = Color(0xff9FE2D4);
  static const Color textColor = Color(0xff53617F);
  static const Color grayText = Color(0xff9A9A9A);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();

  bool isLoading = false;

  Future<void> login() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      showMessage('الرجاء إدخال رقم الجوال');
      return;
    }

    try {
      setState(() => isLoading = true);

      final result = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (result.docs.isEmpty) {
        showMessage('رقم الجوال غير مسجل');
        return;
      }

      final userData = result.docs.first.data();
      final String role = userData['role'] ?? 'user';
      final String status = userData['status'] ?? 'pending';

      // منع حسابات المسؤولين من الدخول عبر هذه الشاشة
      if (role == 'admin') {
        showMessage('هذا الحساب مخصص للمسؤولين، الرجاء استخدام دخول المسؤول');
        return;
      }

      if (status == 'pending') {
        Navigator.pushReplacementNamed(
          context,
          '/pending-approval',
        );
        return;
      }

      if (status == 'rejected') {
        Navigator.pushReplacementNamed(
          context,
          '/rejected-account',
        );
        return;
      }

      if (status == 'approved') {
        Navigator.pushReplacementNamed(
          context,
          '/otp',
        );
        return;
      }
    } catch (e) {
      showMessage('حدث خطأ أثناء تسجيل الدخول');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _header(context),
            const SizedBox(height: 85),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        color: LoginScreen.textColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'أدخل رقم الجوال للمتابعة',
                      style: TextStyle(
                        color: LoginScreen.grayText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 45),

                    _PhoneInputBox(
                      controller: phoneController,
                    ),

                    const SizedBox(height: 35),

                    InkWell(
                      onTap: isLoading ? null : login,
                      child: Container(
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: const LinearGradient(
                            colors: [
                              LoginScreen.mint,
                              LoginScreen.blue,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          'دخول',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'ليس لديك حساب؟',
                          style: TextStyle(
                            color: LoginScreen.grayText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: const Text(
                            'سجل الآن',
                            style: TextStyle(
                              color: LoginScreen.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
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

  Widget _header(BuildContext context) {
    return SizedBox(
      height: 165,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/header_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Positioned(
            right: 24,
            top: 142,
            child: InkWell(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/welcome',
                      (route) => false,
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new,
                    size: 15,
                    color: LoginScreen.textColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'العودة',
                    style: const TextStyle(
                      color: LoginScreen.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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
}

class _PhoneInputBox extends StatelessWidget {
  final TextEditingController controller;

  const _PhoneInputBox({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xffF6F6F6),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'رقم الجوال',
                hintStyle: TextStyle(
                  color: LoginScreen.textColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          SvgPicture.asset(
            'assets/icons/Call.svg',
            width: 19,
            height: 19,
            colorFilter: const ColorFilter.mode(
              LoginScreen.textColor,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}