import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/support_ticket_model.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String collectionName = 'supportTickets';

  // ==========================================================
  // CREATE TICKET
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
    final doc =
    _firestore.collection('supportTickets').doc();

    final ticket = SupportTicketModel(
      ticketId: doc.id,
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

    await doc.set(ticket.toFirestore());

    return doc.id;
  }

  // ==========================================================
  // OWNER TICKETS
  // ==========================================================

  Stream<List<SupportTicketModel>> userTickets(
      String userId,
      ) {
    return _firestore
        .collection('supportTickets')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(
            (doc) => SupportTicketModel.fromFirestore(doc),
      )
          .toList(),
    );
  }

  // ==========================================================
  // ADMIN TICKETS
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
  // UPDATE STATUS
  // ==========================================================

  Future<void> updateStatus({
    required String ticketId,
    required String status,
  }) async {
    await _firestore.collection(collectionName).doc(ticketId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
