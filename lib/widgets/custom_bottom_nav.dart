import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/session_service.dart';

class CustomBottomNav extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTap;

  const CustomBottomNav({
    super.key,
    this.selectedIndex = 0,
    this.onTap,
  });

  static const Color activeColor = Color(0xff5D7FCB);
  static const Color navColor = Color(0xff53617F);

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  // نفس منطق شاشة الإشعارات بالظبط: هوية المستخدم من SessionService،
  // وحالة القراءة تُحسب من readBy (وليس isRead القديم) عشان الرقم
  // الأحمر هنا يطابق فعلياً عدد "غير المقروء" الظاهر في شاشة التنبيهات.
  String currentUserId = '';

  Map<String, bool> _prefs = {
    'news': true,
    'events': false,
    'congratulations': true,
    'condolences': true,
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final id = await SessionService.getUserId();
    if (mounted) {
      setState(() => currentUserId = id ?? '');
    }
    if (id != null) {
      await _loadPreferences(id);
    }
  }

  Future<void> _loadPreferences(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('notification_settings')
          .doc(userId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _prefs = {
            'news': data['news'] ?? _prefs['news']!,
            'events': data['events'] ?? _prefs['events']!,
            'congratulations':
            data['congratulations'] ?? _prefs['congratulations']!,
            'condolences': data['condolences'] ?? _prefs['condolences']!,
          };
        });
      }
    } catch (e) {
      debugPrint('خطأ أثناء تحميل تفضيلات الإشعارات (nav): $e');
    }
  }

  bool _isEnabledType(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    if (!_prefs.containsKey(type)) return true;
    return _prefs[type] ?? true;
  }

  bool _isReadByCurrentUser(Map<String, dynamic> data) {
    final readBy = data['readBy'];

    if (readBy is List && currentUserId.isNotEmpty) {
      return readBy.contains(currentUserId);
    }

    // دعم الإشعارات القديمة التي كانت تستخدم isRead.
    return data['isRead'] == true;
  }

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
              final isSelected = widget.selectedIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (isSelected) {
                      return;
                    }

                    if (widget.onTap != null) {
                      widget.onTap!(index);
                      return;
                    }

                    Navigator.pushReplacementNamed(
                      context,
                      items[index]['route'] as String,
                    );
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
                              isSelected
                                  ? CustomBottomNav.activeColor
                                  : CustomBottomNav.navColor,
                              BlendMode.srcIn,
                            ),
                          ),

                          if (index == 2)
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('notifications')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData ||
                                    currentUserId.isEmpty) {
                                  return const SizedBox();
                                }

                                final unreadCount = snapshot
                                    .data!.docs
                                    .where((doc) {
                                  final data =
                                  doc.data() as Map<String, dynamic>;
                                  if (!_isEnabledType(data)) return false;
                                  return !_isReadByCurrentUser(data);
                                }).length;

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
                          color: isSelected
                              ? CustomBottomNav.activeColor
                              : CustomBottomNav.navColor,
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