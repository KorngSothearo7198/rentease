
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String? profileImage;
  final String role;
  final String accountStatus;

  final String gender;
  final int age;
  final String occupation;
  final String address;
  final String bio;

  final Timestamp createdAt;
  final Timestamp? updatedAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    this.profileImage,
    required this.role,
    required this.accountStatus,
    required this.gender,
    required this.age,
    required this.occupation,
    required this.address,
    required this.bio,
    required this.createdAt,
    this.updatedAt,
  });

  // ============================================================
  // FIRESTORE -> MODEL
  // ============================================================

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',

      profileImage: _cleanString(map['profileImage']),

      role: map['role']?.toString() ?? '',
      accountStatus: map['accountStatus']?.toString() ?? '',

      gender: map['gender']?.toString() ?? '',
      age: _parseAge(map['age']),
      occupation: map['occupation']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      bio: map['bio']?.toString() ?? '',

      createdAt: map['createdAt'] is Timestamp
          ? map['createdAt'] as Timestamp
          : Timestamp.now(),

      updatedAt: map['updatedAt'] is Timestamp
          ? map['updatedAt'] as Timestamp
          : null,
    );
  }

  // ============================================================
  // MODEL -> FIRESTORE
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'profileImage': profileImage ?? '',
      'role': role,
      'accountStatus': accountStatus,

      'gender': gender,
      'age': age,
      'occupation': occupation,
      'address': address,
      'bio': bio,

      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // ============================================================
  // MODEL -> LOCAL JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'profileImage': profileImage ?? '',
      'role': role,
      'accountStatus': accountStatus,

      'gender': gender,
      'age': age,
      'occupation': occupation,
      'address': address,
      'bio': bio,

      'createdAt': createdAt.toDate().toIso8601String(),
      'updatedAt': updatedAt?.toDate().toIso8601String(),
    };
  }

  // ============================================================
  // JSON -> MODEL
  // ============================================================

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',

      profileImage: _cleanString(json['profileImage']),

      role: json['role']?.toString() ?? '',
      accountStatus: json['accountStatus']?.toString() ?? '',

      gender: json['gender']?.toString() ?? '',
      age: _parseAge(json['age']),
      occupation: json['occupation']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',

      createdAt: _parseTimestamp(json['createdAt']) ?? Timestamp.now(),

      updatedAt: _parseTimestamp(json['updatedAt']),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static String? _cleanString(dynamic value) {
    if (value == null) return null;

    final result = value.toString().trim();

    if (result.isEmpty) return null;

    return result;
  }

  static int _parseAge(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  static Timestamp? _parseTimestamp(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value;
    }

    if (value is String) {
      try {
        return Timestamp.fromDate(DateTime.parse(value));
      } catch (_) {
        return null;
      }
    }

    return null;
  }
}