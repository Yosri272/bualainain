import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_edit_user_screen.dart';

class UsersManagementScreen extends StatelessWidget {
  const UsersManagementScreen({super.key});

  static const Color textColor = Color(0xff53617F);
  static const Color greenColor = Color(0xff008C6A);
  static const Color grayColor = Color(0xff777777);

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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا يوجد أعضاء بانتظار المراجعة',
                      ),
                    );
                  }

                  final users = snapshot.data!.docs;

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
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [

                            /// عنوان البطاقة
                            Container(
                              height: 56,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xffE6E6E6),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: const Text(
                                "إدارة المستخدمين",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ),

                            /// محتوى الجدول
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [

                                  const _TableHeader(),

                                  const SizedBox(height: 12),

                                  ...users.map((doc) {
                                    final data = doc.data() as Map<String, dynamic>;

                                    return _UserRow(
                                      docId: doc.id,
                                      name: data['name'] ?? '',
                                      phone: data['phone'] ?? '',
                                    );
                                  }),

                                ],
                              ),
                            ),
                          ],
                        ),
                      )
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
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            "الاسم",
            textAlign: TextAlign.right,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            "رقم الجوال",
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            "تعديل",
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            "حذف",
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  final String docId;
  final String name;
  final String phone;

  const _UserRow({
    required this.docId,
    required this.name,
    required this.phone,
  });

  Future<void> confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'تأكيد الحذف',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'هل أنت متأكد من حذف هذا المستخدم؟',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'حذف',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );


  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              phone,
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminEditUserScreen(
                      userId: docId,
                    ),
                  ),
                );
              },
              child: const Icon(
                Icons.edit,
                color: Colors.blue,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => confirmDelete(context),
              child: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}