import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {

  final String id;
  final String userId;
  final String ownerId;
  final String bookingId;
  final String houseId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final Timestamp createdAt;


  NotificationModel({

    required this.id,
    required this.userId,
    required this.ownerId,
    required this.bookingId,
    required this.houseId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,

  });



  factory NotificationModel.fromMap(
      String id,
      Map<String,dynamic> map
      ){

    return NotificationModel(

      id: id,

      userId: map["userId"] ?? "",

      bookingId: map["bookingId"] ?? "",

      houseId: map["houseId"] ?? "",

      ownerId: map["ownerId"] ?? "", // IMPORTANT

      title: map["title"] ?? "",

      body: map["body"] ?? "",

      type: map["type"] ?? "",

      isRead: map["isRead"] ?? false,

      createdAt: map["createdAt"] ?? Timestamp.now(),

    );

  }

}