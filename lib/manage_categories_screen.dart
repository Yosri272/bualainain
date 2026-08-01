import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const Color kTextColor = Color(0xff53617F);

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() =>
      _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final Set<String> deletingCategoryIds = <String>{};

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> showAddCategoryDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _CategoryFormDialog(
          title: 'إضافة قسم',
          confirmLabel: 'إضافة',
          initialName: '',
          onSubmit: (String name) async {
            await FirebaseFirestore.instance
                .collection('categories')
                .add({
              'name': name,
              'createdAt': FieldValue.serverTimestamp(),
            });
          },
          onSuccess: () => showMessage('تمت إضافة القسم بنجاح'),
          onError: showMessage,
        );
      },
    );
  }

  Future<void> showEditCategoryDialog({
    required String categoryId,
    required Map<String, dynamic> data,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _CategoryFormDialog(
          title: 'تعديل القسم',
          confirmLabel: 'حفظ',
          initialName: (data['name'] ?? '').toString(),
          onSubmit: (String name) async {
            await FirebaseFirestore.instance
                .collection('categories')
                .doc(categoryId)
                .update({
              'name': name,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            await _updateRelatedNews(
              categoryId: categoryId,
              categoryName: name,
            );
          },
          onSuccess: () => showMessage('تم تعديل القسم بنجاح'),
          onError: showMessage,
        );
      },
    );
  }

  // Keeps news documents in sync when a category name is renamed.
  Future<void> _updateRelatedNews({
    required String categoryId,
    required String categoryName,
  }) async {
    final news = await FirebaseFirestore.instance
        .collection('news')
        .where('categoryId', isEqualTo: categoryId)
        .get();

    if (news.docs.isEmpty) return;

    final WriteBatch batch = FirebaseFirestore.instance.batch();

    for (final document in news.docs) {
      batch.update(
        document.reference,
        {
          'categoryName': categoryName,
        },
      );
    }

    await batch.commit();
  }

  Future<void> confirmDeleteCategory({
    required String categoryId,
  }) async {
    final news = await FirebaseFirestore.instance
        .collection('news')
        .where('categoryId', isEqualTo: categoryId)
        .limit(1)
        .get();

    if (news.docs.isNotEmpty) {
      showMessage(
        'لا يمكن حذف هذا القسم لوجود أخبار مرتبطة به',
      );
      return;
    }

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'حذف القسم',
              textAlign: TextAlign.right,
            ),
            content: const Text(
              'هل أنت متأكد من حذف هذا القسم؟',
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
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
      await deleteCategory(categoryId: categoryId);
    }
  }

  Future<void> deleteCategory({
    required String categoryId,
  }) async {
    if (deletingCategoryIds.contains(categoryId)) {
      return;
    }

    setState(() {
      deletingCategoryIds.add(categoryId);
    });

    try {
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .delete();

      showMessage('تم حذف القسم بنجاح');
    } on FirebaseException catch (error) {
      showMessage(
        'خطأ Firebase: ${error.code}\n'
            '${error.message ?? ''}',
      );
    } catch (error) {
      showMessage('خطأ في حذف القسم: $error');
    } finally {
      if (mounted) {
        setState(() {
          deletingCategoryIds.remove(categoryId);
        });
      }
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
                    .collection('categories')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (
                    BuildContext context,
                    AsyncSnapshot<
                        QuerySnapshot<Map<String, dynamic>>>
                    snapshot,
                    ) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
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

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('لا توجد أقسام'),
                    );
                  }

                  final categories = snapshot.data!.docs;

                  return SingleChildScrollView(
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
                            color: Colors.black.withValues(
                              alpha: 0.04,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.stretch,
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
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'إدارة الأقسام',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: kTextColor,
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                const _CategoriesTableHeader(),

                                const SizedBox(height: 12),

                                ...categories.map(
                                      (document) {
                                    final data = document.data();

                                    return _CategoryRow(
                                      name: (data['name'] ?? '')
                                          .toString(),
                                      isDeleting:
                                      deletingCategoryIds
                                          .contains(document.id),
                                      onEdit: () {
                                        showEditCategoryDialog(
                                          categoryId: document.id,
                                          data: data,
                                        );
                                      },
                                      onDelete: () {
                                        confirmDeleteCategory(
                                          categoryId: document.id,
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
}

class _CategoriesTableHeader extends StatelessWidget {
  const _CategoriesTableHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          flex: 6,
          child: Text(
            'اسم القسم',
            textAlign: TextAlign.right,
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

class _CategoryRow extends StatelessWidget {
  final String name;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryRow({
    required this.name,
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
            flex: 6,
            child: Text(
              name,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            flex: 2,
            child: InkWell(
              onTap: isDeleting ? null : onEdit,
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
              onTap: isDeleting ? null : onDelete,
              child: isDeleting
                  ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.red,
                  ),
                ),
              )
                  : const Text(
                'حذف',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Self-contained dialog used for both "add" and "edit" category flows.
///
/// The [TextEditingController] is created in [initState] and disposed in
/// [dispose], so Flutter only tears it down once this widget is actually
/// removed from the tree (after the dialog's exit animation finishes).
/// Disposing it manually right after `await showDialog(...)` returns is
/// what caused the previous "used after being disposed" crash, because the
/// dialog is still animating out at that point and its TextField was still
/// attached to the controller.
class _CategoryFormDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String initialName;
  final Future<void> Function(String name) onSubmit;
  final VoidCallback onSuccess;
  final void Function(String message) onError;

  const _CategoryFormDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialName,
    required this.onSubmit,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_CategoryFormDialog> createState() =>
      _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late final TextEditingController nameController =
  TextEditingController(text: widget.initialName);

  bool isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = nameController.text.trim();

    if (name.isEmpty) {
      widget.onError('الرجاء إدخال اسم القسم');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await widget.onSubmit(name);

      if (!mounted) return;

      Navigator.pop(context);

      widget.onSuccess();
    } on FirebaseException catch (error) {
      widget.onError(
        'خطأ Firebase: ${error.code}\n'
            '${error.message ?? ''}',
      );
    } catch (error) {
      widget.onError('حدث خطأ: $error');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          widget.title,
          textAlign: TextAlign.right,
        ),
        content: SizedBox(
          width: 400,
          child: _EditInputField(
            controller: nameController,
            hint: 'اسم القسم',
            enabled: !isSaving,
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSaving
                ? null
                : () {
              Navigator.pop(context);
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: kTextColor,
              foregroundColor: Colors.white,
            ),
            child: isSaving
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text(widget.confirmLabel),
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
  final bool enabled;

  const _EditInputField({
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
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),
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