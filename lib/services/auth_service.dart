// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import '../models/user_model.dart';
//
// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   // Register User
//
//   Future<UserModel?> register({
//     required String fullName,
//     required String email,
//     required String password,
//     required String phone,
//     required String role,
//
//
//   }) async {
//     try {
//       print("========== AUTH REGISTER DEBUG ==========");
//       print("Full Name: $fullName");
//       print("Email: '$email'");
//       print("Password Length: ${password.length}");
//       print("Phone: $phone");
//       print("Role: $role");
//       print("========================================");
//
//       // Create Firebase Auth Account
//       UserCredential result = await _auth.createUserWithEmailAndPassword(
//         email: email.trim(),
//         password: password.trim(),
//       );
//
//       User user = result.user!;
//
//       print("Firebase User Created");
//       print("UID: ${user.uid}");
//       print("Email: ${user.email}");
//
//       // Create Firestore User Data
//       UserModel userModel = UserModel(
//         uid: user.uid,
//         fullName: fullName,
//         email: email,
//         phone: phone,
//         profileImage: "",
//         role: role,
//         accountStatus: "active",
//
//         // New fields
//         // gender: gender,
//         // age: age,
//         // occupation: occupation,
//         // address: address,
//         // bio: bio,
//
//         gender: "",
//         age: 0,
//         occupation: "",
//         address: "",
//         bio: "",
//
//         createdAt: Timestamp.now(),
//         updatedAt: null,
//       );
//
//       print("Saving Firestore User...");
//
//       await _firestore.collection("users").doc(user.uid).set(userModel.toMap());
//
//       print("Firestore Save Success");
//
//       return userModel;
//     } catch (e, stackTrace) {
//       print("========== REGISTER ERROR ==========");
//       print(e);
//       print(stackTrace);
//       print("===================================");
//
//       return null;
//     }
//   }
//
//   // Login User
//
//
//   Future<UserModel?> login({
//     required String email,
//     required String password,
//   }) async {
//     UserCredential credential = await _auth.signInWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//
//     String uid = credential.user!.uid;
//
//     DocumentSnapshot snapshot = await _firestore
//         .collection("users")
//         .doc(uid)
//         .get();
//
//     if (!snapshot.exists) return null;
//
//     return UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
//   }
//
//   // Get User Token
//   Future<String?> getToken() async {
//     User? user = _auth.currentUser;
//
//     if (user != null) {
//       String? token = await user.getIdToken();
//
//       return token;
//     }
//
//     return null;
//   }
//
//   // Logout
//
//   Future<void> logout() async {
//     await _auth.signOut();
//   }
//
//   // Get Current User
//
//   User? get currentUser {
//     return _auth.currentUser;
//   }
//
//   // Get User Profile From Firestore
//
//   Future<UserModel?> getUserData(String uid) async {
//     DocumentSnapshot snapshot = await _firestore
//         .collection("users")
//         .doc(uid)
//         .get();
//
//     if (snapshot.exists) {
//       return UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
//     }
//
//     return null;
//   }
// }


import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // FIREBASE WEB API KEY
  // ============================================================

  static const String _firebaseApiKey =
      'AIzaSyDiwCCnrKEE6Q4MXNnKHXDaCaIWiTX32TQ';

  // ============================================================
  // REGISTER USER
  // ============================================================

  Future<UserModel?> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    try {
      print("========== AUTH REGISTER DEBUG ==========");
      print("Full Name: $fullName");
      print("Email: '$email'");
      print("Password Length: ${password.length}");
      print("Phone: $phone");
      print("Role: $role");
      print("========================================");

      UserCredential result =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User user = result.user!;

      print("Firebase User Created");
      print("UID: ${user.uid}");
      print("Email: ${user.email}");

      UserModel userModel = UserModel(
        uid: user.uid,
        fullName: fullName,
        email: email,
        phone: phone,
        profileImage: "",
        role: role,
        accountStatus: "active",
        gender: "",
        age: 0,
        occupation: "",
        address: "",
        bio: "",
        createdAt: Timestamp.now(),
        updatedAt: null,
      );

      await _firestore
          .collection("users")
          .doc(user.uid)
          .set(userModel.toMap());

      print("Firestore Save Success");

      return userModel;
    } catch (e, stackTrace) {
      print("========== REGISTER ERROR ==========");
      print(e);
      print(stackTrace);
      print("===================================");

      return null;
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    UserCredential credential =
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    String uid = credential.user!.uid;

    DocumentSnapshot snapshot = await _firestore
        .collection("users")
        .doc(uid)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return UserModel.fromMap(
      snapshot.data() as Map<String, dynamic>,
    );
  }

  // ============================================================
  // SEND PASSWORD RESET CODE
  // ============================================================

  Future<bool> sendPasswordResetCode({
    required String email,
  }) async {
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode'
          '?key=$_firebaseApiKey',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'requestType': 'PASSWORD_RESET',
        'email': email.trim(),
      }),
    );

    print("PASSWORD RESET EMAIL");
    print("Status: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      return true;
    }

    final data = jsonDecode(response.body);

    final errorMessage =
        data['error']?['message'] ?? 'Unable to send reset code.';

    throw Exception(errorMessage);
  }

  // ============================================================
  // VERIFY PASSWORD RESET CODE
  // ============================================================

  Future<String> verifyPasswordResetCode({
    required String code,
  }) async {
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:resetPassword'
          '?key=$_firebaseApiKey',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'oobCode': code.trim(),
      }),
    );

    print("VERIFY PASSWORD RESET CODE");
    print("Status: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['email']?.toString() ?? '';
    }

    final data = jsonDecode(response.body);

    final errorMessage =
        data['error']?['message'] ?? 'Invalid reset code.';

    throw Exception(errorMessage);
  }

  // ============================================================
  // CONFIRM NEW PASSWORD
  // ============================================================

  Future<String> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:resetPassword'
          '?key=$_firebaseApiKey',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'oobCode': code.trim(),
        'newPassword': newPassword,
      }),
    );

    print("CONFIRM PASSWORD RESET");
    print("Status: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['email']?.toString() ?? '';
    }

    final data = jsonDecode(response.body);

    final errorMessage =
        data['error']?['message'] ?? 'Unable to reset password.';

    throw Exception(errorMessage);
  }

  // ============================================================
  // GET USER TOKEN
  // ============================================================

  Future<String?> getToken() async {
    User? user = _auth.currentUser;

    if (user != null) {
      return await user.getIdToken();
    }

    return null;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser {
    return _auth.currentUser;
  }

  // ============================================================
  // GET USER PROFILE
  // ============================================================

  Future<UserModel?> getUserData(String uid) async {
    DocumentSnapshot snapshot = await _firestore
        .collection("users")
        .doc(uid)
        .get();

    if (snapshot.exists) {
      return UserModel.fromMap(
        snapshot.data() as Map<String, dynamic>,
      );
    }

    return null;
  }
}