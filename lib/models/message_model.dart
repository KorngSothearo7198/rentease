
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String message;

  // Media URLs
  final String? imageUrl;
  final String? audioUrl;

  // Message type:
  // text  = normal text message
  // image = image message
  // audio = voice message
  final String messageType;

  final bool isRead;
  final Timestamp createdAt;
  final bool isEdited;

  final int? durationSeconds;


  MessageModel({
    required this.id,
    required this.senderId,
    required this.message,
    this.imageUrl,
    this.audioUrl,
    required this.messageType,
    required this.isRead,
    required this.createdAt,
    this.isEdited = false,
    this.durationSeconds,

  });

  // ============================================================
  // TO MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      "senderId": senderId,
      "message": message,

      // Image URL
      "imageUrl": imageUrl,

      // Voice URL
      "audioUrl": audioUrl,

      // text / image / audio
      "messageType": messageType,

      "isRead": isRead,
      "createdAt": createdAt,
      "isEdited": isEdited,
      "durationSeconds": durationSeconds,

    };
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory MessageModel.fromMap(
      Map<String, dynamic> map,
      String id,
      ) {
    return MessageModel(
      id: id,
      senderId: map["senderId"] ?? "",
      message: map["message"] ?? "",
      imageUrl: map["imageUrl"],
      audioUrl: map["audioUrl"],
      messageType: map["messageType"] ?? "text",
      isRead: map["isRead"] ?? false,
      createdAt: map["createdAt"] is Timestamp
          ? map["createdAt"] as Timestamp
          : Timestamp.now(),
      isEdited: map["isEdited"] ?? false,

      durationSeconds: map["durationSeconds"] is num
          ? (map["durationSeconds"] as num).toInt()
          : null,
    );
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? message,
    String? imageUrl,
    String? audioUrl,
    String? messageType,
    bool? isRead,
    Timestamp? createdAt,
    bool? isEdited,

    int? durationSeconds,

  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      messageType: messageType ?? this.messageType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      isEdited: isEdited ?? this.isEdited,

      durationSeconds:
      durationSeconds ?? this.durationSeconds,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get isText => messageType == "text";

  bool get isImage => messageType == "image";

  bool get isAudio => messageType == "audio";

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'MessageModel('
        'id: $id, '
        'senderId: $senderId, '
        'message: $message, '
        'imageUrl: $imageUrl, '
        'audioUrl: $audioUrl, '
        'messageType: $messageType, '
        'isRead: $isRead, '
        'createdAt: $createdAt, '
        'isEdited: $isEdited'
        ')';

  }
}