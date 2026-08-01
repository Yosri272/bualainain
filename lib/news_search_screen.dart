import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

class NewsSearchScreen extends StatefulWidget {
  const NewsSearchScreen({super.key});

  static const Color blue = Color(0xff5E7FCB);
  static const Color mint = Color(0xff9FE2D4);
  static const Color textColor = Color(0xff53617F);

  @override
  State<NewsSearchScreen> createState() => _NewsSearchScreenState();
}

class _NewsSearchScreenState extends State<NewsSearchScreen> {
  final TextEditingController searchController = TextEditingController();

  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// يتحقق هل الخبر يطابق كلمة البحث في العنوان أو المحتوى أو اسم القسم
  bool _matches(Map<String, dynamic> data, String normalizedQuery) {
    final String title = (data['title'] ?? '').toString().toLowerCase();
    final String content = (data['content'] ?? '').toString().toLowerCase();
    final String categoryName =
    (data['categoryName'] ?? '').toString().toLowerCase();

    return title.contains(normalizedQuery) ||
        content.contains(normalizedQuery) ||
        categoryName.contains(normalizedQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _searchHeader(context),
              Expanded(
                child: query.trim().isEmpty
                    ? const _EmptyState(
                  icon: Icons.search,
                  message: 'اكتب كلمة للبحث عن الأخبار',
                )
                    : _resultsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: NewsSearchScreen.textColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xffF6F6F6),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: Color(0xffC9C9C9),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      textAlign: TextAlign.right,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) {
                        setState(() {
                          query = value;
                        });
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'اكتب ماتريد البحث عنه',
                        hintStyle: TextStyle(
                          color: Color(0xffCFCFCF),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        isCollapsed: true,
                      ),
                    ),
                  ),
                  if (query.isNotEmpty)
                    InkWell(
                      onTap: () {
                        searchController.clear();
                        setState(() {
                          query = '';
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        color: Color(0xffC9C9C9),
                        size: 20,
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

  Widget _resultsList() {
    final String normalizedQuery = query.trim().toLowerCase();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('news')
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                snapshot.error.toString(),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final List<QueryDocumentSnapshot<Map<String, dynamic>>> results =
        (snapshot.data?.docs ?? [])
            .where((doc) => _matches(doc.data(), normalizedQuery))
            .toList();

        if (results.isEmpty) {
          return const _EmptyState(
            icon: Icons.search_off,
            message: 'لا توجد نتائج مطابقة لبحثك',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = results[index].data();

            final String imageUrl = (data['imageUrl'] ?? '').toString();

            final Timestamp? createdAt = data['createdAt'];

            final String formattedDate = createdAt != null
                ? DateFormat('dd.MM.yyyy').format(createdAt.toDate())
                : '';

            return InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/news-details',
                  arguments: results[index].id,
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/news.png',
                          fit: BoxFit.cover,
                        ),
                      )
                          : Image.asset(
                        'assets/images/news.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 90,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              NewsSearchScreen.mint,
                              NewsSearchScreen.blue,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${data['categoryName'] ?? ''} | ${data['city'] ?? ''} | $formattedDate',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: NewsSearchScreen.textColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data['title'] ?? '',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: const Color(0xffCFCFCF),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: NewsSearchScreen.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}