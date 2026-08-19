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
}