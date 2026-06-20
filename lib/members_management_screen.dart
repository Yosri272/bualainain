import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MembersManagementScreen extends StatelessWidget {
  const MembersManagementScreen({super.key});

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
            const SizedBox(height: 70),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('status', isEqualTo: 'pending')
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
                        border: Border.all(
                          color: const Color(0xffE6E6E6),
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            const _TableHeader(),
                            const SizedBox(height: 14),

                            ...users.map((doc) {
                              final data = doc.data()
                              as Map<String, dynamic>;

                              return _MemberRow(
                                docId: doc.id,
                                name: data['name'] ?? '',
                                phone: data['phone'] ?? '',
                              );
                            }),
                          ],
                        ),
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
            'الاسم',
            textAlign: TextAlign.right,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'رقم الجوال',
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'قبول',
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'رفض',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  final String docId;
  final String name;
  final String phone;

  const _MemberRow({
    required this.docId,
    required this.name,
    required this.phone,
  });

  Future<void> approveUser() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(docId)
        .update({
      'status': 'approved',
    });
  }

  Future<void> rejectUser() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(docId)
        .update({
      'status': 'rejected',
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
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
              onTap: approveUser,
              child: const Text(
                'قبول',
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
              onTap: rejectUser,
              child: const Text(
                'رفض',
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