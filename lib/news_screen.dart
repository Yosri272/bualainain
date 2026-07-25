import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/custom_bottom_nav.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  static const Color textColor = Color(0xff53617F);
  static const Color blue = Color(0xff5E7FCB);
  static const Color mint = Color(0xff9FE2D4);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _header(),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
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
            ),

            const SizedBox(height: 26),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('news')
                    .where('isPublished', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد أخبار',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }

                  final news = snapshot.data!.docs;

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    itemCount: news.length,
                    separatorBuilder: (_, __) {
                      return const SizedBox(height: 10);
                    },
                    itemBuilder: (context, index) {
                      final data = news[index].data()
                      as Map<String, dynamic>;

                      final Timestamp? createdAt =
                      data['createdAt'] as Timestamp?;

                      final String formattedDate =
                      createdAt != null
                          ? DateFormat('dd.MM.yyyy').format(
                        createdAt.toDate(),
                      )
                          : '';

                      /*
                       * يدعم الأخبار الجديدة والقديمة.
                       *
                       * الأخبار الجديدة:
                       * mediaType: image أو video
                       * mediaUrl: رابط الصورة أو الفيديو
                       *
                       * الأخبار القديمة:
                       * imageUrl أو videoUrl
                       */
                      final String videoUrl =
                      (data['videoUrl'] ?? '')
                          .toString()
                          .trim();

                      final String imageUrl =
                      (data['imageUrl'] ?? '')
                          .toString()
                          .trim();

                      final String savedMediaType =
                      (data['mediaType'] ?? '')
                          .toString()
                          .trim()
                          .toLowerCase();

                      final bool isVideo =
                          savedMediaType == 'video' ||
                              videoUrl.isNotEmpty;

                      final String mediaType =
                      isVideo ? 'video' : 'image';

                      final String mediaUrl =
                      (data['mediaUrl'] ??
                          (isVideo
                              ? videoUrl
                              : imageUrl))
                          .toString()
                          .trim();

                      /*
                       * اختياري:
                       * عند إضافة thumbnailUrl للفيديو مستقبلًا،
                       * ستظهر صورة مصغرة بدل الصورة الافتراضية.
                       */
                      final String thumbnailUrl =
                      (data['thumbnailUrl'] ?? '')
                          .toString()
                          .trim();

                      return _NewsCard(
                        title:
                        (data['title'] ?? '').toString(),
                        content:
                        (data['content'] ?? '').toString(),
                        categoryName:
                        (data['categoryName'] ?? '')
                            .toString(),
                        city:
                        (data['city'] ?? '').toString(),
                        mediaUrl: mediaUrl,
                        mediaType: mediaType,
                        thumbnailUrl: thumbnailUrl,
                        date: formattedDate,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/news-details',
                            arguments: news[index].id,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            const CustomBottomNav(selectedIndex: 1),
          ],
        ),
      ),
    );
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
}

class _NewsCard extends StatelessWidget {
  final String title;
  final String content;
  final String categoryName;
  final String city;

  final String mediaUrl;
  final String mediaType;
  final String thumbnailUrl;

  final String date;
  final VoidCallback onTap;

  const _NewsCard({
    required this.title,
    required this.content,
    required this.categoryName,
    required this.city,
    required this.mediaUrl,
    required this.mediaType,
    required this.thumbnailUrl,
    required this.date,
    required this.onTap,
  });

  static const Color blue = Color(0xff5E7FCB);
  static const Color mint = Color(0xff9FE2D4);
  static const Color textColor = Color(0xff53617F);

  bool get isVideo => mediaType == 'video';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        height: 306,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .10),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(
              height: 215,
              width: double.infinity,
              child: isVideo
                  ? _buildVideoCover()
                  : _buildImageCover(),
            ),

            Container(
              height: 91,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    mint,
                    blue,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '$categoryName | $city | $date',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 9),

                  Text(
                    title.isNotEmpty ? title : content,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// عرض صورة الخبر العادي
  Widget _buildImageCover() {
    if (mediaUrl.isEmpty) {
      return Image.asset(
        'assets/images/news.png',
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      mediaUrl,
      fit: BoxFit.cover,
      loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? loadingProgress,
          ) {
        if (loadingProgress == null) {
          return child;
        }

        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      errorBuilder: (_, __, ___) {
        return Image.asset(
          'assets/images/news.png',
          fit: BoxFit.cover,
        );
      },
    );
  }

  /// عرض غلاف الفيديو مع علامة فيديو
  Widget _buildVideoCover() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // إذا توفر thumbnailUrl تظهر الصورة المصغرة.
        // وإلا تظهر الصورة الافتراضية.
        thumbnailUrl.isNotEmpty
            ? Image.network(
          thumbnailUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Image.asset(
              'assets/images/news.png',
              fit: BoxFit.cover,
            );
          },
        )
            : Image.asset(
          'assets/images/news.png',
          fit: BoxFit.cover,
        ),

        // طبقة خفيفة لإظهار زر التشغيل
        Container(
          color: Colors.black.withValues(alpha: 0.20),
        ),

        // زر التشغيل في المنتصف
        const Center(
          child: Icon(
            Icons.play_circle_fill_rounded,
            color: Colors.white,
            size: 58,
          ),
        ),

        // شارة فيديو
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videocam_rounded,
                  color: Colors.white,
                  size: 15,
                ),
                SizedBox(width: 4),
                Text(
                  'فيديو',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}