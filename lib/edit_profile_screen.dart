import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'services/family_service.dart';
import 'services/session_service.dart';
import 'models/family_member.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const Color blue = Color(0xff5D7FCB);
  static const Color mint = Color(0xff9FE2D4);
  static const Color textColor = Color(0xff53617F);
  static const Color titleColor = Color(0xff2E3547);
  static const Color bgColor = Color(0xffF7F8FC);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final firstNameController = TextEditingController();
  final secondNameController = TextEditingController();
  final thirdNameController = TextEditingController();
  final fourthNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final cityController = TextEditingController();
  final bioController = TextEditingController();

  String? gender;
  String? maritalStatus;
  String? occupation;
  DateTime? birthDate;
  String? photoUrl;
  File? pickedImageFile;
  String? currentUserId;

  // اختيار الأب المقترح
  String? selectedFatherId;
  List<FamilyMember> allMembers = [];
  bool isLoadingMembers = true;

  bool isLoading = true;
  bool isSaving = false;
  bool isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    currentUserId = await SessionService.getUserId();
    await loadUserData();
    await loadFamilyMembers();
  }

  Future<void> loadFamilyMembers() async {
    try {
      final members = await FamilyService().getAllMembers();

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      final String myFamilyName =
      (userDoc.data()?['fourthName'] ?? fourthNameController.text)
          .toString()
          .trim();

      // نستبعد المستخدم نفسه، ونعرض فقط أعضاء نفس اسم العائلة
      // (الاسم الرابع) عشان الأب يكون منطقياً ومن نفس العائلة.
      allMembers = members.where((m) {
        if (m.id == currentUserId) return false;
        if (myFamilyName.isEmpty) return true; // لو اسم العائلة لسه فاضي، نعرض الكل مؤقتاً
        return (m.familyName ?? '').trim() == myFamilyName;
      }).toList();

      selectedFatherId = userDoc.data()?['pendingFatherId'];
    } catch (e) {
      debugPrint("ERROR loading family members: $e");
    } finally {
      if (mounted) setState(() => isLoadingMembers = false);
    }
  }

  /// النص المعروض لكل خيار في دروب داون اختيار الأب:
  /// "الاسم - اسم العائلة" (مثال: محمد علي - الحربي)
  String _fatherOptionLabel(FamilyMember member) {
    final String familyName = (member.familyName ?? '').trim();
    if (familyName.isEmpty) return member.name;
    return '${member.name} - $familyName';
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
      initialDate: birthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
    if (picked != null) setState(() => birthDate = picked);
  }

  Future<void> pickAndUploadImage() async {
    if (currentUserId == null) {
      showMessage('لا يوجد مستخدم مسجل');
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
    );

    if (picked == null) return;

    setState(() {
      pickedImageFile = File(picked.path);
      isUploadingImage = true;
    });

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('$currentUserId.jpg');

      await ref.putFile(pickedImageFile!);
      final String downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(currentUserId).set({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() => photoUrl = downloadUrl);

      if (mounted) showMessage('تم تحديث الصورة الشخصية');
    } catch (e) {
      if (mounted) showMessage('حدث خطأ أثناء رفع الصورة: $e');
    } finally {
      if (mounted) setState(() => isUploadingImage = false);
    }
  }

  Future<void> loadUserData() async {
    try {
      if (currentUserId == null) {
        throw Exception("No logged in user");
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        firstNameController.text = data['firstName'] ?? '';
        secondNameController.text = data['secondName'] ?? '';
        thirdNameController.text = data['thirdName'] ?? '';
        fourthNameController.text = data['fourthName'] ?? '';
        phoneController.text = data['phone'] ?? '';
        emailController.text = data['email'] ?? '';
        cityController.text = data['city'] ?? '';
        bioController.text = data['bio'] ?? '';
        gender = data['gender'];
        maritalStatus = data['maritalStatus'];
        occupation = data['occupation'];
        photoUrl = data['photoUrl'];

        final Timestamp? bd = data['birthDate'];
        if (bd != null) birthDate = bd.toDate();
      }
    } catch (e) {
      debugPrint("ERROR: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> saveProfile() async {
    if (currentUserId == null) {
      showMessage('حدث خطأ: لا يوجد مستخدم مسجل، الرجاء تسجيل الدخول مجدداً');
      return;
    }

    if (firstNameController.text.trim().isEmpty ||
        secondNameController.text.trim().isEmpty ||
        thirdNameController.text.trim().isEmpty ||
        fourthNameController.text.trim().isEmpty) {
      showMessage('الرجاء تعبئة الاسم كاملاً (الأول، الثاني، الثالث، اسم العائلة)');
      return;
    }

    if (gender == null) {
      showMessage('الرجاء اختيار الجنس');
      return;
    }

    setState(() => isSaving = true);

    try {
      final String fullName =
          '${firstNameController.text.trim()} ${secondNameController.text.trim()} ${thirdNameController.text.trim()} ${fourthNameController.text.trim()}';

      // ملاحظة: pendingFatherId هنا مجرد "اقتراح" من العضو، ولا يُطبَّق
      // فعلياً على شجرة family_members إلا بعد موافقة المشرف من
      // شاشة إدارة الأعضاء (والتي تستدعي syncMemberFromUser).
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).set({
        'firstName': firstNameController.text.trim(),
        'secondName': secondNameController.text.trim(),
        'thirdName': thirdNameController.text.trim(),
        'fourthName': fourthNameController.text.trim(),
        'name': fullName,
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'gender': gender,
        if (maritalStatus != null) 'maritalStatus': maritalStatus,
        if (occupation != null) 'occupation': occupation,
        if (birthDate != null) 'birthDate': Timestamp.fromDate(birthDate!),
        if (photoUrl != null) 'photoUrl': photoUrl,
        'city': cityController.text.trim(),
        'bio': bioController.text.trim(),
        'pendingFatherId': selectedFatherId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('تم بنجاح', textAlign: TextAlign.right),
            content: const Text('تم حفظ التعديلات بنجاح', textAlign: TextAlign.right),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('موافق')),
            ],
          );
        },
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      showMessage('حدث خطأ أثناء الحفظ: $e');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    firstNameController.dispose();
    secondNameController.dispose();
    thirdNameController.dispose();
    fourthNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    cityController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: EditProfileScreen.bgColor,
        body: Column(
          children: [
            _header(context),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 35),
                    _profileImage(),
                    const SizedBox(height: 14),
                    Text(
                      firstNameController.text.isEmpty
                          ? 'مستخدم'
                          : '${firstNameController.text} ${secondNameController.text}',
                      style: const TextStyle(
                        color: EditProfileScreen.textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _inputField(controller: firstNameController, label: 'الاسم الأول', icon: Icons.person_outline),
                    const SizedBox(height: 14),
                    _inputField(controller: secondNameController, label: 'الاسم الثاني', icon: Icons.person_outline),
                    const SizedBox(height: 14),
                    _inputField(controller: thirdNameController, label: 'الاسم الثالث', icon: Icons.person_outline),
                    const SizedBox(height: 14),
                    _inputField(controller: fourthNameController, label: 'اسم العائلة', icon: Icons.person_outline),
                    const SizedBox(height: 14),
                    _inputField(controller: phoneController, label: 'رقم الجوال', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                    const SizedBox(height: 14),
                    _inputField(controller: emailController, label: 'البريد الإلكتروني', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 14),

                    // الجنس
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          value: gender,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: EditProfileScreen.textColor),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          hint: const Text('الجنس', textAlign: TextAlign.right,
                              style: TextStyle(color: EditProfileScreen.textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                          items: const [
                            DropdownMenuItem(value: 'male', child: Text('ذكر', textAlign: TextAlign.right)),
                            DropdownMenuItem(value: 'female', child: Text('أنثى', textAlign: TextAlign.right)),
                          ],
                          onChanged: (value) => setState(() => gender = value),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // الحالة الاجتماعية
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          value: maritalStatus,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: EditProfileScreen.textColor),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          hint: const Text('الحالة الاجتماعية', textAlign: TextAlign.right,
                              style: TextStyle(color: EditProfileScreen.textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                          items: const [
                            DropdownMenuItem(value: 'single', child: Text('أعزب', textAlign: TextAlign.right)),
                            DropdownMenuItem(value: 'married', child: Text('متزوج', textAlign: TextAlign.right)),
                            DropdownMenuItem(value: 'divorced', child: Text('مطلق', textAlign: TextAlign.right)),
                            DropdownMenuItem(value: 'widowed', child: Text('أرمل', textAlign: TextAlign.right)),
                          ],
                          onChanged: (value) => setState(() => maritalStatus = value),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // الوظيفة
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          value: occupation,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: EditProfileScreen.textColor),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          hint: const Text('الوظيفة', textAlign: TextAlign.right,
                              style: TextStyle(color: EditProfileScreen.textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                          items: const [
                            DropdownMenuItem(value: 'student', child: Text('طالب', textAlign: TextAlign.right)),
                            DropdownMenuItem(value: 'government_employee', child: Text('موظف قطاع حكومي', textAlign: TextAlign.right)),
                            DropdownMenuItem(value: 'private_employee', child: Text('موظف قطاع خاص', textAlign: TextAlign.right)),
                          ],
                          onChanged: (value) => setState(() => occupation = value),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // اختيار الأب في شجرة العائلة
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: isLoadingMembers
                          ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                          : DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String?>(
                          value: selectedFatherId,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: EditProfileScreen.textColor),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          hint: const Text(
                            'اختر الأب في شجرة العائلة',
                            textAlign: TextAlign.right,
                            style: TextStyle(color: EditProfileScreen.textColor, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('بدون أب (جذر العائلة)', textAlign: TextAlign.right),
                            ),
                            ...allMembers.map(
                                  (m) => DropdownMenuItem<String?>(
                                value: m.id,
                                child: Text(
                                  _fatherOptionLabel(m),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(() => selectedFatherId = value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'سيتم ربطك بالأب المختار بعد موافقة المشرف',
                        style: TextStyle(color: EditProfileScreen.textColor, fontSize: 11.5),
                      ),
                    ),

                    const SizedBox(height: 14),

                    InkWell(
                      onTap: pickBirthDate,
                      child: Container(
                        height: 58,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cake_outlined, color: EditProfileScreen.textColor, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                birthDate != null ? _formatDate(birthDate!) : 'تاريخ الميلاد',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EditProfileScreen.titleColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    _inputField(controller: cityController, label: 'المدينة', icon: Icons.location_on_outlined),
                    const SizedBox(height: 14),
                    _inputField(controller: bioController, label: 'نبذة شخصية', icon: Icons.info_outline, maxLines: 3),
                    const SizedBox(height: 28),
                    _saveButton(),
                    const SizedBox(height: 24),
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
            decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/header_bg.png'), fit: BoxFit.cover)),
          ),
          Positioned(
            right: 24,
            top: 142,
            child: InkWell(
              onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios_new, size: 15, color: EditProfileScreen.textColor),
                  const SizedBox(width: 6),
                  Text('العودة', style: const TextStyle(color: EditProfileScreen.textColor, fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileImage() {
    ImageProvider imageProvider;
    if (pickedImageFile != null) {
      imageProvider = FileImage(pickedImageFile!);
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(photoUrl!);
    } else {
      imageProvider = const AssetImage('assets/images/profile.png');
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 56,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 52,
            backgroundImage: imageProvider,
            child: isUploadingImage ? const CircularProgressIndicator(color: Colors.white) : null,
          ),
        ),
        InkWell(
          onTap: isUploadingImage ? null : pickAndUploadImage,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [EditProfileScreen.mint, EditProfileScreen.blue], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 17),
          ),
        ),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textAlign: TextAlign.right,
      style: const TextStyle(color: EditProfileScreen.titleColor, fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: EditProfileScreen.textColor, fontSize: 13, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: EditProfileScreen.textColor, size: 22),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EditProfileScreen.blue, width: 1.4)),
      ),
    );
  }

  Widget _saveButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: isSaving ? null : saveProfile,
      child: Container(
        height: 52,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(colors: [EditProfileScreen.mint, EditProfileScreen.blue], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          boxShadow: [BoxShadow(color: EditProfileScreen.blue.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }
}