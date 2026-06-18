import 'package:flutter/material.dart';
import 'widgets/custom_bottom_nav.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color textColor = Color(0xff53617F);

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