import 'package:flutter/material.dart';
import 'widgets/custom_bottom_nav.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color textColor = Color(0xff53617F);

  Future<bool> _reauthenticate(BuildContext context, User user) async {
    final providerId =
    user.providerData.isNotEmpty ? user.providerData.first.providerId : '';

    // حالة الدخول بالإيميل وكلمة المرور (الأدمن مثلاً)
    if (providerId == 'password') {
      final passwordController = TextEditingController();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('تأكيد الهوية', textAlign: TextAlign.right),
            content: TextField(
              controller: passwordController,
              obscureText: true,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'أدخل كلمة المرور الحالية',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('تأكيد'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return false;

      try {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: passwordController.text.trim(),
        );
        await user.reauthenticateWithCredential(credential);
        debugPrint('✅ تمت إعادة المصادقة بنجاح (Email/Password)');
        return true;
      } catch (e) {
        debugPrint('❌ فشل إعادة المصادقة: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('كلمة المرور غير صحيحة')),
          );
        }
        return false;
      }
    }

    // حالة الدخول برقم الجوال / OTP أو أي طريقة أخرى
    debugPrint('⚠️ طريقة الدخول ($providerId) تحتاج تسجيل خروج ودخول جديد');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء تسجيل الخروج والدخول مرة أخرى ثم إعادة المحاولة'),
        ),
      );
    }
    return false;
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'حذف الحساب',
            textAlign: TextAlign.right,
          ),
          content: const Text(
            'سيتم حذف حسابك وجميع بياناتك نهائيًا ولا يمكن التراجع عن هذا الإجراء. هل أنت متأكد؟',
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('حذف نهائي'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint('❌ لا يوجد مستخدم مسجل دخول حاليًا');
      return;
    }

    debugPrint('UID الحالي: ${user.uid}');
    debugPrint('طريقة الدخول: ${user.providerData.map((p) => p.providerId).join(", ")}');

    // إعادة المصادقة أولاً (مطلوبة من Firebase لعمليات الحذف)
    final reauthenticated = await _reauthenticate(context, user);
    if (!reauthenticated) return;

    if (!context.mounted) return;

    // إظهار مؤشر تحميل أثناء عملية الحذف
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final uid = user.uid;

      // 1. حذف بيانات المستخدم من Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      debugPrint('✅ تم حذف مستند Firestore بنجاح (users/$uid)');

      // 2. حذف حساب المستخدم من Firebase Authentication
      await user.delete();
      debugPrint('✅ تم حذف حساب Auth بنجاح');

      if (context.mounted) {
        Navigator.pop(context); // إغلاق مؤشر التحميل

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
              (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف حسابك بنجاح')),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} - ${e.message}');

      if (context.mounted) Navigator.pop(context); // إغلاق مؤشر التحميل

      if (e.code == 'requires-recent-login') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'لأسباب أمنية، الرجاء تسجيل الخروج والدخول مرة أخرى ثم إعادة المحاولة',
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ أثناء حذف الحساب: ${e.message}')),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ غير متوقع: $e');
      if (context.mounted) {
        Navigator.pop(context); // إغلاق مؤشر التحميل
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ غير متوقع أثناء حذف الحساب: $e')),
        );
      }
    }
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

            const SizedBox(height: 70),

            const CircleAvatar(
              radius: 38,
              backgroundImage: AssetImage(
                'assets/images/profile.png',
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'منصور البوعينين',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 25),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                children:  [
                  _ProfileItem(
                    title: 'تعديل الملف الشخصي',
                    icon: SvgPicture.asset(
                      'assets/icons/Profile.svg',
                      width: 19,
                      height: 19,
                      colorFilter: const ColorFilter.mode(
                        Color(0xff53617F),
                        BlendMode.srcIn,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/edit-profile');
                    },
                  ),
                  _ProfileItem(
                    title: 'شجرة العائلة',
                    icon: const Icon(
                      Icons.account_tree_outlined,
                      size: 19,
                      color: Color(0xff53617F),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/FamilyTreeScreen');
                    },
                  ),
                  _ProfileItem(
                    title: 'إدارة التنبيهات',
                    icon: SvgPicture.asset(
                      'assets/icons/bell.svg',
                      width: 19,
                      height: 19,
                      colorFilter: const ColorFilter.mode(
                        Color(0xff53617F),
                        BlendMode.srcIn,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/NotificationSettings');
                    },
                  ),
                  _ProfileItem(
                    title: 'تواصل معنا',
                    icon: SvgPicture.asset(
                      'assets/icons/Call.svg',
                      width: 19,
                      height: 19,
                      colorFilter: const ColorFilter.mode(
                        Color(0xff53617F),
                        BlendMode.srcIn,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/contact-us');
                    },
                  ),
                  _ProfileItem(
                    title: 'قيم التطبيق',
                    icon: SvgPicture.asset(
                      'assets/icons/Star.svg',
                      width: 19,
                      height: 19,
                      colorFilter: const ColorFilter.mode(
                        Color(0xff53617F),
                        BlendMode.srcIn,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/rate-app');
                    },
                  ),
                  _ProfileItem(
                    title: 'الأحكام والشروط',
                    icon: SvgPicture.asset(
                      'assets/icons/document.svg',
                      width: 19,
                      height: 19,
                      colorFilter: const ColorFilter.mode(
                        Color(0xff53617F),
                        BlendMode.srcIn,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/terms');
                    },
                  ),
                  _ProfileItem(
                    title: 'سياسة الخصوصية',
                    icon: SvgPicture.asset(
                      'assets/icons/Paper.svg',
                      width: 19,
                      height: 19,
                      colorFilter: const ColorFilter.mode(
                        Color(0xff53617F),
                        BlendMode.srcIn,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/privacy-policy');
                    },
                  ),
                  _ProfileItem(
                    title: 'حذف الحساب',
                    icon: SvgPicture.asset(
                      'assets/icons/Delete.svg',
                      width: 19,
                      height: 19,
                      colorFilter: const ColorFilter.mode(
                        Color(0xff53617F),
                        BlendMode.srcIn,
                      ),
                    ),
                    onTap: () => _deleteAccount(context),
                  ),
                  _ProfileItem(
                    title: 'تسجيل الخروج',
                    icon: SvgPicture.asset(
                      'assets/icons/Logout.svg',
                      width: 19,
                      height: 19,
                      colorFilter: const ColorFilter.mode(
                        Color(0xff53617F),
                        BlendMode.srcIn,
                      ),
                    ),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: const Text(
                              'تسجيل الخروج',
                              textAlign: TextAlign.right,
                            ),
                            content: const Text(
                              'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
                              textAlign: TextAlign.right,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                                child: const Text('إلغاء'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                child: const Text('خروج'),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm == true) {
                        await FirebaseAuth.instance.signOut();

                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                                (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),

            const CustomBottomNav(
              selectedIndex: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            'assets/images/header_bg.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [

          Positioned(
            right: 24,
            bottom: -45,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new,
                    size: 15,
                    color: textColor,
                  ),
                  SizedBox(width: 6),

                  Text(
                    'العودة',
                    style: TextStyle(
                      color: textColor,
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
class _ProfileItem extends StatelessWidget {
  final String title;
  final Widget icon;
  final VoidCallback? onTap;

  const _ProfileItem({
    required this.title,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            icon,

            const SizedBox(width: 24),

            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xff2E3547),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            SvgPicture.asset(
              'assets/icons/back.svg',
              width: 19,
              height: 19,
              colorFilter: const ColorFilter.mode(
                Color(0xff53617F),
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}