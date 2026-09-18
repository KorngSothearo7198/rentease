import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;

  final String renterId;

  final String ownerId;

  final String houseId;

  final String propertyName;

  final String lastMessage;

  final Timestamp updatedAt;

  ConversationModel({
    required this.id,

    required this.renterId,

    required this.ownerId,

    required this.houseId,

    required this.propertyName,

    required this.lastMessage,

    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "renterId": renterId,

      "ownerId": ownerId,

      "houseId": houseId,

      "propertyName": propertyName,

      "lastMessage": lastMessage,

      "updatedAt": updatedAt,
    };
  }
}
