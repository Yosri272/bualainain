import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  static const Color textColor = Color(0xff53617F);

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  static const Color textColor = AddCategoryScreen.textColor;

  final TextEditingController nameController = TextEditingController();

  final TextEditingController descriptionController =
  TextEditingController();

  File? selectedImage;
  bool isLoading = false;

  /// اختيار صورة القسم من معرض الصور
  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
        requestFullMetadata: false,
      );

      if (image == null || !mounted) return;

      setState(() {
        selectedImage = File(image.path);
      });
    } catch (error) {
      showMessage('تعذر اختيار الصورة: $error');
    }
  }

  void removeSelectedImage() {
    setState(() {
      selectedImage = null;
    });
  }

  /// رفع صورة القسم إلى Firebase Storage
  Future<String> uploadImage(String categoryId) async {
    if (selectedImage == null) {
      throw Exception('الرجاء اختيار صورة القسم');
    }

    final Reference imageReference = FirebaseStorage.instance
        .ref()
        .child('categories')
        .child(categoryId)
        .child('image.jpg');

    final SettableMetadata metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'categoryId': categoryId,
      },
    );

    final UploadTask uploadTask = imageReference.putFile(
      selectedImage!,
      metadata,
    );

    final TaskSnapshot snapshot = await uploadTask;

    return snapshot.ref.getDownloadURL();
  }

  /// حفظ بيانات القسم ورابط الصورة في Firestore
  Future<void> saveCategory() async {
    final String name = nameController.text.trim();
    final String description = descriptionController.text.trim();

    if (name.isEmpty) {
      showMessage('الرجاء إدخال اسم القسم');
      return;
    }

    if (selectedImage == null) {
      showMessage('الرجاء اختيار صورة القسم');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      // إنشاء رقم مستند جديد قبل رفع الصورة
      final DocumentReference<Map<String, dynamic>> categoryReference =
      FirebaseFirestore.instance.collection('categories').doc();

      // رفع الصورة في مجلد يحمل نفس رقم مستند القسم
      final String imageUrl = await uploadImage(categoryReference.id);

      // حفظ بيانات القسم في Firestore
      await categoryReference.set({
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'storagePath': 'categories/${categoryReference.id}/image.jpg',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                'تم بنجاح',
                textAlign: TextAlign.right,
              ),
              content: const Text(
                'تم إضافة القسم بنجاح',
                textAlign: TextAlign.right,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('موافق'),
                ),
              ],
            ),
          );
        },
      );

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/admin',
            (Route<dynamic> route) => false,
      );
    } on FirebaseException catch (error) {
      showMessage(
        'خطأ Firebase: ${error.code}\n'
            '${error.message ?? 'حدث خطأ غير معروف'}',
      );
    } catch (error) {
      showMessage('خطأ في حفظ القسم: $error');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
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

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xffE6E6E6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 56,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xffE6E6E6),
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Text(
                          'اضافة قسم',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _InputField(
                              controller: nameController,
                              hint: 'اسم القسم',
                              enabled: !isLoading,
                            ),

                            const SizedBox(height: 12),

                            _InputField(
                              controller: descriptionController,
                              hint: 'اكتب هنا ...',
                              height: 150,
                              maxLines: 6,
                              enabled: !isLoading,
                            ),

                            const SizedBox(height: 12),

                            if (selectedImage != null) ...[
                              _SelectedImagePreview(
                                image: selectedImage!,
                                onRemove:
                                isLoading ? null : removeSelectedImage,
                              ),
                              const SizedBox(height: 12),
                            ],

                            _MediaButton(
                              label: selectedImage == null
                                  ? 'اضف صورة القسم'
                                  : 'تغيير الصورة',
                              onTap: isLoading ? null : pickImage,
                            ),

                            const SizedBox(height: 12),

                            _SubmitButton(
                              label: 'حفظ القسم',
                              isLoading: isLoading,
                              onTap: isLoading ? null : saveCategory,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                      (Route<dynamic> route) => false,
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

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final double height;
  final int maxLines;
  final bool enabled;

  const _InputField({
    required this.controller,
    required this.hint,
    this.height = 52,
    this.maxLines = 1,
    this.enabled = true,
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
        enabled: enabled,
        maxLines: maxLines,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
        ),
      ),
    );
  }
}

/// زر "اضف الوسائط" بنفس تدرج اللون المستخدم في شاشة إضافة الخبر.
class _MediaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _MediaButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 52,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xffA9B4D6),
              Color(0xff5B6C99),
            ],
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// زر "ارسال" الرئيسي بنفس لون ونمط شاشة إضافة الخبر.
class _SubmitButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 52,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AddCategoryScreen.textColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: isLoading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SelectedImagePreview extends StatelessWidget {
  final File image;
  final VoidCallback? onRemove;

  const _SelectedImagePreview({
    required this.image,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xffF6F6F6),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 18,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'تم اختيار صورة القسم',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AddCategoryScreen.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              image,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}