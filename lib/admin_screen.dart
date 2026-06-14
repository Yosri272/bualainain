import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/custom_status_bar.dart';
import 'widgets/custom_bottom_nav.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const Color textColor = Color(0xff53617F);

  final DocumentReference<Map<String, dynamic>> settingsRef =
  FirebaseFirestore.instance
      .collection('app_settings')
      .doc('notifications');

  bool news = true;
  bool events = false;
  bool congrats = true;
  bool condolences = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final doc = await settingsRef.get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        news = data['news'] ?? true;
        events = data['events'] ?? false;
        congrats = data['congrats'] ?? true;
        condolences = data['condolences'] ?? false;
      } else {
        await settingsRef.set({
          'news': news,
          'events': events,
          'congrats': congrats,
          'condolences': condolences,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      showMessage('خطأ في تحميل الإعدادات');
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateSetting(String key, bool value) async {
    setState(() {
      if (key == 'news') news = value;
      if (key == 'events') events = value;
      if (key == 'congrats') congrats = value;
      if (key == 'condolences') condolences = value;
    });

    try {
      await settingsRef.set({
        key: value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      showMessage('لم يتم حفظ التعديل');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Stream<int> countStream(String collection) {
    return FirebaseFirestore.instance
        .collection(collection)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
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
            Expanded(
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _statsCard(),
                    const SizedBox(height: 24),
                    _adminCard(context),
                    const SizedBox(height: 24),
                    _notificationsCard(),
                  ],
                ),
              ),
            ),
            const CustomBottomNav(selectedIndex: 3),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
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
          const Positioned(
            top: 18,
            left: 0,
            right: 0,
            child: CustomStatusBar(),
          ),
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

  Widget _statsCard() {
    return _SectionCard(
      title: 'إحصائيات التطبيق',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatBox(
              title: 'المستخدمين',
              stream: countStream('users'),
            ),
            _StatBox(
              title: 'الأخبار',
              stream: countStream('news'),
            ),
            _StatBox(
              title: 'الأعضاء',
              stream: countStream('members'),
            ),
            _StatBox(
              title: 'الأقسام',
              stream: countStream('categories'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminCard(BuildContext context) {
    return _SectionCard(
      title: 'إدارة التطبيق',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _AdminButton(
              title: 'إضافة عضو',
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
                Navigator.pushNamed(context, '/add-member');
              },
            ),
            _AdminButton(
              title: 'إضافة خبر',
              icon: SvgPicture.asset(
                'assets/icons/book-reader.svg',
                width: 19,
                height: 19,
                colorFilter: const ColorFilter.mode(
                  Color(0xff53617F),
                  BlendMode.srcIn,
                ),
              ),
              onTap: () {
                Navigator.pushNamed(context, '/add-news');
              },
            ),
            _AdminButton(
              title: 'إدارة الأعضاء',
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
                Navigator.pushNamed(context, '/members-management');
              },
            ),
            _AdminButton(
              title: 'إضافة أقسام',
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
                Navigator.pushNamed(context, '/add-category');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationsCard() {
    return _SectionCard(
      title: 'إدارة إشعارات التطبيق',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          children: [
            _NotificationRow(
              title: 'تنبيهات الأخبار',
              value: news,
              onChanged: (value) {
                updateSetting('news', value);
              },
            ),
            const SizedBox(height: 14),
            _NotificationRow(
              title: 'تنبيهات المناسبات',
              value: events,
              onChanged: (value) {
                updateSetting('events', value);
              },
            ),
            const SizedBox(height: 14),
            _NotificationRow(
              title: 'تنبيهات التهاني والتبريكات',
              value: congrats,
              onChanged: (value) {
                updateSetting('congrats', value);
              },
            ),
            const SizedBox(height: 14),
            _NotificationRow(
              title: 'تنبيهات التعازي والمواساة',
              value: condolences,
              onChanged: (value) {
                updateSetting('condolences', value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final Stream<int> stream;

  const _StatBox({
    required this.title,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xffF5F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: StreamBuilder<int>(
        stream: stream,
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Color(0xff53617F),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff222222),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffE6E6E6)),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 58,
            width: double.infinity,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: const BoxDecoration(
              color: Color(0xffF8F8F8),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xff222222),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _AdminButton extends StatelessWidget {
  final String title;
  final Widget icon;
  final VoidCallback? onTap;

  const _AdminButton({
    required this.title,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 68,
        height: 76,
        decoration: BoxDecoration(
          color: const Color(0xffF5F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xff222222),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
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
                color: Color(0xff222222),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.82,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
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