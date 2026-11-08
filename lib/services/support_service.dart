import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/support_ticket_model.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String collectionName = 'supportTickets';
  final String notificationCollection = 'notifications';

  // ==========================================================
  // CREATE TICKET: OWNER -> ADMIN
  // ==========================================================

  Future<String> createTicket({
    required String userId,
    required String userName,
    required String userEmail,
    required String userRole,
    required String adminId,
    required String subject,
    required String message,
  }) async {
    final ticketRef = _firestore.collection(collectionName).doc();
    final batch = _firestore.batch();

    final ticket = SupportTicketModel(
      ticketId: ticketRef.id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userRole: userRole,
      adminId: adminId,
      subject: subject,
      message: message,
      status: 'open',
      createdAt: DateTime.now(),
      updatedAt: null,
    );

    batch.set(ticketRef, ticket.toFirestore());

    // Store the first message in the conversation.
    final firstMessageRef = ticketRef.collection('messages').doc();

    batch.set(firstMessageRef, {
      'senderId': userId,
      'senderName': userName,
      'senderRole': userRole,
      'message': message.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Notify the admin web dashboard.
    final notificationRef = _firestore.collection(notificationCollection).doc();

    batch.set(notificationRef, {
      'userId': adminId,
      'role': 'admin',
      'title': 'New Support Ticket',
      'body': '$userName submitted a support ticket: $subject',
      'type': 'support_ticket',
      'isRead': false,
      'relatedId': ticketRef.id,
      'relatedType': 'supportTicket',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return ticketRef.id;
  }

  // ==========================================================
  // OWNER TICKET LIST
  // ==========================================================

  Stream<List<SupportTicketModel>> userTickets(String userId) {
    return _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SupportTicketModel.fromFirestore(doc))
              .toList();
        });
  }

  // ==========================================================
  // ADMIN TICKET LIST
  // ==========================================================

  Stream<List<SupportTicketModel>> adminTickets(String adminId) {
    return _firestore
        .collection(collectionName)
        .where('adminId', isEqualTo: adminId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SupportTicketModel.fromFirestore(doc))
              .toList();
        });
  }

  // ==========================================================
  // REAL-TIME CONVERSATION
  // ==========================================================

  Stream<List<Map<String, dynamic>>> ticketMessages(String ticketId) {
    return _firestore
        .collection(collectionName)
        .doc(ticketId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        });
  }

  // ==========================================================
  // SEND REPLY: OWNER OR ADMIN
  // ==========================================================

  Future<void> sendReply({
    required String ticketId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String message,
  }) async {
    final text = message.trim();

    if (text.isEmpty) {
      throw ArgumentError('Reply message cannot be empty.');
    }

    final ticketRef = _firestore.collection(collectionName).doc(ticketId);

    final ticketSnapshot = await ticketRef.get();

    if (!ticketSnapshot.exists) {
      throw Exception('Support ticket not found.');
    }

    final ticket = ticketSnapshot.data()!;

    final ownerId = ticket['userId']?.toString() ?? '';
    final adminId = ticket['adminId']?.toString() ?? '';
    final role = senderRole.toLowerCase();

    // Verify the sender against the ticket participants.
    if (role == 'owner' && senderId != ownerId) {
      throw Exception('You cannot reply to this ticket.');
    }

    if (role == 'admin' && senderId != adminId) {
      throw Exception('You cannot reply to this ticket.');
    }

    if (role != 'owner' && role != 'admin') {
      throw Exception('Invalid support ticket role.');
    }

    final status = (ticket['status'] ?? 'open').toString().toLowerCase();

    if (status == 'closed' || status == 'resolved') {
      throw Exception('This ticket is closed. Reopen it before replying.');
    }

    final batch = _firestore.batch();

    final messageRef = ticketRef.collection('messages').doc();

    batch.set(messageRef, {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': role,
      'message': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final nextStatus = role == 'admin' ? 'waiting_for_owner' : 'in_progress';

    batch.update(ticketRef, {
      'status': nextStatus,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': text,
      'lastMessageBy': role,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    // Notify the other participant.
    final recipientId = role == 'owner' ? adminId : ownerId;
    final recipientRole = role == 'owner' ? 'admin' : 'owner';

    final notificationRef = _firestore.collection(notificationCollection).doc();

    batch.set(notificationRef, {
      'userId': recipientId,
      'role': recipientRole,
      'title': role == 'owner'
          ? 'Owner Replied to Support Ticket'
          : 'Admin Replied to Your Ticket',
      'body': '$senderName: $text',
      'type': 'support_ticket_reply',
      'isRead': false,
      'relatedId': ticketId,
      'relatedType': 'supportTicket',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ==========================================================
  // UPDATE STATUS
  // ==========================================================

  Future<void> updateStatus({
    required String ticketId,
    required String status,
    required String adminId,
  }) async {
    const allowedStatuses = {
      'open',
      'in_progress',
      'waiting_for_owner',
      'resolved',
      'closed',
    };

    if (!allowedStatuses.contains(status)) {
      throw ArgumentError('Invalid support ticket status.');
    }

    final ticketRef = _firestore.collection(collectionName).doc(ticketId);

    final snapshot = await ticketRef.get();

    if (!snapshot.exists) {
      throw Exception('Support ticket not found.');
    }

    final ticket = snapshot.data()!;

    if (ticket['adminId']?.toString() != adminId) {
      throw Exception('You cannot update this ticket.');
    }

    final batch = _firestore.batch();

    batch.update(ticketRef, {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final ownerId = ticket['userId']?.toString() ?? '';
    final notificationRef = _firestore.collection(notificationCollection).doc();

    batch.set(notificationRef, {
      'userId': ownerId,
      'role': 'owner',
      'title': 'Support Ticket Updated',
      'body': 'Your ticket status changed to ${status.replaceAll('_', ' ')}.',
      'type': 'support_ticket_status',
      'isRead': false,
      'relatedId': ticketId,
      'relatedType': 'supportTicket',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
