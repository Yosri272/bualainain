import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'services/family_service.dart';
import 'models/family_member.dart';

class AdminEditUserScreen extends StatefulWidget {
  final String userId;

  const AdminEditUserScreen({
    super.key,
    required this.userId,
  });

  static const Color blue = Color(0xff5D7FCB);
  static const Color mint = Color(0xff9FE2D4);
  static const Color textColor = Color(0xff53617F);
  static const Color titleColor = Color(0xff2E3547);
  static const Color bgColor = Color(0xffF7F8FC);

  @override
  State<AdminEditUserScreen> createState() =>
      _AdminEditUserScreenState();
}

class _AdminEditUserScreenState extends State<AdminEditUserScreen> {
  // =========================
  // Controllers
  // =========================

  final firstNameController = TextEditingController();
  final secondNameController = TextEditingController();
  final thirdNameController = TextEditingController();
  final fourthNameController = TextEditingController();

  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final cityController = TextEditingController();
  final bioController = TextEditingController();

  // =========================
  // User data
  // =========================

  String? gender;
  String? maritalStatus;
  DateTime? birthDate;

  String? photoUrl;
  File? pickedImageFile;

  String? selectedFatherId;

  List<FamilyMember> allMembers = [];

  bool isLoading = true;
  bool isSaving = false;
  bool isUploadingImage = false;
  bool isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // =========================
  // Initial loading
  // =========================

  Future<void> _init() async {
    await Future.wait([
      loadUser(),
      loadFamilyMembers(),
    ]);

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // =========================
  // Load user
  // =========================

  Future<void> loadUser() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!doc.exists) {
        showMessage('المستخدم غير موجود');
        return;
      }

      final data = doc.data()!;

      firstNameController.text =
          (data['firstName'] ?? '').toString();

      secondNameController.text =
          (data['secondName'] ?? '').toString();

      thirdNameController.text =
          (data['thirdName'] ?? '').toString();

      fourthNameController.text =
          (data['fourthName'] ?? '').toString();

      phoneController.text =
          (data['phone'] ?? '').toString();

      emailController.text =
          (data['email'] ?? '').toString();

      cityController.text =
          (data['city'] ?? '').toString();

      bioController.text =
          (data['bio'] ?? '').toString();

      // =========================
      // Gender
      // =========================

      final savedGender = data['gender'];

      if (savedGender == 'male' || savedGender == 'female') {
        gender = savedGender;
      } else if (savedGender == 'ذكر') {
        gender = 'male';
      } else if (savedGender == 'أنثى') {
        gender = 'female';
      } else {
        gender = null;
      }

      // =========================
      // Marital Status
      // =========================

      final savedMaritalStatus = data['maritalStatus'];

      const validStatuses = [
        'single',
        'married',
        'divorced',
        'widowed',
      ];

      if (validStatuses.contains(savedMaritalStatus)) {
        maritalStatus = savedMaritalStatus;
      } else {
        maritalStatus = null;
      }

      // =========================
      // Birth date
      // =========================

      final birthDateData = data['birthDate'];

      if (birthDateData is Timestamp) {
        birthDate = birthDateData.toDate();
      }

      // =========================
      // Photo
      // =========================

      photoUrl = data['photoUrl'];

      // =========================
      // Father
      // =========================

      selectedFatherId = data['pendingFatherId'];

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('ERROR loading user: $e');

      if (mounted) {
        showMessage('حدث خطأ أثناء تحميل بيانات المستخدم');
      }
    }
  }

  // =========================
  // Load family members
  // =========================

  Future<void> loadFamilyMembers() async {
    try {
      final members = await FamilyService().getAllMembers();

      // لا نسمح للمستخدم أن يكون أبًا لنفسه
      allMembers = members
          .where((member) => member.id != widget.userId)
          .toList();
    } catch (e) {
      debugPrint('ERROR loading family members: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingMembers = false;
        });
      }
    }
  }

  // =========================
  // Birth date
  // =========================

  Future<void> pickBirthDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate:
      birthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        birthDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // =========================
  // Upload image
  // =========================

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();

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
          .child('${widget.userId}.jpg');

      await ref.putFile(pickedImageFile!);

      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set(
        {
          'photoUrl': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (mounted) {
        setState(() {
          photoUrl = downloadUrl;
        });

        showMessage('تم تحديث الصورة الشخصية');
      }
    } catch (e) {
      if (mounted) {
        showMessage('حدث خطأ أثناء رفع الصورة');
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploadingImage = false;
        });
      }
    }
  }

  // =========================
  // Save
  // =========================

  Future<void> updateUser() async {
    if (firstNameController.text.trim().isEmpty ||
        secondNameController.text.trim().isEmpty ||
        thirdNameController.text.trim().isEmpty ||
        fourthNameController.text.trim().isEmpty) {
      showMessage(
        'الرجاء تعبئة الاسم كاملاً (الأول، الثاني، الثالث، الرابع)',
      );
      return;
    }

    if (gender == null) {
      showMessage('الرجاء اختيار الجنس');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final fullName =
          '${firstNameController.text.trim()} '
          '${secondNameController.text.trim()} '
          '${thirdNameController.text.trim()} '
          '${fourthNameController.text.trim()}';

      final Map<String, dynamic> data = {
        'firstName': firstNameController.text.trim(),
        'secondName': secondNameController.text.trim(),
        'thirdName': thirdNameController.text.trim(),
        'fourthName': fourthNameController.text.trim(),

        'name': fullName,

        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),

        'gender': gender,

        'maritalStatus': maritalStatus,

        'city': cityController.text.trim(),

        'bio': bioController.text.trim(),

        'pendingFatherId': selectedFatherId,

        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (birthDate != null) {
        data['birthDate'] = Timestamp.fromDate(birthDate!);
      } else {
        data['birthDate'] = FieldValue.delete();
      }

      if (photoUrl != null && photoUrl!.isNotEmpty) {
        data['photoUrl'] = photoUrl;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set(
        data,
        SetOptions(merge: true),
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'تم بنجاح',
              textAlign: TextAlign.right,
            ),
            content: const Text(
              'تم تعديل جميع بيانات المستخدم بنجاح',
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

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('UPDATE USER ERROR: $e');

      if (mounted) {
        showMessage(
          'حدث خطأ أثناء حفظ البيانات: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // =========================
  // Message
  // =========================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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

  // =========================
  // Build
  // =========================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AdminEditUserScreen.bgColor,
        body: Column(
          children: [
            _header(context),

            Expanded(
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AdminEditUserScreen.blue,
                ),
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                ),
                child: _form(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Header
  // =========================

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
                image: AssetImage(
                  'assets/images/header_bg.png',
                ),
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
                    color: AdminEditUserScreen.textColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'العودة',
                    style: TextStyle(
                      color: AdminEditUserScreen.textColor,
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

  // =========================
  // Form
  // =========================

  Widget _form() {
    return Container(
      margin: const EdgeInsets.only(
        top: 25,
        bottom: 30,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xffE6E6E6),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 58,
            width: double.infinity,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
            ),
            color: const Color(0xffF8F8F8),
            child: const Text(
              'تعديل المستخدم',
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
                _profileImage(),

                const SizedBox(height: 20),

                // الاسم الأول
                _inputField(
                  controller: firstNameController,
                  label: 'الاسم الأول',
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 14),

                // الاسم الثاني
                _inputField(
                  controller: secondNameController,
                  label: 'الاسم الثاني',
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 14),

                // الاسم الثالث
                _inputField(
                  controller: thirdNameController,
                  label: 'الاسم الثالث',
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 14),

                // الاسم الرابع
                _inputField(
                  controller: fourthNameController,
                  label: 'الاسم الرابع',
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 14),

                // الهاتف
                _inputField(
                  controller: phoneController,
                  label: 'رقم الجوال',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 14),

                // البريد
                _inputField(
                  controller: emailController,
                  label: 'البريد الإلكتروني',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 14),

                // الجنس
                _genderDropdown(),

                const SizedBox(height: 14),

                // الحالة الاجتماعية
                _maritalDropdown(),

                const SizedBox(height: 14),

                // الأب
                _fatherDropdown(),

                const SizedBox(height: 14),

                // تاريخ الميلاد
                _birthDateField(),

                const SizedBox(height: 14),

                // المدينة
                _inputField(
                  controller: cityController,
                  label: 'المدينة',
                  icon: Icons.location_on_outlined,
                ),

                const SizedBox(height: 14),

                // النبذة
                _inputField(
                  controller: bioController,
                  label: 'نبذة شخصية',
                  icon: Icons.info_outline,
                  maxLines: 3,
                ),

                const SizedBox(height: 24),

                // حفظ
                _saveButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Profile image
  // =========================

  Widget _profileImage() {
    ImageProvider imageProvider;

    if (pickedImageFile != null) {
      imageProvider = FileImage(
        pickedImageFile!,
      );
    } else if (photoUrl != null &&
        photoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(
        photoUrl!,
      );
    } else {
      imageProvider = const AssetImage(
        'assets/images/profile.png',
      );
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 56,
          backgroundColor: Colors.grey.shade100,
          child: CircleAvatar(
            radius: 52,
            backgroundImage: imageProvider,
            child: isUploadingImage
                ? const CircularProgressIndicator(
              color: Colors.white,
            )
                : null,
          ),
        ),

        InkWell(
          onTap: isUploadingImage
              ? null
              : pickAndUploadImage,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  AdminEditUserScreen.mint,
                  AdminEditUserScreen.blue,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 17,
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  // Gender
  // =========================

  Widget _genderDropdown() {
    return _dropdownContainer(
      child: DropdownButtonFormField<String>(
        value: gender,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: AdminEditUserScreen.textColor,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(
            vertical: 16,
          ),
        ),
        hint: const Text(
          'الجنس',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: AdminEditUserScreen.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        items: const [
          DropdownMenuItem(
            value: 'male',
            child: Text('ذكر'),
          ),
          DropdownMenuItem(
            value: 'female',
            child: Text('أنثى'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            gender = value;
          });
        },
      ),
    );
  }

  // =========================
  // Marital status
  // =========================

  Widget _maritalDropdown() {
    return _dropdownContainer(
      child: DropdownButtonFormField<String>(
        value: maritalStatus,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: AdminEditUserScreen.textColor,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(
            vertical: 16,
          ),
        ),
        hint: const Text(
          'الحالة الاجتماعية',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: AdminEditUserScreen.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        items: const [
          DropdownMenuItem(
            value: 'single',
            child: Text('أعزب'),
          ),
          DropdownMenuItem(
            value: 'married',
            child: Text('متزوج'),
          ),
          DropdownMenuItem(
            value: 'divorced',
            child: Text('مطلق'),
          ),
          DropdownMenuItem(
            value: 'widowed',
            child: Text('أرمل'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            maritalStatus = value;
          });
        },
      ),
    );
  }

  // =========================
  // Father
  // =========================

  Widget _fatherDropdown() {
    return _dropdownContainer(
      child: isLoadingMembers
          ? const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 16,
        ),
        child: Center(
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      )
          : DropdownButtonFormField<String?>(
        value: selectedFatherId,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: AdminEditUserScreen.textColor,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(
            vertical: 16,
          ),
        ),
        hint: const Text(
          'اختر الأب في شجرة العائلة',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: AdminEditUserScreen.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text(
              'بدون أب (جذر العائلة)',
            ),
          ),
          ...allMembers.map(
                (member) {
              return DropdownMenuItem<String?>(
                value: member.id,
                child: Text(
                  member.name,
                ),
              );
            },
          ),
        ],
        onChanged: (value) {
          setState(() {
            selectedFatherId = value;
          });
        },
      ),
    );
  }

  // =========================
  // Birth date
  // =========================

  Widget _birthDateField() {
    return InkWell(
      onTap: pickBirthDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cake_outlined,
              color: AdminEditUserScreen.textColor,
              size: 22,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                birthDate != null
                    ? _formatDate(birthDate!)
                    : 'تاريخ الميلاد',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: birthDate != null
                      ? AdminEditUserScreen.titleColor
                      : AdminEditUserScreen.textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Dropdown container
  // =========================

  Widget _dropdownContainer({
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: child,
    );
  }

  // =========================
  // Input
  // =========================

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: AdminEditUserScreen.titleColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AdminEditUserScreen.textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          icon,
          color: AdminEditUserScreen.textColor,
          size: 22,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AdminEditUserScreen.blue,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  // =========================
  // Save button
  // =========================

  Widget _saveButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: isSaving ? null : updateUser,
      child: Container(
        height: 52,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [
              AdminEditUserScreen.mint,
              AdminEditUserScreen.blue,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: AdminEditUserScreen.blue
                  .withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: isSaving
            ? const CircularProgressIndicator(
          color: Colors.white,
        )
            : const Text(
          'حفظ التعديلات',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}