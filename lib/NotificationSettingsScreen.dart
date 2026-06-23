import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'widgets/custom_bottom_nav.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const Color textColor = Color(0xff53617F);

  bool newsNotification = true;
  bool eventsNotification = false;
  bool congratulationsNotification = true;
  bool condolencesNotification = true;

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
              backgroundImage: AssetImage('assets/images/profile.png'),
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

            const SizedBox(height: 45),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34),
                child: Column(
                  children: [
                    _NotificationItem(
                      title: 'تنبيهات الأخبار',
                      value: newsNotification,
                      onChanged: (value) {
                        setState(() {
                          newsNotification = value;
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    _NotificationItem(
                      title: 'تنبيهات المناسبات',
                      value: eventsNotification,
                      onChanged: (value) {
                        setState(() {
                          eventsNotification = value;
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    _NotificationItem(
                      title: 'تنبيهات التهاني والتبريكات',
                      value: congratulationsNotification,
                      onChanged: (value) {
                        setState(() {
                          congratulationsNotification = value;
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    _NotificationItem(
                      title: 'تنبيهات التعازي والمواساة',
                      value: condolencesNotification,
                      onChanged: (value) {
                        setState(() {
                          condolencesNotification = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const CustomBottomNav(selectedIndex: 2),
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
                  '/profile',
                      (route) => false,
                );
              },
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

class _NotificationItem extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationItem({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/bell.svg',
            width: 19,
            height: 19,
            colorFilter: const ColorFilter.mode(
              Color(0xff53617F),
              BlendMode.srcIn,
            ),
          ),

          const SizedBox(width: 12),

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

          Transform.scale(
            scale: 0.82,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xff5B6C99),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xffE7E7E7),
            ),
          ),
        ],
      ),
    );
  }
}