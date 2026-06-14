import 'package:flutter/material.dart';
import 'widgets/custom_status_bar.dart';
import 'widgets/custom_bottom_nav.dart';

class NewsDetailsScreen extends StatelessWidget {
  const NewsDetailsScreen({super.key});

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

            const SizedBox(height: 55),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/news.png',
                        height: 255,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'تهاني وتبريكات  |  الرياض  |  2025.11.26',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Color(0xff9A9A9A),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'تهنئة للشاب خالد بن سعد البوعينين بمناسبة زفافه',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'نبارك من أعماق قلوبنا للشاب خالد بن سعد البوعينين بمناسبة زفافه السعيد، ونتمنى له حياة مليئة بالسعادة والنجاح، وأن تكون أيامه القادمة مليئة بالحب والفرح، وأن يحقق كل أحلامه وطموحاته مع شريكته في الحياة.',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Color(0xff222222),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.9,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const CustomBottomNav(selectedIndex: 1),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      height: 135,
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
            top: 28,
            left: 0,
            right: 0,
            child: CustomStatusBar(),
          ),

          Positioned(
            right: 28,
            bottom: -38,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'العودة',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
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