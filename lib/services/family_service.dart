import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/family_member.dart';

class FamilyService {
  final _col = FirebaseFirestore.instance.collection('family_members');
  final _usersCol = FirebaseFirestore.instance.collection('users');

  Future<void> addMember({
    required String name,
    required String gender,
    DateTime? birthDate,
    String? fatherId,
  }) async {
    int generation = 0;
    if (fatherId != null) {
      final fatherDoc = await _col.doc(fatherId).get();
      generation = (fatherDoc.data()?['generation'] ?? 0) + 1;
    }

    await _col.add({
      'name': name,
      'gender': gender,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate) : null,
      'fatherId': fatherId,
      'generation': generation,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<FamilyMember>> getAllMembers() async {
    final snapshot = await _col.orderBy('generation').get();
    return snapshot.docs.map((d) => FamilyMember.fromDoc(d)).toList();
  }

  /// يزامن بيانات مستخدم من users إلى family_members.
  /// fatherId يُقرأ تلقائياً من حقل pendingFatherId في مستند المستخدم
  /// (وهو الحقل اللي بيحدده العضو نفسه من شاشة تعديل البروفايل).
  Future<void> syncMemberFromUser(
      String uid, {
        bool skipStatusCheck = false,
      }) async {
    final userDoc = await _usersCol.doc(uid).get();

    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    final String status = data['status'] ?? 'pending';

    if (!skipStatusCheck && status != 'approved') return;

    final String fullName = [
      data['firstName'],
      data['secondName'],
      data['thirdName'],
      data['fourthName'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');

    if (fullName.trim().isEmpty) return;

    final String? fatherId = data['pendingFatherId'];

    int generation = 0;
    if (fatherId != null) {
      final fatherDoc = await _col.doc(fatherId).get();
      generation = (fatherDoc.data()?['generation'] ?? 0) + 1;
    }

    final existing = await _col.doc(uid).get();

    await _col.doc(uid).set({
      'name': fullName,
      'gender': data['gender'] ?? 'male',
      'birthDate': data['birthDate'],
      'photoUrl': data['photoUrl'],
      'phone': data['phone'],
      'hidePhoneInTree': data['hidePhoneInTree'] ?? false,
      'maritalStatus': data['maritalStatus'],
      'city': data['city'],
      'bio': data['bio'],
      'familyName': data['fourthName'],
      'occupation': data['occupation'],
      'fatherId': fatherId,
      'generation': generation,
      'linkedUserId': uid,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// يجيب اسم عضو معين من family_members (يُستخدم لعرض اسم الأب المقترح
  /// في شاشة إدارة الأعضاء قبل الموافقة).
  Future<String?> getMemberName(String? memberId) async {
    if (memberId == null) return null;
    final doc = await _col.doc(memberId).get();
    if (!doc.exists) return null;
    return doc.data()?['name'];
  }
}