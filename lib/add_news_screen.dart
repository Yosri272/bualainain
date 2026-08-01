import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'manage_categories_screen.dart';

class AddNewsScreen extends StatefulWidget {
  const AddNewsScreen({super.key});

  static const Color blue = Color(0xff5E7FCB);
  static const Color mint = Color(0xff9FE2D4);
  static const Color textColor = Color(0xff53617F);

  @override
  State<AddNewsScreen> createState() => _AddNewsScreenState();
}

class _AddNewsScreenState extends State<AddNewsScreen> {
  final TextEditingController titleController =
  TextEditingController();

  final TextEditingController contentController =
  TextEditingController();

  final TextEditingController cityController =
  TextEditingController();

  static const Color textColor = Color(0xff53617F);

  final ImagePicker mediaPicker = ImagePicker();

  String? selectedCategoryId;
  String? selectedCategoryName;

  XFile? selectedMedia;

  // القيمة تكون image أو video
  String? selectedMediaType;

  bool isLoading = false;

  static const Set<String> _videoExtensions = {
    'mp4', 'mov', 'm4v', 'webm', 'avi', 'mkv', '3gp',
  };

  /// اختيار صورة أو فيديو من نفس المعرض مباشرة (بدون قائمة اختيار نوع)
  Future<void> pickMedia() async {
    if (isLoading) return;

    try {
      final XFile? media = await mediaPicker.pickMedia(
        imageQuality: 80,
      );

      if (media == null || !mounted) return;

      final String extension = getFileExtension(media);
      final bool isVideo =
      _videoExtensions.contains(extension);

      final int fileSize = await media.length();

      final int maxSize =
      isVideo ? 50 * 1024 * 1024 : 5 * 1024 * 1024;

      if (fileSize > maxSize) {
        showMessage(
          isVideo
              ? 'حجم الفيديو كبير، يجب ألا يتجاوز 50 ميجابايت'
              : 'حجم الصورة كبير، يجب ألا يتجاوز 5 ميجابايت',
        );
        return;
      }

      setState(() {
        selectedMedia = media;
        selectedMediaType = isVideo ? 'video' : 'image';
      });
    } catch (error) {
      showMessage('تعذر اختيار الملف: $error');
    }
  }

  /// إزالة الملف المختار
  void removeSelectedMedia() {
    setState(() {
      selectedMedia = null;
      selectedMediaType = null;
    });
  }

  /// استخراج امتداد الملف
  String getFileExtension(XFile file) {
    String fileName = file.name.trim().toLowerCase();

    if (fileName.isEmpty) {
      fileName = file.path.trim().toLowerCase();
    }

    if (fileName.contains('.')) {
      final String extension =
          fileName.split('.').last.split('?').first;

      if (extension.isNotEmpty) {
        return extension;
      }
    }

    return selectedMediaType == 'video' ? 'mp4' : 'jpg';
  }

  /// تحديد نوع الملف المرسل إلى Firebase Storage
  String getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      case 'gif':
        return 'image/gif';

      case 'heic':
        return 'image/heic';

      case 'jpeg':
      case 'jpg':
        return 'image/jpeg';

      case 'mov':
        return 'video/quicktime';

      case 'm4v':
        return 'video/x-m4v';

      case 'webm':
        return 'video/webm';

      case 'avi':
        return 'video/x-msvideo';

      case 'mp4':
        return 'video/mp4';

      default:
        return selectedMediaType == 'video'
            ? 'video/mp4'
            : 'image/jpeg';
    }
  }

  /// رفع الصورة أو الفيديو إلى Firebase Storage
  Future<Map<String, String>> uploadMedia({
    required String newsId,
  }) async {
    if (selectedMedia == null ||
        selectedMediaType == null) {
      throw Exception('الرجاء اختيار صورة أو فيديو');
    }

    final String extension =
    getFileExtension(selectedMedia!);

    final String fileName =
    selectedMediaType == 'video'
        ? 'video.$extension'
        : 'image.$extension';

    final String storagePath =
        'news/$newsId/$fileName';

    final Reference storageReference =
    FirebaseStorage.instance
        .ref()
        .child(storagePath);

    final SettableMetadata metadata =
    SettableMetadata(
      contentType:
      selectedMedia!.mimeType ??
          getContentType(extension),
      customMetadata: {
        'newsId': newsId,
        'mediaType': selectedMediaType!,
      },
    );

    final UploadTask uploadTask =
    storageReference.putFile(
      File(selectedMedia!.path),
      metadata,
    );

    final TaskSnapshot snapshot =
    await uploadTask;

    final String mediaUrl =
    await snapshot.ref.getDownloadURL();

    return {
      'mediaUrl': mediaUrl,
      'mediaType': selectedMediaType!,
      'storagePath': storagePath,
    };
  }

  /// حفظ الخبر والإشعار بعد رفع الملف
  Future<void> saveNews() async {
    final String title =
    titleController.text.trim();

    final String content =
    contentController.text.trim();

    final String city =
    cityController.text.trim();

    if (title.isEmpty) {
      showMessage('الرجاء إدخال عنوان الخبر');
      return;
    }

    if (selectedCategoryId == null) {
      showMessage('الرجاء اختيار التصنيف');
      return;
    }

    if (selectedMedia == null ||
        selectedMediaType == null) {
      showMessage('الرجاء اختيار صورة أو فيديو');
      return;
    }

    if (content.isEmpty) {
      showMessage('الرجاء كتابة محتوى الخبر');
      return;
    }

    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      showMessage('يجب تسجيل الدخول أولاً');
      return;
    }

    Reference? uploadedFileReference;
    bool dataSaved = false;

    try {
      setState(() {
        isLoading = true;
      });

      // إنشاء رقم الخبر قبل رفع الملف
      final DocumentReference<Map<String, dynamic>>
      newsReference = FirebaseFirestore.instance
          .collection('news')
          .doc();

      // رفع الصورة أو الفيديو
      final Map<String, String> uploadedMedia =
      await uploadMedia(
        newsId: newsReference.id,
      );

      final String mediaUrl =
      uploadedMedia['mediaUrl']!;

      final String mediaType =
      uploadedMedia['mediaType']!;

      final String storagePath =
      uploadedMedia['storagePath']!;

      uploadedFileReference =
          FirebaseStorage.instance
              .ref()
              .child(storagePath);

      final DocumentReference<Map<String, dynamic>>
      notificationReference =
      FirebaseFirestore.instance
          .collection('notifications')
          .doc();

      final WriteBatch batch =
      FirebaseFirestore.instance.batch();

      // حفظ الخبر
      batch.set(newsReference, {
        'title': title,
        'content': content,
        'city': city.isEmpty ? 'الرياض' : city,

        // بيانات الصورة أو الفيديو
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'storagePath': storagePath,

        // الحقول القديمة للتوافق مع بقية التطبيق
        'imageUrl':
        mediaType == 'image' ? mediaUrl : '',
        'videoUrl':
        mediaType == 'video' ? mediaUrl : '',

        'categoryId': selectedCategoryId,
        'categoryName': selectedCategoryName,
        'authorId': currentUser.uid,
        'authorName': 'الإدارة',
        'isPublished': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // إنشاء الإشعار
      batch.set(notificationReference, {
        'newsId': newsReference.id,
        'title': title,
        'body': content,
        'type': 'news',
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'imageUrl':
        mediaType == 'image' ? mediaUrl : '',
        'videoUrl':
        mediaType == 'video' ? mediaUrl : '',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      dataSaved = true;

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'تم بنجاح',
              textAlign: TextAlign.right,
            ),
            content: Text(
              mediaType == 'video'
                  ? 'تم رفع الفيديو وإضافة الخبر بنجاح'
                  : 'تم رفع الصورة وإضافة الخبر بنجاح',
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
      if (!dataSaved &&
          uploadedFileReference != null) {
        try {
          await uploadedFileReference.delete();
        } catch (_) {}
      }

      showMessage(
        'خطأ Firebase: ${error.code}\n'
            '${error.message ?? 'حدث خطأ غير معروف'}',
      );
    } catch (error) {
      if (!dataSaved &&
          uploadedFileReference != null) {
        try {
          await uploadedFileReference.delete();
        } catch (_) {}
      }

      showMessage('خطأ في حفظ الخبر: $error');
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
    titleController.dispose();
    contentController.dispose();
    cityController.dispose();
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
            const SizedBox(height: 40),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
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
                image: AssetImage(
                  'assets/images/header_bg.png',
                ),
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
                    color: kTextColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'العودة',
                    style: TextStyle(
                      color: kTextColor,
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
        border: Border.all(
          color: const Color(0xffE6E6E6),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            height: 58,
            width: double.infinity,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
            ),
            decoration: const BoxDecoration(
              color: Color(0xffF8F8F8),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: const Text(
              'اضافة خبر',
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

                _CategoryDropdown(
                  selectedCategoryId:
                  selectedCategoryId,
                  onChanged: (
                      String id,
                      String name,
                      ) {
                    setState(() {
                      selectedCategoryId = id;
                      selectedCategoryName = name;
                    });
                  },
                ),

                const SizedBox(height: 14),

                _InputField(
                  controller: contentController,
                  hint: 'اكتب هنا ...',
                  height: 260,
                  maxLines: 10,
                ),

                const SizedBox(height: 16),

                // زر إضافة الوسائط بتدرج لوني كما في التصميم
                _MediaPickerButton(
                  selectedMedia: selectedMedia,
                  selectedMediaType: selectedMediaType,
                  onTap: pickMedia,
                  onRemove: removeSelectedMedia,
                ),

                const SizedBox(height: 14),

                InkWell(
                  onTap:
                  isLoading ? null : saveNews,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AddNewsScreen.textColor,
                      borderRadius:
                      BorderRadius.circular(6),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text(
                      'ارسال الخبر',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight:
                        FontWeight.w800,
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

/// زر إضافة الوسائط (صورة أو فيديو) بتدرج لوني مطابق للتصميم
class _MediaPickerButton extends StatelessWidget {
  final XFile? selectedMedia;
  final String? selectedMediaType;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _MediaPickerButton({
    required this.selectedMedia,
    required this.selectedMediaType,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasMedia = selectedMedia != null;

    String label = 'اضف الوسائط';

    if (hasMedia) {
      label = selectedMediaType == 'video'
          ? 'تم اختيار فيديو'
          : 'تم اختيار صورة';
    }

    return InkWell(
      onTap: onTap,
      onLongPress: hasMedia ? onRemove : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 52,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              Color(0xff9FBAC9),
              Color(0xff6C87C9),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (hasMedia) ...[
              const SizedBox(width: 8),
              Icon(
                selectedMediaType == 'video'
                    ? Icons.videocam_outlined
                    : Icons.image_outlined,
                color: Colors.white,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String? selectedCategoryId;

  final void Function(
      String id,
      String name,
      ) onChanged;

  const _CategoryDropdown({
    required this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF6F6F6),
        borderRadius: BorderRadius.circular(3),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('categories')
            .orderBy(
          'createdAt',
          descending: true,
        )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'خطأ في تحميل الأقسام',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            );
          }

          final List<QueryDocumentSnapshot> docs =
              snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text('لا توجد أقسام'),
            );
          }

          return DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCategoryId,
              isExpanded: true,
              hint: const Text('التصنيف'),
              items: docs.map(
                    (QueryDocumentSnapshot document) {
                  final Map<String, dynamic> data =
                  document.data()
                  as Map<String, dynamic>;

                  final String name =
                  (data['name'] ?? 'قسم')
                      .toString();

                  return DropdownMenuItem<String>(
                    value: document.id,
                    child: Text(name),
                  );
                },
              ).toList(),
              onChanged: (String? selectedId) {
                if (selectedId == null) return;

                final QueryDocumentSnapshot document =
                docs.firstWhere(
                      (QueryDocumentSnapshot item) =>
                  item.id == selectedId,
                );

                final Map<String, dynamic> data =
                document.data()
                as Map<String, dynamic>;

                final String name =
                (data['name'] ?? 'قسم')
                    .toString();

                onChanged(selectedId, name);
              },
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
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),
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