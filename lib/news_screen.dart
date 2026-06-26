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
            _header(context),

            const SizedBox(height: 44),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('news')
                    .where('isPublished', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    itemCount: news.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 18),
                    itemBuilder: (context, index) {
                      final data = news[index].data() as Map<String, dynamic>;
                      final Timestamp? createdAt = data['createdAt'];

                      final String formattedDate = createdAt != null
                          ? DateFormat('d MMMM yyyy', 'ar')
                          .format(createdAt.toDate())
                          : '';

                      return _NewsCard(
                        title: data['title'] ?? '',
                        content: data['content'] ?? '',
                        categoryName: data['categoryName'] ?? '',
                        city: data['city'] ?? '',
                        imageUrl: data['imageUrl'] ?? '',
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
          Positioned(
            right: 24,
            bottom: -35,
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

class _NewsCard extends StatelessWidget {
  final String title;
  final String content;
  final String categoryName;
  final String city;
  final String imageUrl;
  final String date;
  final VoidCallback onTap;

  const _NewsCard({
    required this.title,
    required this.content,
    required this.categoryName,
    required this.city,
    required this.date,
    required this.imageUrl,
    required this.onTap,
  });

  static const Color blue = Color(0xff5E7FCB);
  static const Color mint = Color(0xff9FE2D4);
  static const Color textColor = Color(0xff53617F);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        height: 285,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.10),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
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
            ),

            Container(
              height: 85,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [mint, blue],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '$categoryName | $city | $date',
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
                    textAlign: TextAlign.center,
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
}