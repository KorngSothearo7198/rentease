import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // GET CURRENT USER
  // ============================================================

  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        print('❌ No authenticated user');
        return null;
      }

      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        print('⚠️ User document not found');
        return null;
      }

      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      print('❌ Get current user error: $e');
      return null;
    }
  }

  // ============================================================
  // SAVE USER
  // ============================================================

  Future<bool> saveUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        user.toMap(),
        SetOptions(merge: true),
      );

      print(' User saved successfully');

      return true;
    } catch (e) {
      print(' Save user error: $e');
      return false;
    }
  }

  // ============================================================
  // UPDATE PERSONAL INFORMATION
  // ============================================================

  Future<bool> updatePersonalInfo({
    required String uid,
    required String fullName,
    required String phone,
    required String gender,
    required int age,
    required String occupation,
    required String address,
    required String bio,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({
        'fullName': fullName,
        'phone': phone,
        'gender': gender,
        'age': age,
        'occupation': occupation,
        'address': address,
        'bio': bio,
        'updatedAt': Timestamp.now(),
      });

      print(' Personal information updated');

      return true;
    } catch (e) {
      print(' Update personal information error: $e');
      return false;
    }
  }

  // ============================================================
  // UPDATE PROFILE IMAGE
  // ============================================================

  Future<bool> updateProfileImage({
    required String uid,
    required String imageUrl,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({
        'profileImage': imageUrl,
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('❌ Update profile image error: $e');
      return false;
    }
  }

  // ============================================================
// GET ADMIN USER
// ============================================================

  Future<UserModel?> getAdmin() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('⚠️ Admin user not found');
        return null;
      }

      return UserModel.fromMap(querySnapshot.docs.first.data());
    } catch (e) {
      print('❌ Get admin user error: $e');
      return null;
    }
  }


}