import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  static const Color blue = Color(0xff5E7FCB);
  static const Color mint = Color(0xff9FE2D4);
  static const Color textColor = Color(0xff53617F);
  static const Color grayText = Color(0xff9A9A9A);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('الرجاء إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }

    try {
      setState(() => isLoading = true);

      // تسجيل الدخول عبر Firebase Auth
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // التحقق أن هذا المستخدم فعلاً مسؤول (role == admin)
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        showMessage('لا يوجد حساب مرتبط بهذا المستخدم');
        await FirebaseAuth.instance.signOut();
        return;
      }

      final data = doc.data()!;
      final String role = data['role'] ?? 'user';

      if (role != 'admin') {
        showMessage('هذا الحساب ليس لديه صلاحية الدخول كمسؤول');
        await FirebaseAuth.instance.signOut();
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/admin');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showMessage('البريد الإلكتروني غير مسجل');
      } else if (e.code == 'wrong-password') {
        showMessage('كلمة المرور غير صحيحة');
      } else if (e.code == 'invalid-email') {
        showMessage('صيغة البريد الإلكتروني غير صحيحة');
      } else if (e.code == 'invalid-credential') {
        showMessage('بيانات الدخول غير صحيحة');
      } else {
        showMessage('حدث خطأ أثناء تسجيل الدخول');
      }
    } catch (e) {
      showMessage('حدث خطأ غير متوقع');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> resetPassword() async {
    // لو المستخدم كاتب إيميل في الحقل، نستخدمه مباشرة كقيمة مبدئية
    final TextEditingController resetEmailController =
    TextEditingController(text: emailController.text.trim());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'استعادة كلمة المرور',
                  style: TextStyle(
                    color: AdminLoginScreen.textColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة تعيين كلمة المرور',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AdminLoginScreen.grayText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xffF6F6F6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'البريد الإلكتروني',
                      hintStyle: TextStyle(
                        color: AdminLoginScreen.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => Navigator.pop(context, true),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: const LinearGradient(
                        colors: [
                          AdminLoginScreen.mint,
                          AdminLoginScreen.blue,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: const Text(
                      'إرسال رابط الاستعادة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => Navigator.pop(context, false),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(
                      color: AdminLoginScreen.grayText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != true) return;

    final email = resetEmailController.text.trim();

    if (email.isEmpty) {
      showMessage('الرجاء إدخال البريد الإلكتروني');
      return;
    }

    try {
      setState(() => isLoading = true);
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showMessage('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showMessage('لا يوجد حساب مرتبط بهذا البريد الإلكتروني');
      } else if (e.code == 'invalid-email') {
        showMessage('صيغة البريد الإلكتروني غير صحيحة');
      } else {
        showMessage('حدث خطأ أثناء إرسال رابط الاستعادة');
      }
    } catch (e) {
      showMessage('حدث خطأ غير متوقع');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
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
                      'دخول المسؤول',
                      style: TextStyle(
                        color: AdminLoginScreen.textColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'أدخل البريد الإلكتروني وكلمة المرور',
                      style: TextStyle(
                        color: AdminLoginScreen.grayText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 45),

                    // حقل البريد الإلكتروني
                    _InputBox(
                      controller: emailController,
                      hint: 'البريد الإلكتروني',
                      keyboardType: TextInputType.emailAddress,
                      icon: Icons.email_outlined,
                    ),

                    const SizedBox(height: 18),

                    // حقل كلمة المرور
                    _InputBox(
                      controller: passwordController,
                      hint: 'كلمة المرور',
                      obscureText: obscurePassword,
                      icon: obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      onIconTap: () {
                        setState(() => obscurePassword = !obscurePassword);
                      },
                    ),

                    const SizedBox(height: 14),

                    // زر نسيت كلمة المرور
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: isLoading ? null : resetPassword,
                        child: const Text(
                          'نسيت كلمة المرور؟',
                          style: TextStyle(
                            color: AdminLoginScreen.textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
                              AdminLoginScreen.mint,
                              AdminLoginScreen.blue,
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
                  const Icon(
                    Icons.arrow_back_ios_new,
                    size: 15,
                    color: AdminLoginScreen.textColor,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'العودة',
                    style: TextStyle(
                      color: AdminLoginScreen.textColor,
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

class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData icon;
  final VoidCallback? onIconTap;

  const _InputBox({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    required this.icon,
    this.onIconTap,
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
              keyboardType: keyboardType,
              obscureText: obscureText,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AdminLoginScreen.textColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          InkWell(
            onTap: onIconTap,
            child: Icon(
              icon,
              size: 20,
              color: AdminLoginScreen.textColor,
            ),
          ),
        ],
      ),
    );
  }
}