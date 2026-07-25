import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'widgets/custom_bottom_nav.dart';

enum NotificationFilter {
  all,
  unread,
  read,
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static const Color textColor = Color(0xff53617F);
  static const Color titleColor = Color(0xff2E3547);
  static const Color blue = Color(0xff5D7FCB);
  static const Color bgColor = Color(0xffF4F6FA);

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationFilter selectedFilter = NotificationFilter.all;

  String get currentUserId {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  DateTime? _getCreatedAt(Map<String, dynamic> data) {
    final value = data['createdAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  /// يدعم newsId وأسماء الحقول القديمة أو البديلة.
  String _getNewsId(Map<String, dynamic> data) {
    final possibleValues = [
      data['newsId'],
      data['news_id'],
      data['relatedNewsId'],
      data['postId'],
      data['referenceId'],
    ];

    for (final value in possibleValues) {
      final id = value?.toString().trim() ?? '';

      if (id.isNotEmpty && id != 'null') {
        return id;
      }
    }

    return '';
  }

  bool _isReadByCurrentUser(Map<String, dynamic> data) {
    final readBy = data['readBy'];

    /*
     الإشعارات الجديدة:
     حالة القراءة منفصلة لكل مستخدم.
    */
    if (readBy is List && currentUserId.isNotEmpty) {
      return readBy.contains(currentUserId);
    }

    /*
     دعم الإشعارات القديمة التي كانت تستخدم isRead.
    */
    return data['isRead'] == true;
  }

  List<QueryDocumentSnapshot> _filterNotifications(
      List<QueryDocumentSnapshot> notifications,
      ) {
    switch (selectedFilter) {
      case NotificationFilter.unread:
        return notifications.where((document) {
          final data = document.data() as Map<String, dynamic>;

          return !_isReadByCurrentUser(data);
        }).toList();

      case NotificationFilter.read:
        return notifications.where((document) {
          final data = document.data() as Map<String, dynamic>;

          return _isReadByCurrentUser(data);
        }).toList();

      case NotificationFilter.all:
        return notifications;
    }
  }

  int _unreadCount(
      List<QueryDocumentSnapshot> notifications,
      ) {
    return notifications.where((document) {
      final data = document.data() as Map<String, dynamic>;

      return !_isReadByCurrentUser(data);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: NotificationsScreen.bgColor,
        body: Column(
          children: [
            _header(),

            const SizedBox(height: 40),

            _backButton(),

            const SizedBox(height: 18),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: NotificationsScreen.blue,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _errorWidget();
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return _emptyWidget(
                      message: 'لا توجد إشعارات حتى الآن',
                    );
                  }

                  final notifications = snapshot.data!.docs.toList();

                  /*
                   ترتيب أحدث إشعار في الأعلى.

                   الإشعارات التي لا تحتوي على createdAt
                   تظهر في نهاية القائمة.
                  */
                  notifications.sort((first, second) {
                    final firstData =
                    first.data() as Map<String, dynamic>;

                    final secondData =
                    second.data() as Map<String, dynamic>;

                    final firstDate = _getCreatedAt(firstData);
                    final secondDate = _getCreatedAt(secondData);

                    if (firstDate == null && secondDate == null) {
                      return 0;
                    }

                    if (firstDate == null) {
                      return 1;
                    }

                    if (secondDate == null) {
                      return -1;
                    }

                    return secondDate.compareTo(firstDate);
                  });

                  final unreadCount = _unreadCount(notifications);

                  final readCount =
                      notifications.length - unreadCount;

                  final filteredNotifications =
                  _filterNotifications(notifications);

                  return Column(
                    children: [
                      _filters(
                        totalCount: notifications.length,
                        unreadCount: unreadCount,
                        readCount: readCount,
                      ),

                      const SizedBox(height: 12),

                      Expanded(
                        child: filteredNotifications.isEmpty
                            ? _emptyWidget(
                          message: _emptyFilterMessage(),
                        )
                            : ListView.separated(
                          physics:
                          const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(
                            top: 4,
                            bottom: 12,
                          ),
                          itemCount:
                          filteredNotifications.length,
                          separatorBuilder:
                              (context, index) {
                            return const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xffE8EAF0),
                            );
                          },
                          itemBuilder: (context, index) {
                            final document =
                            filteredNotifications[index];

                            final data =
                            document.data()
                            as Map<String, dynamic>;

                            final title =
                            data['title']
                                ?.toString()
                                .trim();

                            return _NotificationItem(
                              key: ValueKey(document.id),
                              id: document.id,
                              userId: currentUserId,
                              title: title != null &&
                                  title.isNotEmpty
                                  ? title
                                  : 'إشعار جديد',
                              body:
                              data['body']?.toString() ??
                                  '',
                              type:
                              data['type']?.toString() ??
                                  '',
                              newsId: _getNewsId(data),
                              isRead:
                              _isReadByCurrentUser(data),
                              createdAt:
                              _getCreatedAt(data),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const CustomBottomNav(
              selectedIndex: 2,
            ),
          ],
        ),
      ),
    );
  }

  String _emptyFilterMessage() {
    switch (selectedFilter) {
      case NotificationFilter.read:
        return 'لا توجد إشعارات مقروءة';

      case NotificationFilter.unread:
        return 'جميع الإشعارات تمت قراءتها';

      case NotificationFilter.all:
        return 'لا توجد إشعارات حتى الآن';
    }
  }

  Widget _header() {
    return Container(
      height: 90,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            'assets/images/header_bg.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _backButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
                  (route) => false,
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios_new,
                  size: 15,
                  color: NotificationsScreen.textColor,
                ),
                SizedBox(width: 6),
                Text(
                  'العودة',
                  style: TextStyle(
                    color: NotificationsScreen.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filters({
    required int totalCount,
    required int unreadCount,
    required int readCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Container(
        height: 52,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xffE4E8F1),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _filterButton(
                title: 'الكل',
                count: totalCount,
                filter: NotificationFilter.all,
              ),
            ),

            const SizedBox(width: 4),

            Expanded(
              child: _filterButton(
                title: 'غير المقروء',
                count: unreadCount,
                filter: NotificationFilter.unread,
              ),
            ),

            const SizedBox(width: 4),

            Expanded(
              child: _filterButton(
                title: 'المقروء',
                count: readCount,
                filter: NotificationFilter.read,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterButton({
    required String title,
    required int count,
    required NotificationFilter filter,
  }) {
    final isSelected = selectedFilter == filter;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (selectedFilter == filter) return;

          setState(() {
            selectedFilter = filter;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? NotificationsScreen.blue
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : NotificationsScreen.textColor,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                constraints: const BoxConstraints(
                  minWidth: 21,
                  minHeight: 21,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0x33FFFFFF)
                      : const Color(0xffEEF2FA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count > 99 ? '+99' : count.toString(),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : NotificationsScreen.blue,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 34,
            ),
            SizedBox(height: 12),
            Text(
              'حدث خطأ أثناء تحميل الإشعارات',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyWidget({
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: Color(0xffEAF0FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 32,
              color: NotificationsScreen.blue,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: NotificationsScreen.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatefulWidget {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String newsId;
  final DateTime? createdAt;

  const _NotificationItem({
    super.key,
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.newsId,
    required this.createdAt,
  });

  @override
  State<_NotificationItem> createState() =>
      _NotificationItemState();
}

class _NotificationItemState extends State<_NotificationItem> {
  bool isOpening = false;

  IconData get _icon {
    switch (widget.type) {
      case 'news':
        return Icons.article_outlined;

      case 'events':
        return Icons.event_available_outlined;

      case 'congratulations':
        return Icons.celebration_outlined;

      case 'condolences':
        return Icons.volunteer_activism_outlined;

      default:
        return Icons.notifications_none_outlined;
    }
  }

  String get _typeText {
    switch (widget.type) {
      case 'news':
        return 'خبر جديد';

      case 'events':
        return 'مناسبة جديدة';

      case 'congratulations':
        return 'تهنئة جديدة';

      case 'condolences':
        return 'تعزية جديدة';

      default:
        return 'إشعار جديد';
    }
  }

  String get _timeText {
    final createdAt = widget.createdAt;

    if (createdAt == null) {
      return 'منذ فترة';
    }

    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.isNegative ||
        difference.inSeconds < 60) {
      return 'الآن';
    }

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;

      if (hours == 1) {
        return 'منذ ساعة';
      }

      if (hours == 2) {
        return 'منذ ساعتين';
      }

      if (hours >= 3 && hours <= 10) {
        return 'منذ $hours ساعات';
      }

      return 'منذ $hours ساعة';
    }

    if (difference.inDays < 7) {
      final days = difference.inDays;

      if (days == 1) {
        return 'منذ يوم';
      }

      if (days == 2) {
        return 'منذ يومين';
      }

      return 'منذ $days أيام';
    }

    final day =
    createdAt.day.toString().padLeft(2, '0');

    final month =
    createdAt.month.toString().padLeft(2, '0');

    return '$day/$month/${createdAt.year}';
  }

  Future<bool> _markAsRead() async {
    if (widget.isRead) {
      return true;
    }

    if (widget.userId.isEmpty) {
      return false;
    }

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(widget.id)
          .set({
        'readBy': FieldValue.arrayUnion([
          widget.userId,
        ]),
      }, SetOptions(merge: true));

      return true;
    } catch (error) {
      debugPrint(
        'خطأ أثناء تحديث حالة الإشعار: $error',
      );

      return false;
    }
  }

  /// البحث عن رقم الخبر المرتبط بالإشعار.
  ///
  /// أولًا يستخدم newsId المحفوظ.
  /// إذا لم يوجد، يبحث عن خبر له نفس العنوان.
  Future<String> _resolveNewsId() async {
    final directNewsId = widget.newsId.trim();

    if (directNewsId.isNotEmpty) {
      final newsDocument = await FirebaseFirestore.instance
          .collection('news')
          .doc(directNewsId)
          .get();

      if (newsDocument.exists) {
        return directNewsId;
      }
    }

    final notificationTitle = widget.title.trim();

    if (notificationTitle.isEmpty ||
        notificationTitle == 'إشعار جديد') {
      return '';
    }

    try {
      final newsResult = await FirebaseFirestore.instance
          .collection('news')
          .where(
        'title',
        isEqualTo: notificationTitle,
      )
          .limit(1)
          .get();

      if (newsResult.docs.isEmpty) {
        return '';
      }

      final foundNewsId = newsResult.docs.first.id;

      /*
       حفظ newsId في الإشعار القديم،
       حتى لا نحتاج إلى البحث مرة أخرى.
      */
      try {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(widget.id)
            .set({
          'newsId': foundNewsId,
        }, SetOptions(merge: true));
      } catch (error) {
        debugPrint(
          'تم العثور على الخبر، لكن تعذر حفظ newsId: $error',
        );
      }

      return foundNewsId;
    } catch (error) {
      debugPrint(
        'خطأ أثناء البحث عن الخبر: $error',
      );

      return '';
    }
  }

  Future<void> _handleTap() async {
    if (isOpening) return;

    setState(() {
      isOpening = true;
    });

    try {
      /*
       نبحث عن الخبر أولًا قبل تغيير الفلتر
       أو تحديث الإشعار إلى مقروء.
      */
      if (widget.type == 'news') {
        final resolvedNewsId = await _resolveNewsId();

        if (!mounted) return;

        if (resolvedNewsId.isEmpty) {
          await _markAsRead();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'لم يتم العثور على الخبر المرتبط بهذا الإشعار',
              ),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );

          return;
        }

        /*
         مهم جدًا:

         نبدأ الانتقال أولًا، ثم نحدّث حالة القراءة.

         لو حدث تحديث القراءة أولًا والمستخدم داخل
         فلتر غير المقروء، ستختفي البطاقة وقد يتم
         التخلص من الـ Widget قبل تنفيذ Navigator.
        */
        final navigationFuture = Navigator.pushNamed(
          context,
          '/news-details',
          arguments: resolvedNewsId,
        );

        await _markAsRead();

        /*
         الانتظار حتى يعود المستخدم من صفحة الخبر.
        */
        await navigationFuture;

        return;
      }

      /*
       الأنواع غير المرتبطة بصفحة خبر.
      */
      await _markAsRead();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا توجد صفحة مرتبطة بهذا الإشعار',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      debugPrint(
        'خطأ عند فتح الإشعار: $error',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر فتح الخبر: $error',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isOpening = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: widget.isRead
          ? Colors.white
          : const Color(0xffF7F9FF),
      child: InkWell(
        onTap: isOpening ? null : _handleTap,
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
                child: isOpening
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: NotificationsScreen.blue,
                  ),
                )
                    : Icon(
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
                    Row(
                      children: [
                        Text(
                          _typeText,
                          style: const TextStyle(
                            color: NotificationsScreen.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const Spacer(),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isRead
                                ? const Color(0xffF1F3F7)
                                : const Color(0xffEAF0FF),
                            borderRadius:
                            BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.isRead
                                ? 'مقروء'
                                : 'غير مقروء',
                            style: TextStyle(
                              color: widget.isRead
                                  ? const Color(0xff8A94AA)
                                  : NotificationsScreen.blue,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.isRead
                            ? const Color(0xff8A94AA)
                            : NotificationsScreen.titleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),

                    if (widget.body.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),

                      Text(
                        widget.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.isRead
                              ? const Color(0xffA0A8B8)
                              : NotificationsScreen.textColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Color(0xff8A94AA),
                        ),

                        const SizedBox(width: 4),

                        Text(
                          _timeText,
                          style: const TextStyle(
                            color: Color(0xff8A94AA),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        if (widget.type == 'news') ...[
                          const Spacer(),

                          const Text(
                            'عرض الخبر',
                            style: TextStyle(
                              color: NotificationsScreen.blue,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(width: 3),

                          const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 11,
                            color: NotificationsScreen.blue,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              if (!widget.isRead)
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(
                    top: 7,
                    right: 6,
                  ),
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