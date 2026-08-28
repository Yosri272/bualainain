import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyMember {
  final String id;
  final String name;
  final String gender;
  final DateTime? birthDate;
  final String? photoUrl;
  final String? fatherId;
  final int generation;
  final String? phone;
  final bool showPhoneInTree;
  final String? maritalStatus;
  final String? city;
  final String? bio;
  final String? familyName; // اسم العائلة (الاسم الرابع)
  final String? occupation;

  FamilyMember({
    required this.id,
    required this.name,
    required this.gender,
    this.birthDate,
    this.photoUrl,
    this.fatherId,
    required this.generation,
    this.phone,
    this.showPhoneInTree = false,
    this.maritalStatus,
    this.city,
    this.bio,
    this.familyName,
    this.occupation,
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
      phone: data['phone'],
      showPhoneInTree: data['showPhoneInTree'] ?? false,
      maritalStatus: data['maritalStatus'],
      city: data['city'],
      bio: data['bio'],
      familyName: data['familyName'],
      occupation: data['occupation'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'gender': gender,
    'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
    'photoUrl': photoUrl,
    'fatherId': fatherId,
    'generation': generation,
    'phone': phone,
    'showPhoneInTree': showPhoneInTree,
    'maritalStatus': maritalStatus,
    'city': city,
    'bio': bio,
    'familyName': familyName,
    'occupation': occupation,
    'createdAt': FieldValue.serverTimestamp(),
  };
}