import 'package:flutter/material.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  static const Color blue = Color(0xff5E7FCB);
  static const Color mint = Color(0xff9FE2D4);
  static const Color textColor = Color(0xff53617F);
  static const Color grayText = Color(0xff9A9A9A);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _header(context),
            const SizedBox(height: 90),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Text(
                      'رمز التحقق',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'أدخل رمز التحقق المرسل إلى رقم جوالك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: grayText,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      '05XXXXXXXX',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 45),

                    Row(
                      textDirection: TextDirection.ltr,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _OtpBox(),
                        _OtpBox(),
                        _OtpBox(),
                        _OtpBox(),
                      ],
                    ),

                    const SizedBox(height: 40),

                    InkWell(
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                              (route) => false,
                        );
                      },
                      child: Container(
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: const LinearGradient(
                            colors: [mint, blue],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: const Text(
                          'تحقق',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'لم يصلك الرمز؟',
                          style: TextStyle(
                            color: grayText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {},
                          child: const Text(
                            'إعادة الإرسال',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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

          Positioned(
            right: 28,
            bottom: -38,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new,
                    color: textColor,
                    size: 15,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'العودة',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
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

class _OtpBox extends StatelessWidget {
  const _OtpBox();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 58,
      child: TextField(
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          color: OtpScreen.textColor,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xffF6F6F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}