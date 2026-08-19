import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyMember {
  final String id;
  final String name;
  final String gender;
  final DateTime? birthDate;
  final String? photoUrl;
  final String? fatherId;
  final int generation;

  FamilyMember({
    required this.id,
    required this.name,
    required this.gender,
    this.birthDate,
    this.photoUrl,
    this.fatherId,
    required this.generation,
  });

  factory FamilyMember.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyMember(
      id: doc.id,
      name: data['name'] ?? '',
      gender: data['gender'] ?? 'male',
      birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
      photoUrl: data['photoUrl'],
      fatherId: data['fatherId'],
      generation: data['generation'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'gender': gender,
    'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
    'photoUrl': photoUrl,
    'fatherId': fatherId,
    'generation': generation,
    'createdAt': FieldValue.serverTimestamp(),
  };
}