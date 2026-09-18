import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicketModel {
  final String ticketId;

  final String userId;
  final String userName;
  final String userEmail;
  final String userRole;

  final String adminId;

  final String subject;
  final String message;

  final String status;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const SupportTicketModel({
    required this.ticketId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.adminId,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'ticketId': ticketId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userRole': userRole,
      'adminId': adminId,
      'subject': subject,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt':
      updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory SupportTicketModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};

    return SupportTicketModel(
      ticketId: data['ticketId'] ?? doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userRole: data['userRole'] ?? '',
      adminId: data['adminId'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      status: data['status'] ?? 'open',
      createdAt:
      (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
      (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}