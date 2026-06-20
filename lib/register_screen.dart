import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const Color blue = Color(0xff5E7FCB);
  static const Color mint = Color(0xff9FE2D4);
  static const Color textColor = Color(0xff53617F);
  static const Color grayText = Color(0xff9A9A9A);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool agree = false;
  bool isLoading = false;

  Future<void> createAccount() async {
    if (!agree) {
      showMessage('يجب الموافقة على شروط الخدمة');
      return;
    }

    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      showMessage('الرجاء تعبئة جميع البيانات');
      return;
    }

    try {
      setState(() => isLoading = true);

      final UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final String userId = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'userId': userId,
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'role': 'user',
        'status': 'pending', // pending - approved - rejected
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/SuccessScreen');
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ أثناء إنشاء الحساب';

      if (e.code == 'email-already-in-use') {
        message = 'البريد الإلكتروني مستخدم مسبقاً';
      } else if (e.code == 'weak-password') {
        message = 'كلمة المرور ضعيفة، يجب أن تكون 6 أحرف أو أكثر';
      } else if (e.code == 'invalid-email') {
        message = 'البريد الإلكتروني غير صحيح';
      }

      showMessage(message);
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
    nameController.dispose();
    phoneController.dispose();
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
            const SizedBox(height: 55),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Text(
                      'حساب جديد',
                      style: TextStyle(
                        color: RegisterScreen.textColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'أهلاً بك، ويسعدنا اشتراكك معنا بالتطبيق',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: RegisterScreen.grayText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 42),

                    _InputBox(
                      controller: nameController,
                      hint: 'الإسم الثاني',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 18),

                    _InputBox(
                      controller: phoneController,
                      hint: 'رقم الجوال',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 18),

                    _InputBox(
                      controller: emailController,
                      hint: 'البريد الإلكتروني',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 18),

                    _InputBox(
                      controller: passwordController,
                      hint: 'كلمة المرور',
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Checkbox(
                          value: agree,
                          onChanged: (value) {
                            setState(() {
                              agree = value ?? false;
                            });
                          },
                          side: const BorderSide(
                            color: Color(0xffD8D8D8),
                            width: 1.5,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'من خلال تسجيل فإنك توافق على شروط الخدمة',
                            style: TextStyle(
                              color: RegisterScreen.grayText,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    InkWell(
                      onTap: isLoading ? null : createAccount,
                      child: Container(
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: const LinearGradient(
                            colors: [
                              RegisterScreen.mint,
                              RegisterScreen.blue,
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
                          'إنشاء حساب',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 38),
                    const _OrDivider(),
                    const SizedBox(height: 35),

                    const _SocialButton(
                      text: 'الدخول عن طريق قوقل',
                      assetPath: 'assets/icons/icons_google.svg',
                    ),

                    const SizedBox(height: 16),

                    const _SocialButton(
                      text: 'الدخول عن طريق ابل',
                      assetPath: 'assets/icons/icons_apple.svg',
                    ),

                    const SizedBox(height: 30),
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
    return Container(
      height: 135,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/header_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [

          Positioned(
            right: 28,
            bottom: -38,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'العودة',
                    style: TextStyle(
                      color: RegisterScreen.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_back_ios_new,
                    color: RegisterScreen.textColor,
                    size: 15,
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
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _InputBox({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xffF6F6F6),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: RegisterScreen.textColor,
            size: 25,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  color: RegisterScreen.textColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xffEEEEEE))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'أو',
            style: TextStyle(
              color: RegisterScreen.grayText,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xffEEEEEE))),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String text;
  final String assetPath;

  const _SocialButton({
    required this.text,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffDDDDDD)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            assetPath,
            height: 24,
            width: 24,
          ),
          const SizedBox(width: 18),
          Text(
            text,
            style: const TextStyle(
              color: RegisterScreen.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}