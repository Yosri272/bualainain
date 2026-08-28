import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'widgets/custom_bottom_nav.dart';
import 'services/session_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const Color textColor = Color(0xff53617F);

  // القيم الافتراضية تُستخدم فقط لو المستخدم ما ضبطش تفضيلاته من قبل
  // (يعني أول مرة يفتح فيها هذه الشاشة، قبل أي حفظ في notification_settings).
  bool newsNotification = true;
  bool eventsNotification = false;
  bool congratulationsNotification = true;
  bool condolencesNotification = true;

  String? currentUserId;
  bool isLoadingPrefs = true;

  CollectionReference<Map<String, dynamic>> get _prefsCol =>
      FirebaseFirestore.instance.collection('notification_settings');

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final id = await SessionService.getUserId();
    if (mounted) {
      setState(() => currentUserId = id);
    }
    if (id != null) {
      await _loadPreferences(id);
    } else if (mounted) {
      setState(() => isLoadingPrefs = false);
    }
  }

  Future<void> _loadPreferences(String userId) async {
    try {
      final doc = await _prefsCol.doc(userId).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          newsNotification = data['news'] ?? true;
          eventsNotification = data['events'] ?? false;
          congratulationsNotification = data['congratulations'] ?? true;
          condolencesNotification = data['condolences'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('خطأ أثناء تحميل تفضيلات الإشعارات: $e');
    } finally {
      if (mounted) setState(() => isLoadingPrefs = false);
    }
  }

  /// يحفظ التفضيل فورًا في Firestore بمجرد تغييره (بدون زر حفظ منفصل).
  Future<void> _updatePreference(String key, bool value) async {
    if (currentUserId == null) return;

    try {
      await _prefsCol.doc(currentUserId).set({
        key: value,
        'userId': currentUserId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('خطأ أثناء حفظ تفضيل الإشعارات: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ التغيير، حاول مرة أخرى')),
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

            _profileHeaderInfo(),

            const SizedBox(height: 45),

            Expanded(
              child: isLoadingPrefs
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34),
                child: Column(
                  children: [
                    _NotificationItem(
                      title: 'تنبيهات الأخبار',
                      value: newsNotification,
                      onChanged: (value) {
                        setState(() => newsNotification = value);
                        _updatePreference('news', value);
                      },
                    ),

                    const SizedBox(height: 14),

                    _NotificationItem(
                      title: 'تنبيهات المناسبات',
                      value: eventsNotification,
                      onChanged: (value) {
                        setState(() => eventsNotification = value);
                        _updatePreference('events', value);
                      },
                    ),

                    const SizedBox(height: 14),

                    _NotificationItem(
                      title: 'تنبيهات التهاني والتبريكات',
                      value: congratulationsNotification,
                      onChanged: (value) {
                        setState(() => congratulationsNotification = value);
                        _updatePreference('congratulations', value);
                      },
                    ),

                    const SizedBox(height: 14),

                    _NotificationItem(
                      title: 'تنبيهات التعازي والمواساة',
                      value: condolencesNotification,
                      onChanged: (value) {
                        setState(() => condolencesNotification = value);
                        _updatePreference('condolences', value);
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

  Widget _profileHeaderInfo() {
    if (currentUserId == null) {
      return Column(
        children: const [
          CircleAvatar(
            radius: 38,
            backgroundImage: AssetImage('assets/images/profile.png'),
          ),
          SizedBox(height: 10),
          Text(
            'مستخدم',
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        String name = 'مستخدم';
        String? photoUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? 'مستخدم';
          photoUrl = data['photoUrl'];
        }

        final ImageProvider avatarImage = (photoUrl != null && photoUrl.isNotEmpty)
            ? NetworkImage(photoUrl)
            : const AssetImage('assets/images/profile.png') as ImageProvider;

        return Column(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              backgroundImage: avatarImage,
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
      },
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