import 'package:flutter/material.dart';
import 'widgets/custom_bottom_nav.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
                        'الأحكام والشروط',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 20),

                      _TermsParagraph(
                        title: '1. قبول الشروط',
                        body:
                        'باستخدامك لهذا التطبيق فإنك توافق على الالتزام بجميع الأحكام والشروط المذكورة في هذه الصفحة.',
                      ),

                      _TermsParagraph(
                        title: '2. استخدام التطبيق',
                        body:
                        'يجب استخدام التطبيق للأغراض العائلية والاجتماعية المخصصة له، وعدم إساءة استخدام الخدمات أو المحتوى المنشور.',
                      ),

                      _TermsParagraph(
                        title: '3. الحسابات والمعلومات',
                        body:
                        'يلتزم المستخدم بإدخال بيانات صحيحة عند التسجيل، ويحق لإدارة التطبيق مراجعة أو رفض أي حساب غير مكتمل أو غير صحيح.',
                      ),

                      _TermsParagraph(
                        title: '4. المحتوى المنشور',
                        body:
                        'يمنع نشر أي محتوى مخالف للآداب العامة أو مسيء لأي شخص أو جهة، وتحتفظ الإدارة بحق حذف أي محتوى مخالف.',
                      ),

                      _TermsParagraph(
                        title: '5. الخصوصية',
                        body:
                        'نحرص على حماية بيانات المستخدمين وعدم مشاركتها مع أي طرف غير مصرح له إلا وفق الأنظمة والسياسات المعتمدة.',
                      ),

                      _TermsParagraph(
                        title: '6. تعديل الشروط',
                        body:
                        'يحق لإدارة التطبيق تعديل هذه الشروط في أي وقت، ويعد استمرارك في استخدام التطبيق موافقة على التعديلات الجديدة.',
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
                  '/profile',
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

class _TermsParagraph extends StatelessWidget {
  final String title;
  final String body;

  const _TermsParagraph({
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
              color: TermsScreen.textColor,
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