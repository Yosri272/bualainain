import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/family_member.dart';

class FamilyService {
  final _col = FirebaseFirestore.instance.collection('family_members');

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

  Future<void> syncMemberFromUser(String uid, {bool skipStatusCheck = false}) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

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

    final existing = await _col.doc(uid).get();
    final int generation = existing.exists
        ? (existing.data()?['generation'] ?? 0)
        : 0;

    final String? existingFatherId =
    existing.exists ? (existing.data()?['fatherId']) : null;

    await _col.doc(uid).set({
      'name': fullName,
      'gender': data['gender'] ?? 'male',
      'birthDate': data['birthDate'],
      'fatherId': existingFatherId,
      'generation': generation,
      'linkedUserId': uid,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}