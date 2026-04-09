import 'package:cloud_firestore/cloud_firestore.dart';

/// EmergencyOS: UserModel in lib/features/auth/domain/user_model.dart.
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? bloodType;
  final List<String> allergies;
  final List<String> medicalConditions;
  final List<Map<String, String>> emergencyContacts;
  final bool isVolunteer;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.bloodType,
    this.allergies = const [],
    this.medicalConditions = const [],
    this.emergencyContacts = const [],
    this.isVolunteer = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'],
      bloodType: map['bloodType'],
      allergies: List<String>.from(map['allergies'] ?? []),
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      emergencyContacts: List<Map<String, String>>.from(
          (map['emergencyContacts'] as List? ?? []).map((e) => Map<String, String>.from(e))),
      isVolunteer: map['isVolunteer'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'bloodType': bloodType,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'emergencyContacts': emergencyContacts,
      'isVolunteer': isVolunteer,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
