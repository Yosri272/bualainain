import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;

  const CustomBottomNav({
    super.key,
    this.selectedIndex = 0,
  });

  static const Color activeColor = Color(0xff5D7FCB);
  static const Color navColor = Color(0xff53617F);

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'title': 'البداية',
        'icon': 'assets/icons/home.svg',
        'route': '/home',
      },
      {
        'title': 'احدث الأخبار',
        'icon': 'assets/icons/document.svg',
        'route': '/news',
      },
      {
        'title': 'التنبيهات',
        'icon': 'assets/icons/bell.svg',
        'route': '/notifications',
      },
      {
        'title': 'الملف الشخصي',
        'icon': 'assets/icons/settings-sliders.svg',
        'route': '/profile',
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: 75,
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        child: Row(
          children: List.generate(
            items.length,
                (index) {
              final isSelected = selectedIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (!isSelected) {
                      Navigator.pushReplacementNamed(
                        context,
                        items[index]['route'] as String,
                      );
                    }
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SvgPicture.asset(
                            items[index]['icon'] as String,
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              isSelected ? activeColor : navColor,
                              BlendMode.srcIn,
                            ),
                          ),

                          if (index == 2)
                            if (index == 2)
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('notifications')
                                    .where('isRead', isEqualTo: false)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const SizedBox();
                                  }

                                  final unreadCount = snapshot.data!.docs.length;

                                  if (unreadCount == 0) {
                                    return const SizedBox();
                                  }

                                  return Positioned(
                                    top: -6,
                                    right: -8,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          unreadCount > 99
                                              ? '99+'
                                              : unreadCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        items[index]['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? activeColor : navColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}