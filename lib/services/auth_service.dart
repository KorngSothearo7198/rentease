import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';



class AuthService {


  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register User

  Future<UserModel?> register({
    required String fullName,

    required String email,

    required String password,

    required String phone,

    required String role,

  }) async {


    try {
      // Create Firebase Auth Account

      UserCredential result =
          await _auth.createUserWithEmailAndPassword(

        email: email,

        password: password,

      );



      User user = result.user!;



      // Create Firestore User Data

      UserModel userModel = UserModel(

        uid: user.uid,

        fullName: fullName,

        email: email,

        phone: phone,

        profileImage: "",

        role: role,

        accountStatus: "active",

        createdAt: Timestamp.now(),

        updatedAt: null,

      );



      await _firestore.collection("users").doc(user.uid).set(userModel.toMap());
      return userModel;
    } catch(e){

      print(
        "Register Error: $e"
      );

      return null;

    }

  }




  // Login User

  Future<String?> login({

  required String email,

  required String password,

}) async {


  try {


    UserCredential credential =

    await _auth.signInWithEmailAndPassword(

      email: email,

      password: password,

    );



    String uid = credential.user!.uid;



    DocumentSnapshot snapshot =

    await _firestore

        .collection("users")

        .doc(uid)

        .get();



    if(!snapshot.exists){

      return null;

    }



    Map<String,dynamic> data =

    snapshot.data() as Map<String,dynamic>;



    // Check account status

    if(data["accountStatus"] == "blocked"){


      await logout();


      throw Exception(
        "Your account has been blocked"
      );


    }



    // Return role

    return data["role"];



  }catch(e){


    throw Exception(
      e.toString()
    );


  }

}




  // Logout

  Future<void> logout() async {


    await _auth.signOut();


  }




  // Get Current User

  User? get currentUser {


    return _auth.currentUser;


  }




  // Get User Profile From Firestore

  Future<UserModel?> getUserData(
      String uid
  ) async {


    DocumentSnapshot snapshot =

    await _firestore

        .collection("users")

        .doc(uid)

        .get();



    if(snapshot.exists){


      return UserModel.fromMap(

          snapshot.data()
          as Map<String,dynamic>

      );


    }


    return null;

  }



}