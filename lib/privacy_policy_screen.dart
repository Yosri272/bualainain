import 'package:flutter/material.dart';
import 'widgets/custom_bottom_nav.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const Color textColor = Color(0xff53617F);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _header(context),
            const SizedBox(height: 75),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xffE6E6E6)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سياسة الخصوصية',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 20),

                      _PrivacyParagraph(
                        title: '1. جمع البيانات',
                        body:
                        'يقوم التطبيق بجمع البيانات اللازمة لتقديم الخدمات مثل الاسم ورقم الجوال والبريد الإلكتروني عند التسجيل أو استخدام بعض الخصائص.',
                      ),

                      _PrivacyParagraph(
                        title: '2. استخدام البيانات',
                        body:
                        'تستخدم البيانات لتحسين تجربة المستخدم، وإرسال التنبيهات، وإدارة الحسابات، وتقديم الخدمات داخل التطبيق.',
                      ),

                      _PrivacyParagraph(
                        title: '3. حماية البيانات',
                        body:
                        'نلتزم بحماية بيانات المستخدمين واتخاذ الإجراءات المناسبة لمنع الوصول غير المصرح به أو إساءة استخدام المعلومات.',
                      ),

                      _PrivacyParagraph(
                        title: '4. مشاركة البيانات',
                        body:
                        'لا يتم مشاركة بيانات المستخدمين مع أي طرف خارجي إلا عند الحاجة النظامية أو بموافقة المستخدم.',
                      ),

                      _PrivacyParagraph(
                        title: '5. التنبيهات والإشعارات',
                        body:
                        'قد يستخدم التطبيق التنبيهات لإبلاغ المستخدمين بالأخبار والمناسبات والتحديثات المهمة، ويمكن للمستخدم التحكم بها من إعدادات التنبيهات.',
                      ),

                      _PrivacyParagraph(
                        title: '6. تعديل سياسة الخصوصية',
                        body:
                        'قد يتم تحديث سياسة الخصوصية من وقت لآخر، ويعد استمرار استخدام التطبيق موافقة على أي تحديثات جديدة.',
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

class _PrivacyParagraph extends StatelessWidget {
  final String title;
  final String body;

  const _PrivacyParagraph({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: PrivacyPolicyScreen.textColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xff2E3547),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}