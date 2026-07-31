import 'package:cloud_firestore/cloud_firestore.dart';


class UserModel {

  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String? profileImage;
  final String role;
  final String accountStatus;
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
    required this.createdAt,
    this.updatedAt,

  });



  Map<String, dynamic> toMap(){

    return {

      "uid": uid,

      "fullName": fullName,

      "email": email,

      "phone": phone,

      "profileImage": profileImage ?? "",

      "role": role,

      "accountStatus": accountStatus,

      "createdAt": createdAt,

      "updatedAt": updatedAt,

    };

  }



  factory UserModel.fromMap(
      Map<String,dynamic> map
  ){

    return UserModel(

      uid: map["uid"],

      fullName: map["fullName"],

      email: map["email"],

      phone: map["phone"],

      profileImage: map["profileImage"],

      role: map["role"],

      accountStatus: map["accountStatus"],

      createdAt: map["createdAt"],

      updatedAt: map["updatedAt"],

    );

  }

}