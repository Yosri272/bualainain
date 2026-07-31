import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ManageNewsScreen extends StatefulWidget {
  const ManageNewsScreen({super.key});

  @override
  State<ManageNewsScreen> createState() =>
      _ManageNewsScreenState();
}

class _ManageNewsScreenState extends State<ManageNewsScreen> {
  static const Color textColor = Color(0xff53617F);

  final Set<String> deletingNewsIds = <String>{};

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final dynamic value in values) {
      final String text = (value ?? '').toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  Future<void> showEditNewsDialog({
    required String newsId,
    required Map<String, dynamic> data,
  }) async {
    final TextEditingController titleController =
    TextEditingController(
      text: (data['title'] ?? '').toString(),
    );

    final TextEditingController cityController =
    TextEditingController(
      text: (data['city'] ?? '').toString(),
    );

    final TextEditingController contentController =
    TextEditingController(
      text: (data['content'] ?? '').toString(),
    );

    String? selectedCategoryId =
    (data['categoryId'] ?? '').toString().trim();

    String selectedCategoryName =
    (data['categoryName'] ?? '').toString();

    bool isPublished = data['isPublished'] == true;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (
              BuildContext context,
              StateSetter setDialogState,
              ) {
            Future<void> saveChanges() async {
              final String title =
              titleController.text.trim();

              final String city =
              cityController.text.trim();

              final String content =
              contentController.text.trim();

              if (title.isEmpty) {
                showMessage('الرجاء إدخال عنوان الخبر');
                return;
              }

              if (selectedCategoryId == null ||
                  selectedCategoryId!.isEmpty) {
                showMessage('الرجاء اختيار التصنيف');
                return;
              }

              if (content.isEmpty) {
                showMessage('الرجاء كتابة محتوى الخبر');
                return;
              }

              try {
                setDialogState(() {
                  isSaving = true;
                });

                await FirebaseFirestore.instance
                    .collection('news')
                    .doc(newsId)
                    .update({
                  'title': title,
                  'city': city.isEmpty ? 'الرياض' : city,
                  'content': content,
                  'categoryId': selectedCategoryId,
                  'categoryName': selectedCategoryName,
                  'isPublished': isPublished,
                  'updatedAt':
                  FieldValue.serverTimestamp(),
                });

                await _updateRelatedNotifications(
                  newsId: newsId,
                  title: title,
                  content: content,
                );

                if (!dialogContext.mounted) return;

                Navigator.pop(dialogContext);

                showMessage('تم تعديل الخبر بنجاح');
              } on FirebaseException catch (error) {
                showMessage(
                  'خطأ Firebase: ${error.code}\n'
                      '${error.message ?? ''}',
                );
              } catch (error) {
                showMessage(
                  'خطأ في تعديل الخبر: $error',
                );
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() {
                    isSaving = false;
                  });
                }
              }
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                title: const Text(
                  'تعديل الخبر',
                  textAlign: TextAlign.right,
                ),
                content: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _EditInputField(
                          controller: titleController,
                          hint: 'عنوان الخبر',
                        ),

                        const SizedBox(height: 12),

                        _EditInputField(
                          controller: cityController,
                          hint: 'المدينة',
                        ),

                        const SizedBox(height: 12),

                        Container(
                          height: 52,
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color:
                            const Color(0xffF6F6F6),
                            borderRadius:
                            BorderRadius.circular(3),
                          ),
                          child: StreamBuilder<
                              QuerySnapshot<
                                  Map<String, dynamic>>>(
                            stream: FirebaseFirestore
                                .instance
                                .collection('categories')
                                .orderBy(
                              'createdAt',
                              descending: true,
                            )
                                .snapshots(),
                            builder: (
                                BuildContext context,
                                AsyncSnapshot<
                                    QuerySnapshot<
                                        Map<String,
                                            dynamic>>>
                                snapshot,
                                ) {
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
                                    child:
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }

                              final documents =
                                  snapshot.data!.docs;

                              final bool selectedExists =
                              documents.any(
                                    (document) =>
                                document.id ==
                                    selectedCategoryId,
                              );

                              return DropdownButtonHideUnderline(
                                child:
                                DropdownButton<String>(
                                  value: selectedExists
                                      ? selectedCategoryId
                                      : null,
                                  isExpanded: true,
                                  hint: const Text(
                                    'اختر التصنيف',
                                  ),
                                  items: documents.map(
                                        (document) {
                                      final data =
                                      document.data();

                                      final String name =
                                      (data['name'] ??
                                          'قسم')
                                          .toString();

                                      return DropdownMenuItem<
                                          String>(
                                        value:
                                        document.id,
                                        child:
                                        Text(name),
                                      );
                                    },
                                  ).toList(),
                                  onChanged: isSaving
                                      ? null
                                      : (String? value) {
                                    if (value ==
                                        null) {
                                      return;
                                    }

                                    final document =
                                    documents
                                        .firstWhere(
                                          (item) =>
                                      item.id ==
                                          value,
                                    );

                                    final data =
                                    document.data();

                                    setDialogState(
                                          () {
                                        selectedCategoryId =
                                            value;

                                        selectedCategoryName =
                                            (data['name'] ??
                                                'قسم')
                                                .toString();
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        _EditInputField(
                          controller: contentController,
                          hint: 'محتوى الخبر',
                          height: 150,
                          maxLines: 6,
                        ),

                        const SizedBox(height: 12),

                        Container(
                          height: 52,
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color:
                            const Color(0xffF6F6F6),
                            borderRadius:
                            BorderRadius.circular(3),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'نشر الخبر',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight:
                                    FontWeight.w700,
                                  ),
                                ),
                              ),
                              Switch(
                                value: isPublished,
                                onChanged: isSaving
                                    ? null
                                    : (bool value) {
                                  setDialogState(
                                        () {
                                      isPublished =
                                          value;
                                    },
                                  );
                                },
                                activeThumbColor:
                                Colors.white,
                                activeTrackColor:
                                const Color(
                                  0xff5B6C99,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'سيتم الاحتفاظ بالصورة أو الفيديو الحالي دون تغيير.',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Color(0xff888888),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                      Navigator.pop(
                        dialogContext,
                      );
                    },
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed:
                    isSaving ? null : saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: textColor,
                      foregroundColor: Colors.white,
                    ),
                    child: isSaving
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('حفظ'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    cityController.dispose();
    contentController.dispose();
  }

  Future<void> _updateRelatedNotifications({
    required String newsId,
    required String title,
    required String content,
  }) async {
    final notifications = await FirebaseFirestore.instance
        .collection('notifications')
        .where(
      'newsId',
      isEqualTo: newsId,
    )
        .get();

    if (notifications.docs.isEmpty) return;

    final WriteBatch batch =
    FirebaseFirestore.instance.batch();

    for (final document in notifications.docs) {
      batch.update(
        document.reference,
        {
          'title': title,
          'body': content,
        },
      );
    }

    await batch.commit();
  }

  Future<void> confirmDeleteNews({
    required String newsId,
    required Map<String, dynamic> data,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(12),
            ),
            title: const Text(
              'حذف الخبر',
              textAlign: TextAlign.right,
            ),
            content: const Text(
              'هل أنت متأكد من حذف الخبر؟ سيتم حذف الصورة أو الفيديو المرتبط به.',
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      await deleteNews(
        newsId: newsId,
        data: data,
      );
    }
  }

  Future<void> deleteNews({
    required String newsId,
    required Map<String, dynamic> data,
  }) async {
    if (deletingNewsIds.contains(newsId)) {
      return;
    }

    setState(() {
      deletingNewsIds.add(newsId);
    });

    try {
      await _deleteNewsMedia(data);

      final notifications =
      await FirebaseFirestore.instance
          .collection('notifications')
          .where(
        'newsId',
        isEqualTo: newsId,
      )
          .get();

      final WriteBatch batch =
      FirebaseFirestore.instance.batch();

      batch.delete(
        FirebaseFirestore.instance
            .collection('news')
            .doc(newsId),
      );

      for (final document in notifications.docs) {
        batch.delete(document.reference);
      }

      await batch.commit();

      showMessage('تم حذف الخبر بنجاح');
    } on FirebaseException catch (error) {
      showMessage(
        'خطأ Firebase: ${error.code}\n'
            '${error.message ?? ''}',
      );
    } catch (error) {
      showMessage('خطأ في حذف الخبر: $error');
    } finally {
      if (mounted) {
        setState(() {
          deletingNewsIds.remove(newsId);
        });
      }
    }
  }

  Future<void> _deleteNewsMedia(
      Map<String, dynamic> data,
      ) async {
    final String storagePath =
    (data['storagePath'] ?? '').toString().trim();

    final String mediaUrl = _firstNonEmpty([
      data['mediaUrl'],
      data['videoUrl'],
      data['imageUrl'],
    ]);

    try {
      if (storagePath.isNotEmpty) {
        await FirebaseStorage.instance
            .ref()
            .child(storagePath)
            .delete();

        return;
      }

      if (mediaUrl.isNotEmpty) {
        await FirebaseStorage.instance
            .refFromURL(mediaUrl)
            .delete();
      }
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') {
        return;
      }

      rethrow;
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

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('news')
                    .orderBy(
                  'createdAt',
                  descending: true,
                )
                    .snapshots(),
                builder: (
                    BuildContext context,
                    AsyncSnapshot<
                        QuerySnapshot<
                            Map<String, dynamic>>>
                    snapshot,
                    ) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                      CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding:
                        const EdgeInsets.all(20),
                        child: Text(
                          snapshot.error.toString(),
                          textAlign:
                          TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد أخبار',
                      ),
                    );
                  }

                  final news =
                      snapshot.data!.docs;

                  return SingleChildScrollView(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 24,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(12),
                        border: Border.all(
                          color:
                          const Color(0xffE6E6E6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                            Colors.black.withValues(
                              alpha: 0.04,
                            ),
                            blurRadius: 20,
                            offset:
                            const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 56,
                            alignment:
                            Alignment.centerRight,
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            decoration:
                            const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color:
                                  Color(0xffE6E6E6),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: const Text(
                              'إدارة الأخبار',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight:
                                FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ),

                          Padding(
                            padding:
                            const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                const _NewsTableHeader(),

                                const SizedBox(height: 12),

                                ...news.map(
                                      (document) {
                                    final data =
                                    document.data();

                                    return _NewsRow(
                                      title:
                                      (data['title'] ??
                                          '')
                                          .toString(),
                                      category:
                                      (data['categoryName'] ??
                                          '')
                                          .toString(),
                                      isDeleting:
                                      deletingNewsIds
                                          .contains(
                                        document.id,
                                      ),
                                      onEdit: () {
                                        showEditNewsDialog(
                                          newsId:
                                          document.id,
                                          data: data,
                                        );
                                      },
                                      onDelete: () {
                                        confirmDeleteNews(
                                          newsId:
                                          document.id,
                                          data: data,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
                    color: textColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'العودة',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight:
                      FontWeight.w700,
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

class _NewsTableHeader extends StatelessWidget {
  const _NewsTableHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            'عنوان الخبر',
            textAlign: TextAlign.right,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'التصنيف',
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'تعديل',
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'حذف',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _NewsRow extends StatelessWidget {
  final String title;
  final String category;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NewsRow({
    required this.title,
    required this.category,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            flex: 3,
            child: Text(
              category,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            flex: 2,
            child: InkWell(
              onTap:
              isDeleting ? null : onEdit,
              child: const Text(
                'تعديل',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: InkWell(
              onTap:
              isDeleting ? null : onDelete,
              child: isDeleting
                  ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.red,
                  ),
                ),
              )
                  : const Text(
                'حذف',
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final double height;
  final int maxLines;

  const _EditInputField({
    required this.controller,
    required this.hint,
    this.height = 52,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF6F6F6),
        borderRadius:
        BorderRadius.circular(3),
      ),
      child: TextField(
        controller: controller,
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