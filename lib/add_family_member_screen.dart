import 'package:flutter/material.dart';
import 'models/family_member.dart';
import 'services/family_service.dart';

class AddFamilyMemberScreen extends StatefulWidget {
  const AddFamilyMemberScreen({super.key});

  static const Color blue = Color(0xff5E7FCB);
  static const Color mint = Color(0xff9FE2D4);
  static const Color textColor = Color(0xff53617F);
  static const Color grayText = Color(0xff9A9A9A);

  @override
  State<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  final TextEditingController nameController = TextEditingController();
  String? gender;
  DateTime? birthDate;
  String? selectedFatherId;
  List<FamilyMember> allMembers = [];
  bool isLoading = false;
  bool isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    loadFathers();
  }

  Future<void> loadFathers() async {
    allMembers = await FamilyService().getAllMembers();
    if (mounted) setState(() => isLoadingMembers = false);
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> pickBirthDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
    if (picked != null) setState(() => birthDate = picked);
  }

  Future<void> saveMember() async {
    if (nameController.text.trim().isEmpty || gender == null) {
      showMessage('الرجاء تعبئة الاسم والجنس');
      return;
    }

    setState(() => isLoading = true);
    try {
      await FamilyService().addMember(
        name: nameController.text.trim(),
        gender: gender!,
        birthDate: birthDate,
        fatherId: selectedFatherId,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      showMessage('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
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
            const SizedBox(height: 40),
            Expanded(
              child: isLoadingMembers
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AddFamilyMemberScreen.blue,
                ),
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Text(
                      'إضافة فرد جديد',
                      style: TextStyle(
                        color: AddFamilyMemberScreen.textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'أدخل بيانات الفرد لإضافته إلى شجرة العائلة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AddFamilyMemberScreen.grayText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // الاسم
                    Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xffF7F7F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: nameController,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AddFamilyMemberScreen.textColor,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          hintText: 'الاسم الكامل',
                          hintStyle: TextStyle(
                            color: AddFamilyMemberScreen.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // اختيار الأب
                    Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xffF7F7F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          value: selectedFatherId,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: AddFamilyMemberScreen.textColor,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                          hint: const Text(
                            'اختر الأب (اختياري)',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: AddFamilyMemberScreen.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AddFamilyMemberScreen.textColor,
                          ),
                          items: allMembers
                              .where((m) => m.gender == 'male')
                              .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(m.name, textAlign: TextAlign.right),
                          ))
                              .toList(),
                          onChanged: (value) => setState(() => selectedFatherId = value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // الجنس
                    Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xffF7F7F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          value: gender,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: AddFamilyMemberScreen.textColor,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                          hint: const Text(
                            'الجنس',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: AddFamilyMemberScreen.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AddFamilyMemberScreen.textColor,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'male',
                              child: Text('ذكر', textAlign: TextAlign.right),
                            ),
                            DropdownMenuItem(
                              value: 'female',
                              child: Text('أنثى', textAlign: TextAlign.right),
                            ),
                          ],
                          onChanged: (value) => setState(() => gender = value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // تاريخ الميلاد
                    InkWell(
                      onTap: pickBirthDate,
                      child: Container(
                        height: 58,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xffF7F7F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                birthDate != null
                                    ? _formatDate(birthDate!)
                                    : 'تاريخ الميلاد (اختياري)',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AddFamilyMemberScreen.textColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.cake_outlined,
                              color: AddFamilyMemberScreen.textColor,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // زر الحفظ
                    InkWell(
                      onTap: isLoading ? null : saveMember,
                      child: Container(
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: const LinearGradient(
                            colors: [
                              AddFamilyMemberScreen.mint,
                              AddFamilyMemberScreen.blue,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'حفظ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
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
              onTap: () => Navigator.pop(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new,
                    size: 15,
                    color: AddFamilyMemberScreen.textColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'العودة',
                    style: TextStyle(
                      color: AddFamilyMemberScreen.textColor,
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