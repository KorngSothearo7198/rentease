import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // CREATE CONVERSATION ID
  // ============================================================

  String createConversationId(
      String user1,
      String user2,
      String houseId,
      ) {
    final ids = [user1, user2]..sort();

    return '${ids[0]}_${ids[1]}_$houseId';
  }
  // ============================================================
  // CREATE CONVERSATION
  // ============================================================

  // Future<void> createConversation({
  //   required String conversationId,
  //   required String renterId,
  //   required String ownerId,
  //   required String houseId,
  //   required String propertyName,
  // }) async {
  //   final ref = _firestore.collection("conversations").doc(conversationId);
  //
  //   final doc = await ref.get();
  //
  //   // Conversation already exists
  //   if (doc.exists) {
  //     return;
  //   }
  //
  //   // Get renter information
  //   final renterDoc = await _firestore.collection("users").doc(renterId).get();
  //
  //   String renterName = "Renter";
  //   String renterImage = "";
  //
  //   if (renterDoc.exists && renterDoc.data() != null) {
  //     final userData = renterDoc.data()!;
  //
  //     renterName = userData["fullName"] ?? "Renter";
  //     renterImage = userData["profileImage"] ?? "";
  //   }
  //
  //   // Create conversation
  //   await ref.set({
  //     "renterId": renterId,
  //     "renterName": renterName,
  //     "renterImage": renterImage,
  //     "ownerId": ownerId,
  //     "houseId": houseId,
  //     "propertyName": propertyName,
  //     "lastMessage": "",
  //     "updatedAt": Timestamp.now(),
  //   });
  // }

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
    final ref = _firestore.collection("conversations").doc(conversationId);

    final doc = await ref.get();

    // ============================================================
    // CONVERSATION ALREADY EXISTS
    // ============================================================

    if (doc.exists) {
      return;
    }

    // ============================================================
    // GET RENTER INFORMATION
    // ============================================================

    final renterDoc = await _firestore.collection("users").doc(renterId).get();

    String renterName = "Renter";
    String renterImage = "";

    if (renterDoc.exists && renterDoc.data() != null) {
      final renterData = renterDoc.data()!;

      renterName = renterData["fullName"] ?? "Renter";
      renterImage = renterData["profileImage"] ?? "";
    }

    // ============================================================
    // GET OWNER INFORMATION
    // ============================================================

    final ownerDoc = await _firestore.collection("users").doc(ownerId).get();

    String ownerName = "Owner";
    String ownerImage = "";

    if (ownerDoc.exists && ownerDoc.data() != null) {
      final ownerData = ownerDoc.data()!;

      ownerName = ownerData["fullName"] ?? "Owner";
      ownerImage = ownerData["profileImage"] ?? "";
    }

    // ============================================================
    // CREATE CONVERSATION
    // ============================================================

    await ref.set({
      // ----------------------------------------------------------
      // PARTICIPANTS
      // ----------------------------------------------------------
      "participants": [renterId, ownerId],

      // ----------------------------------------------------------
      // RENTER
      // ----------------------------------------------------------
      "renterId": renterId,
      "renterName": renterName,
      "renterImage": renterImage,

      // ----------------------------------------------------------
      // OWNER
      // ----------------------------------------------------------
      "ownerId": ownerId,
      "ownerName": ownerName,
      "ownerImage": ownerImage,

      // ----------------------------------------------------------
      // PROPERTY
      // ----------------------------------------------------------
      "houseId": houseId,
      "propertyName": propertyName,

      // ----------------------------------------------------------
      // LAST MESSAGE
      // ----------------------------------------------------------
      "lastMessage": "",

      // ----------------------------------------------------------
      // TIME
      // ----------------------------------------------------------
      "updatedAt": Timestamp.now(),
    });
  }

  Future<void> _updateConversationPeople({
    required String conversationId,
    required String renterId,
    required String ownerId,
  }) async {
    try {

      final renterDoc = await _firestore
          .collection("users")
          .doc(renterId)
          .get();

      final ownerDoc = await _firestore.collection("users").doc(ownerId).get();

      final Map<String, dynamic> updateData = {
        "renterId": renterId,
        "ownerId": ownerId,
        "participants": [renterId, ownerId],
      };

      if (renterDoc.exists && renterDoc.data() != null) {
        final renterData = renterDoc.data()!;

        updateData["renterName"] =
            renterData["fullName"]?.toString() ?? "Renter";

        updateData["renterImage"] =
            renterData["profileImage"]?.toString() ?? "";
      }

      // ----------------------------------------------------------
      // OWNER INFORMATION
      // ----------------------------------------------------------

      if (ownerDoc.exists && ownerDoc.data() != null) {
        final ownerData = ownerDoc.data()!;

        updateData["ownerName"] = ownerData["fullName"]?.toString() ?? "Owner";

        updateData["ownerImage"] = ownerData["profileImage"]?.toString() ?? "";
      }

      await _firestore
          .collection("conversations")
          .doc(conversationId)
          .set(updateData, SetOptions(merge: true));
    } catch (e) {
      print("Update conversation people error: $e");
    }
  }


  Stream<int> getOwnerUnreadMessageCount(String ownerId) {
    final controller = StreamController<int>();

    // Listen to messages separately for each conversation.
    final Map<
        String,
        StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
    > messageSubscriptions = {};

    // Store the unread count for each conversation.
    final Map<String, int> unreadCounts = {};

    // Store each conversation's renter ID.
    final Map<String, String> renterIds = {};

    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    conversationsSubscription;

    void emitTotal() {
      if (controller.isClosed) return;

      final total = unreadCounts.values.fold<int>(
        0,
            (sum, count) => sum + count,
      );

      controller.add(total);
    }

    conversationsSubscription = _firestore
        .collection('conversations')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .listen(
          (conversationSnapshot) {
        final activeIds = conversationSnapshot.docs
            .map((doc) => doc.id)
            .toSet();

        // Remove listeners for deleted conversations.
        for (final id in messageSubscriptions.keys.toList()) {
          if (!activeIds.contains(id)) {
            messageSubscriptions.remove(id)?.cancel();
            unreadCounts.remove(id);
            renterIds.remove(id);
          }
        }

        for (final conversation in conversationSnapshot.docs) {
          final data = conversation.data();
          final conversationId = conversation.id;
          final renterId = data['renterId']?.toString() ?? '';

          if (renterId.isEmpty) continue;

          // Recreate the listener if the renter ID has changed.
          if (messageSubscriptions.containsKey(conversationId) &&
              renterIds[conversationId] != renterId) {
            messageSubscriptions.remove(conversationId)?.cancel();
            unreadCounts.remove(conversationId);
          }

          renterIds[conversationId] = renterId;

          // Avoid creating duplicate listeners.
          if (messageSubscriptions.containsKey(conversationId)) {
            continue;
          }

          messageSubscriptions[conversationId] = conversation.reference
              .collection('messages')
              .where('isRead', isEqualTo: false)
              .snapshots()
              .listen(
                (messageSnapshot) {
              // Count only unread messages sent by the renter.
              final count = messageSnapshot.docs.where((message) {
                final messageData = message.data();

                return messageData['senderId']?.toString() == renterId &&
                    messageData['isRead'] == false;
              }).length;

              unreadCounts[conversationId] = count;

              // Update the badge immediately when messages change.
              emitTotal();
            },
            onError: (Object error) {
              debugPrint(
                '[CHAT SERVICE] Message listener error: $error',
              );

              if (!controller.isClosed) {
                controller.addError(error);
              }
            },
          );
        }

        emitTotal();
      },
      onError: (Object error) {
        debugPrint(
          '[CHAT SERVICE] Conversation listener error: $error',
        );

        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    // Clean up all listeners when the stream is cancelled.
    controller.onCancel = () async {
      await conversationsSubscription?.cancel();

      for (final subscription in messageSubscriptions.values) {
        await subscription.cancel();
      }

      messageSubscriptions.clear();
      unreadCounts.clear();
      renterIds.clear();
    };

    return controller.stream;
  }



  Stream<int> getRenterUnreadMessageCount(String renterId) {
    final controller = StreamController<int>();

    final Map<
        String,
        StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
    > messageSubscriptions = {};

    final Map<String, int> unreadCounts = {};
    final Map<String, String> ownerIds = {};

    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    conversationsSubscription;

    void emitTotal() {
      if (controller.isClosed) return;

      final total = unreadCounts.values.fold<int>(
        0,
            (sum, count) => sum + count,
      );

      controller.add(total);
    }

    conversationsSubscription = _firestore
        .collection('conversations')
        .where('renterId', isEqualTo: renterId)
        .snapshots()
        .listen(
          (conversationSnapshot) {
        final activeIds =
        conversationSnapshot.docs.map((doc) => doc.id).toSet();

        for (final id in messageSubscriptions.keys.toList()) {
          if (!activeIds.contains(id)) {
            messageSubscriptions.remove(id)?.cancel();
            unreadCounts.remove(id);
            ownerIds.remove(id);
          }
        }

        for (final conversation in conversationSnapshot.docs) {
          final conversationId = conversation.id;
          final data = conversation.data();
          final ownerId = data['ownerId']?.toString() ?? '';

          if (ownerId.isEmpty) continue;

          if (messageSubscriptions.containsKey(conversationId) &&
              ownerIds[conversationId] != ownerId) {
            messageSubscriptions.remove(conversationId)?.cancel();
            unreadCounts.remove(conversationId);
          }

          ownerIds[conversationId] = ownerId;

          if (messageSubscriptions.containsKey(conversationId)) {
            continue;
          }

          messageSubscriptions[conversationId] = conversation.reference
              .collection('messages')
              .where('isRead', isEqualTo: false)
              .snapshots()
              .listen(
                (messageSnapshot) {
              final count = messageSnapshot.docs.where((message) {
                final messageData = message.data();

                return messageData['senderId']?.toString() == ownerId &&
                    messageData['isRead'] == false;
              }).length;

              unreadCounts[conversationId] = count;
              emitTotal();
            },
            onError: (Object error) {
              debugPrint(
                '[CHAT SERVICE] Renter message listener error: $error',
              );

              if (!controller.isClosed) {
                controller.addError(error);
              }
            },
          );
        }

        emitTotal();
      },
      onError: (Object error) {
        debugPrint(
          '[CHAT SERVICE] Renter conversation listener error: $error',
        );

        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    controller.onCancel = () async {
      await conversationsSubscription?.cancel();

      for (final subscription in messageSubscriptions.values) {
        await subscription.cancel();
      }

      messageSubscriptions.clear();
      unreadCounts.clear();
      ownerIds.clear();
    };

    return controller.stream;
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

      // Get latest renter information
      final renterDoc = await _firestore
          .collection("users")
          .doc(renterId)
          .get();

      if (!renterDoc.exists || renterDoc.data() == null) {
        return;
      }

      final renterData = renterDoc.data()!;

      // Update conversation renter information
      await _firestore.collection("conversations").doc(conversationId).update({
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

  Stream<QuerySnapshot> getRenterConversations(String renterId) {
    return _firestore
        .collection("conversations")
        .where("renterId", isEqualTo: renterId)
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
    final chatRef = _firestore.collection("conversations").doc(conversationId);

    // Add message
    await chatRef.collection("messages").add(message.toMap());

    // Text message
    String lastMessage = message.message;

    // Handle different message types
    switch (message.messageType) {
      case "image":
        lastMessage = "📷 Photo";
        break;

      case "audio":
        lastMessage = "🎤 Voice message";
        break;

      case "text":
      default:
        lastMessage = message.message;
    }

    // Update conversation preview
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
    final chatRef = _firestore.collection("conversations").doc(conversationId);

    // Add image message
    await chatRef.collection("messages").add(message.toMap());

    // Update conversation preview
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
    final chatRef = _firestore.collection("conversations").doc(conversationId);

    // Add audio message
    await chatRef.collection("messages").add(message.toMap());

    // Update conversation preview
    await chatRef.update({
      "lastMessage": "🎤 Voice message",
      "updatedAt": Timestamp.now(),
    });
  }

  // ============================================================
// GET MESSAGES
// ============================================================

  Stream<List<MessageModel>> getMessages(
      String conversationId,
      ) {
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
// MARK MESSAGE AS READ
// ============================================================

  Future<void> markMessageAsRead(
      String conversationId,
      String messageId,
      ) async {
    try {
      await _firestore
          .collection("conversations")
          .doc(conversationId)
          .collection("messages")
          .doc(messageId)
          .update({
        "isRead": true,
      });
    } catch (e) {
      print("Mark message as read error: $e");
    }
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

    await _updateLastMessage(
      conversationId,
    );
  }

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

    // Update message
    await messageRef.update({
      "message": newText,
      "isEdited": true,
      "updatedAt": Timestamp.now(),
    });

    // Update conversation preview
    await _firestore.collection("conversations").doc(conversationId).update({
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

      // Image
      if (type == "image") {
        lastMessage = "📷 Photo";
      }
      // Audio
      else if (type == "audio") {
        lastMessage = "🎤 Voice message";
      }
      // Text
      else {
        lastMessage = data["message"]?.toString() ?? "";
      }
    }

    // Update conversation
    await _firestore.collection("conversations").doc(conversationId).update({
      "lastMessage": lastMessage,
      "updatedAt": Timestamp.now(),
    });
  }
}
