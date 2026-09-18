// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import '../models/message_model.dart';
//
// class ChatService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   // Create Conversation ID
//
//   String createConversationId(String user1, String user2) {
//     if (user1.compareTo(user2) < 0) {
//       return "${user1}_$user2";
//     }
//
//     return "${user2}_$user1";
//   }
//
//   Future<void> createConversation({
//     required String conversationId,
//     required String renterId,
//     required String ownerId,
//     required String houseId,
//     required String propertyName,
//   }) async {
//     try {
//       final ref = _firestore
//           .collection("conversations")
//           .doc(conversationId);
//
//       final doc = await ref.get();
//
//       // Conversation already exists
//       if (doc.exists) {
//         return;
//       }
//
//       // Get renter information
//       final renterDoc = await _firestore
//           .collection("users")
//           .doc(renterId)
//           .get();
//
//       String renterName = "Renter";
//       String renterImage = "";
//
//       if (renterDoc.exists && renterDoc.data() != null) {
//         final userData = renterDoc.data()!;
//
//         renterName = userData["fullName"] ?? "Renter";
//         renterImage = userData["profileImage"] ?? "";
//       }
//
//       // Create conversation
//       await ref.set({
//         "renterId": renterId,
//         "renterName": renterName,
//         "renterImage": renterImage,
//
//         "ownerId": ownerId,
//
//         "houseId": houseId,
//         "propertyName": propertyName,
//
//         "lastMessage": "",
//         "updatedAt": Timestamp.now(),
//       });
//
//     } catch (e) {
//       print("Create Conversation Error: $e");
//     }
//   }
//
//   Future<void> updateRenterInfo(String conversationId) async {
//     try {
//       final conversationDoc = await _firestore
//           .collection("conversations")
//           .doc(conversationId)
//           .get();
//
//       if (!conversationDoc.exists) {
//         return;
//       }
//
//       final data = conversationDoc.data();
//
//       if (data == null) {
//         return;
//       }
//
//       final renterId = data["renterId"];
//
//       if (renterId == null || renterId.toString().isEmpty) {
//         return;
//       }
//
//       final renterDoc = await _firestore
//           .collection("users")
//           .doc(renterId)
//           .get();
//
//       if (!renterDoc.exists || renterDoc.data() == null) {
//         return;
//       }
//
//       final renterData = renterDoc.data()!;
//
//       await _firestore
//           .collection("conversations")
//           .doc(conversationId)
//           .update({
//         "renterName": renterData["fullName"] ?? "Renter",
//         "renterImage": renterData["profileImage"] ?? "",
//       });
//
//     } catch (e) {
//       print("Update renter info error: $e");
//     }
//   }
//
//
//
//   Stream<QuerySnapshot> getOwnerConversations(String ownerId) {
//     return _firestore
//         .collection("conversations")
//         .where("ownerId", isEqualTo: ownerId)
//         .orderBy("updatedAt", descending: true)
//         .snapshots();
//   }
//
//   // Send Message
//
//   Future<void> sendMessage({
//     required String conversationId,
//
//     required MessageModel message,
//   }) async {
//     final chatRef = _firestore.collection("conversations").doc(conversationId);
//
//     await chatRef.collection("messages").add(message.toMap());
//
//     // update last message
//
//     await chatRef.update({
//       "lastMessage": message.message,
//
//       "updatedAt": Timestamp.now(),
//     });
//   }
//
//   // Get Messages realtime
//
//   Stream<List<MessageModel>> getMessages(String conversationId) {
//     return _firestore
//         .collection("conversations")
//         .doc(conversationId)
//         .collection("messages")
//         .orderBy("createdAt")
//         .snapshots()
//         .map((snapshot) {
//           return snapshot.docs.map((doc) {
//             return MessageModel.fromMap(doc.data(), doc.id);
//           }).toList();
//         });
//   }
//
//   // Add these methods inside ChatService class
//
//   Future<void> deleteMessage({
//     required String conversationId,
//     required String messageId,
//   }) async {
//     await _firestore
//         .collection("conversations")
//         .doc(conversationId)
//         .collection("messages")
//         .doc(messageId)
//         .delete();
//   }
//
//   Future<void> editMessage({
//     required String conversationId,
//     required String messageId,
//     required String newText,
//   }) async {
//     await _firestore
//         .collection("conversations")
//         .doc(conversationId)
//         .collection("messages")
//         .doc(messageId)
//         .update({
//       "message": newText,
//       "isEdited": true,
//       "updatedAt": Timestamp.now(),
//     });
//   }
//
//   Future<void> sendImageMessage({
//     required String conversationId,
//     required MessageModel message,
//   }) async {
//     final chatRef = _firestore.collection("conversations").doc(conversationId);
//
//     await chatRef.collection("messages").add(message.toMap());
//
//     await chatRef.update({
//       "lastMessage": "📷 Photo",
//       "updatedAt": Timestamp.now(),
//     });
//   }
//
//
// }

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // CREATE CONVERSATION ID
  // ============================================================

  String createConversationId(String user1, String user2) {
    if (user1.compareTo(user2) < 0) {
      return "${user1}_$user2";
    }

    return "${user2}_$user1";
  }

  // ============================================================
  // CREATE CONVERSATION
  // ============================================================

  Future<void> createConversation({
    required String conversationId,
    required String renterId,
    required String ownerId,
    required String houseId,
    required String propertyName,
  }) async {
    final ref = _firestore
        .collection("conversations")
        .doc(conversationId);

    final doc = await ref.get();

    if (doc.exists) {
      return;
    }

    final renterDoc = await _firestore
        .collection("users")
        .doc(renterId)
        .get();

    String renterName = "Renter";
    String renterImage = "";

    if (renterDoc.exists && renterDoc.data() != null) {
      final userData = renterDoc.data()!;

      renterName = userData["fullName"] ?? "Renter";
      renterImage = userData["profileImage"] ?? "";
    }

    await ref.set({
      "renterId": renterId,
      "renterName": renterName,
      "renterImage": renterImage,
      "ownerId": ownerId,
      "houseId": houseId,
      "propertyName": propertyName,
      "lastMessage": "",
      "updatedAt": Timestamp.now(),
    });
  }

  // ============================================================
  // UPDATE RENTER INFO
  // ============================================================

  Future<void> updateRenterInfo(String conversationId) async {
    try {
      final conversationDoc = await _firestore
          .collection("conversations")
          .doc(conversationId)
          .get();

      if (!conversationDoc.exists) {
        return;
      }

      final data = conversationDoc.data();

      if (data == null) {
        return;
      }

      final renterId = data["renterId"];

      if (renterId == null || renterId.toString().isEmpty) {
        return;
      }

      final renterDoc = await _firestore
          .collection("users")
          .doc(renterId)
          .get();

      if (!renterDoc.exists || renterDoc.data() == null) {
        return;
      }

      final renterData = renterDoc.data()!;

      await _firestore
          .collection("conversations")
          .doc(conversationId)
          .update({
        "renterName": renterData["fullName"] ?? "Renter",
        "renterImage": renterData["profileImage"] ?? "",
      });
    } catch (e) {
      print("Update renter info error: $e");
    }
  }

  // ============================================================
  // OWNER CONVERSATIONS
  // ============================================================

  Stream<QuerySnapshot> getOwnerConversations(String ownerId) {
    return _firestore
        .collection("conversations")
        .where("ownerId", isEqualTo: ownerId)
        .orderBy("updatedAt", descending: true)
        .snapshots();
  }

  // ============================================================
  // SEND TEXT MESSAGE
  // ============================================================

  Future<void> sendMessage({
    required String conversationId,
    required MessageModel message,
  }) async {
    final chatRef = _firestore
        .collection("conversations")
        .doc(conversationId);

    await chatRef
        .collection("messages")
        .add(message.toMap());

    String lastMessage = message.message;

    switch (message.messageType) {
      case "image":
        lastMessage = "📷 Photo";
        break;

      case "voice":
        lastMessage = "🎤 Voice message";
        break;

      case "text":
      default:
        lastMessage = message.message;
    }

    await chatRef.update({
      "lastMessage": lastMessage,
      "updatedAt": Timestamp.now(),
    });
  }

  // ============================================================
  // SEND IMAGE MESSAGE
  // ============================================================

  Future<void> sendImageMessage({
    required String conversationId,
    required MessageModel message,
  }) async {
    final chatRef = _firestore
        .collection("conversations")
        .doc(conversationId);

    await chatRef
        .collection("messages")
        .add(message.toMap());

    await chatRef.update({
      "lastMessage": "📷 Photo",
      "updatedAt": Timestamp.now(),
    });
  }

  // ============================================================
  // SEND VOICE MESSAGE
  // ============================================================

  Future<void> sendVoiceMessage({
    required String conversationId,
    required MessageModel message,
  }) async {
    final chatRef = _firestore
        .collection("conversations")
        .doc(conversationId);

    await chatRef
        .collection("messages")
        .add(message.toMap());

    await chatRef.update({
      "lastMessage": "🎤 Voice message",
      "updatedAt": Timestamp.now(),
    });
  }

  // ============================================================
  // GET MESSAGES
  // ============================================================

  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _firestore
        .collection("conversations")
        .doc(conversationId)
        .collection("messages")
        .orderBy("createdAt")
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromMap(
          doc.data(),
          doc.id,
        );
      }).toList();
    });
  }

  // ============================================================
  // DELETE MESSAGE
  // ============================================================

  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    final messageRef = _firestore
        .collection("conversations")
        .doc(conversationId)
        .collection("messages")
        .doc(messageId);

    await messageRef.delete();

    await _updateLastMessage(conversationId);
  }

  // ============================================================
  // EDIT MESSAGE
  // ============================================================

  Future<void> editMessage({
    required String conversationId,
    required String messageId,
    required String newText,
  }) async {
    final messageRef = _firestore
        .collection("conversations")
        .doc(conversationId)
        .collection("messages")
        .doc(messageId);

    await messageRef.update({
      "message": newText,
      "isEdited": true,
      "updatedAt": Timestamp.now(),
    });

    await _firestore
        .collection("conversations")
        .doc(conversationId)
        .update({
      "lastMessage": newText,
      "updatedAt": Timestamp.now(),
    });
  }

  // ============================================================
  // UPDATE LAST MESSAGE AFTER DELETE
  // ============================================================

  Future<void> _updateLastMessage(String conversationId) async {
    final snapshot = await _firestore
        .collection("conversations")
        .doc(conversationId)
        .collection("messages")
        .orderBy("createdAt", descending: true)
        .limit(1)
        .get();

    String lastMessage = "";

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();

      final type = data["messageType"]?.toString() ?? "text";

      if (type == "image") {
        lastMessage = "📷 Photo";
      } else if (type == "voice") {
        lastMessage = "🎤 Voice message";
      } else {
        lastMessage = data["message"]?.toString() ?? "";
      }
    }

    await _firestore
        .collection("conversations")
        .doc(conversationId)
        .update({
      "lastMessage": lastMessage,
      "updatedAt": Timestamp.now(),
    });
  }
}
