import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  static const Color textColor = Color(0xff53617F);

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController genderController = TextEditingController();

  bool isLoading = false;

  Future<void> saveMember() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final city = cityController.text.trim();
    final gender = genderController.text.trim();

    if (name.isEmpty) {
      showMessage('الرجاء إدخال اسم العضو');
      return;
    }

    try {
      setState(() => isLoading = true);

      await FirebaseFirestore.instance.collection('members').add({
        'name': name,
        'email': email,
        'phone': phone,
        'city': city,
        'gender': gender,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      nameController.clear();
      emailController.clear();
      phoneController.clear();
      cityController.clear();
      genderController.clear();

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'تم بنجاح',
              textAlign: TextAlign.right,
            ),
            content: const Text(
              'تم إضافة العضو بنجاح',
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('موافق'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/admin',
            (route) => false,
      );
    } catch (e) {
      showMessage('خطأ في إضافة العضو: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    cityController.dispose();
    genderController.dispose();
    super.dispose();
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

            const SizedBox(height: 25),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: _formCard(),
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
                    color: AddMemberScreen.textColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'العودة',
                    style: TextStyle(
                      color: AddMemberScreen.textColor,
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
                _InputField(
                  controller: nameController,
                  hint: 'الاسم',
                ),

                const SizedBox(height: 14),

                _InputField(
                  controller: emailController,
                  hint: 'البريد الإلكتروني',
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 14),

                _InputField(
                  controller: phoneController,
                  hint: 'الهاتف',
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 14),

                _InputField(
                  controller: cityController,
                  hint: 'المدينة',
                ),

                const SizedBox(height: 14),

                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xffF6F6F6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: genderController.text.isEmpty
                        ? null
                        : genderController.text,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                    hint: const Text(
                      'الجنس',
                      style: TextStyle(
                        color: AddMemberScreen.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'ذكر',
                        child: Text('ذكر'),
                      ),
                      DropdownMenuItem(
                        value: 'أنثى',
                        child: Text('أنثى'),
                      ),
                    ],
                    onChanged: (value) {
                      genderController.text = value ?? '';
                    },
                  ),
                ),
                const SizedBox(height: 22),

                InkWell(
                  onTap: isLoading ? null : saveMember,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AddMemberScreen.textColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text(
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
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
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
        controller: controller,
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