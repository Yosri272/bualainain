import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'widgets/custom_bottom_nav.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  static const Color textColor = Color(0xff53617F);

  static const Color titleColor = Color(0xff2E3547);
  static const Color blue = Color(0xff5D7FCB);
  static const Color bgColor = Color(0xffF4F6FA);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Column(
          children: [
            _header(context, Colors.white),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد إشعارات جديدة',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  final notifications = snapshot.data!.docs;

                  return ListView.separated(
                    padding: const EdgeInsets.only(
                      top: 12,
                      bottom: 12,
                    ),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xffE8EAF0),
                    ),
                    itemBuilder: (context, index) {
                      final data =
                      notifications[index].data() as Map<String, dynamic>;

                      return _NotificationItem(
                        title: data['title'] ?? 'إشعار جديد',
                        body: data['body'] ?? '',
                        type: data['type'] ?? '',
                      );
                    },
                  );
                },
              ),
            ),

            const CustomBottomNav(selectedIndex: 2),
          ],
        ),
      ),
    );
  }

}
Widget _header(BuildContext context, Color? textColor) {
  return Container(
    height: 120,
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
          right: 24,
          bottom: -45,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios_new,
                  size: 15,
                  color: textColor,
                ),
                const SizedBox(width: 6),
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

class _NotificationItem extends StatelessWidget {
  final String title;
  final String body;
  final String type;

  const _NotificationItem({
    required this.title,
    required this.body,
    required this.type,
  });

  IconData get _icon {
    if (type == 'news') return Icons.article_outlined;
    if (type == 'events') return Icons.event_available_outlined;
    if (type == 'congratulations') return Icons.celebration_outlined;
    if (type == 'condolences') return Icons.volunteer_activism_outlined;
    return Icons.notifications_none_outlined;
  }

  String get _typeText {
    if (type == 'news') return 'خبر جديد';
    if (type == 'events') return 'مناسبة جديدة';
    if (type == 'congratulations') return 'تهنئة جديدة';
    if (type == 'condolences') return 'تعزية جديدة';
    return 'إشعار جديد';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xffEAF0FF),
                child: Icon(
                  _icon,
                  color: NotificationsScreen.blue,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _typeText,
                      style: const TextStyle(
                        color: NotificationsScreen.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      title,
                      style: const TextStyle(
                        color: NotificationsScreen.titleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),

                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: const TextStyle(
                          color: NotificationsScreen.textColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),

                    const Text(
                      'الآن',
                      style: TextStyle(
                        color: Color(0xff8A94AA),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 7),
                decoration: const BoxDecoration(
                  color: NotificationsScreen.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}