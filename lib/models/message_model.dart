import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String message;
  final String messageType;
  final bool isRead;
  final Timestamp createdAt;
  final bool isEdited; // ← added

  MessageModel({
    required this.id,
    required this.senderId,
    required this.message,
    required this.messageType,
    required this.isRead,
    required this.createdAt,
    this.isEdited = false, // ← default false
  });

  Map<String, dynamic> toMap() {
    return {
      "senderId": senderId,
      "message": message,
      "messageType": messageType,
      "isRead": isRead,
      "createdAt": createdAt,
      "isEdited": isEdited, // ← added
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map["senderId"] ?? "",
      message: map["message"] ?? "",
      messageType: map["messageType"] ?? "text",
      isRead: map["isRead"] ?? false,
      createdAt: map["createdAt"] ?? Timestamp.now(),
      isEdited: map["isEdited"] ?? false, // ← added
    );
  }
}