import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/custom_bottom_nav.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class NewsDetailsScreen extends StatelessWidget {
  const NewsDetailsScreen({super.key});

  static const Color textColor = Color(0xff53617F);

  @override
  Widget build(BuildContext context) {
    final newsId = ModalRoute.of(context)?.settings.arguments as String?;
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
                      '/news',
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
              child: newsId == null
                  ? const Center(child: Text('لم يتم العثور على الخبر'))
                  : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('news')
                    .doc(newsId)
                    .get(),
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

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                      child: Text('الخبر غير موجود'),
                    );
                  }

                  final data =
                  snapshot.data!.data() as Map<String, dynamic>;
                  final Timestamp? createdAt = data['createdAt'];
                  final String formattedDate = createdAt != null
                      ? DateFormat('dd.MM.yyyy').format(createdAt.toDate())
                      : '';
                  final imageUrl = data['imageUrl'] ?? '';
                  final categoryName = data['categoryName'] ?? '';
                  final city = data['city'] ?? '';
                  final title = data['title'] ?? '';
                  final content = data['content'] ?? '';
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            height: 248,
                            width: double.infinity,
                            child: imageUrl.toString().isNotEmpty
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
                        ),

                        const SizedBox(height: 18),

                        Text(
                          '$categoryName | $city | $formattedDate',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Color(0xff9A9A9A),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          title,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 22),

                        Text(
                          content,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Color(0xff222222),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.9,
                          ),
                        ),
                      ],
                    ),
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
          image: AssetImage('assets/images/header_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}