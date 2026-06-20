import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AddNewsScreen extends StatefulWidget {
  const AddNewsScreen({super.key});

  static const Color blue = Color(0xff5E7FCB);
  static const Color mint = Color(0xff9FE2D4);
  static const Color textColor = Color(0xff53617F);

  @override
  State<AddNewsScreen> createState() => _AddNewsScreenState();
}

class _AddNewsScreenState extends State<AddNewsScreen> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final cityController = TextEditingController();
  final imageUrlController = TextEditingController();
  static const Color textColor = Color(0xff53617F);



  String? selectedCategoryId;
  String? selectedCategoryName;

  bool isLoading = false;

  Future<void> saveNews() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();
    final city = cityController.text.trim();
    final imageUrl = imageUrlController.text.trim();

    if (title.isEmpty) {
      showMessage('الرجاء إدخال عنوان الخبر');
      return;
    }

    if (selectedCategoryId == null) {
      showMessage('الرجاء اختيار التصنيف');
      return;
    }

    if (content.isEmpty) {
      showMessage('الرجاء كتابة محتوى الخبر');
      return;
    }

    try {
      setState(() => isLoading = true);

      await FirebaseFirestore.instance.collection('news').add({
        'title': title,
        'content': content,
        'city': city.isEmpty ? 'الرياض' : city,
        'imageUrl': imageUrl,
        'categoryId': selectedCategoryId,
        'categoryName': selectedCategoryName,
        'authorId': '',
        'authorName': 'الإدارة',
        'isPublished': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'body': content,
        'type': 'news',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'تم بنجاح',
              textAlign: TextAlign.right,
            ),
            content: const Text(
              'تم إضافة خبر بنجاح',
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('موافق'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/admin',
            (route) => false,
      );

    } catch (e) {
      showMessage('خطأ في حفظ الخبر: $e');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    cityController.dispose();
    imageUrlController.dispose();
    super.dispose();
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: _formCard(),
              ),
            ),
          ],
        ),
      ),
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
                  '/admin',
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
  Widget _formCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffE6E6E6)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            height: 58,
            width: double.infinity,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: const BoxDecoration(
              color: Color(0xffF8F8F8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: const Text(
              'إضافة خبر',
              style: TextStyle(
                color: Color(0xff222222),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _InputField(
                  controller: titleController,
                  hint: 'عنوان الخبر',
                ),
                const SizedBox(height: 14),
                _InputField(
                  controller: cityController,
                  hint: 'المدينة',
                ),
                const SizedBox(height: 14),
                _CategoryDropdown(
                  selectedCategoryId: selectedCategoryId,
                  onChanged: (id, name) {
                    setState(() {
                      selectedCategoryId = id;
                      selectedCategoryName = name;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _InputField(
                  controller: imageUrlController,
                  hint: 'رابط الصورة',
                ),
                const SizedBox(height: 14),
                _InputField(
                  controller: contentController,
                  hint: 'اكتب هنا ...',
                  height: 190,
                  maxLines: 8,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: isLoading ? null : saveNews,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AddNewsScreen.textColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'ارسال الخبر',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String? selectedCategoryId;
  final void Function(String id, String name) onChanged;

  const _CategoryDropdown({
    required this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xffF6F6F6),
        borderRadius: BorderRadius.circular(3),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('categories')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('خطأ في تحميل الأقسام'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('لا توجد أقسام'));
          }

          return DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCategoryId,
              isExpanded: true,
              hint: const Text('اختر التصنيف'),
              items: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name'] ?? 'قسم';

                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(name),
                  onTap: () {
                    onChanged(doc.id, name);
                  },
                );
              }).toList(),
              onChanged: (_) {},
            ),
          );
        },
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final double height;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.hint,
    this.height = 52,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xffF6F6F6),
        borderRadius: BorderRadius.circular(3),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xffC2C2C2),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}