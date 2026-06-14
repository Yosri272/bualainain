import 'package:flutter/material.dart';
import 'widgets/custom_status_bar.dart';
import 'widgets/custom_bottom_nav.dart';

class MembersManagementScreen extends StatelessWidget {
  const MembersManagementScreen({super.key});

  static const Color textColor = Color(0xff53617F);
  static const Color greenColor = Color(0xff008C6A);
  static const Color grayColor = Color(0xff777777);

  @override
  Widget build(BuildContext context) {
    final members = [
      ['فهد الحربي', '050277XXXX'],
      ['احمد القحطاني', '050277XXXX'],
      ['يوسف عبدالله', '050277XXXX'],
      ['خالد الحامدي', '050277XXXX'],
      ['فواز العتيبي', '050277XXXX'],
      ['وليد الصراف', '050277XXXX'],
    ];

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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xffE6E6E6)),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.05),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        height: 58,
                        width: double.infinity,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        color: const Color(0xffF8F8F8),
                        child: const Text(
                          'إدارة الأعضاء',
                          style: TextStyle(
                            color: Color(0xff222222),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 20, 14, 22),
                        child: Column(
                          children: [
                            const _TableHeader(),
                            const SizedBox(height: 14),

                            ...members.map(
                                  (member) => _MemberRow(
                                name: member[0],
                                phone: member[1],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const CustomBottomNav(selectedIndex: 3),
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
          const Positioned(
            top: 18,
            left: 0,
            right: 0,
            child: CustomStatusBar(),
          ),

          Positioned(
            right: 24,
            bottom: -45,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'العودة',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_back_ios_new,
                    size: 15,
                    color: textColor,
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
            style: _headerStyle,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'رقم الجوال',
            textAlign: TextAlign.center,
            style: _headerStyle,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'إجراء القبول',
            textAlign: TextAlign.center,
            style: _headerStyle,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'إجراء الرفض',
            textAlign: TextAlign.center,
            style: _headerStyle,
          ),
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  final String name;
  final String phone;

  const _MemberRow({
    required this.name,
    required this.phone,
  });

  static const TextStyle rowStyle = TextStyle(
    color: MembersManagementScreen.textColor,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              textAlign: TextAlign.right,
              style: rowStyle,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              phone,
              textAlign: TextAlign.center,
              style: rowStyle,
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'قبول',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MembersManagementScreen.greenColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'رفض',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MembersManagementScreen.grayColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const TextStyle _headerStyle = TextStyle(
  color: Color(0xff222222),
  fontSize: 13,
  fontWeight: FontWeight.w800,
);