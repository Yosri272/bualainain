import 'package:flutter/material.dart';
import 'widgets/custom_bottom_nav.dart';

class AddMemberScreen extends StatelessWidget {
  const AddMemberScreen({super.key});

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
            const SizedBox(height: 70),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: _formCard(),
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

  Widget _formCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffE6E6E6)),
        borderRadius: BorderRadius.circular(10),
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
              'إضافة عضو جديد',
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
                const _InputField(hint: 'الاسم'),
                const SizedBox(height: 14),

                const _InputField(
                  hint: 'البريد الإلكتروني',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),

                const _InputField(
                  hint: 'الهاتف',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),

                const _InputField(hint: 'المدينة'),
                const SizedBox(height: 14),

                const _InputField(hint: 'الجنس'),
                const SizedBox(height: 22),

                InkWell(
                  onTap: () {},
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: textColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'إنشاء الحساب',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
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

class _InputField extends StatelessWidget {
  final String hint;
  final TextInputType? keyboardType;

  const _InputField({
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xffF6F6F6),
        borderRadius: BorderRadius.circular(3),
      ),
      child: TextField(
        keyboardType: keyboardType,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            color: AddMemberScreen.textColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}