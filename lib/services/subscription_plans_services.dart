import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/subscription_plan_model.dart';
import '../models/subscription_model.dart';

class SubscriptionPlansService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== SUBSCRIPTION PLANS ====================

  Stream<List<SubscriptionPlanModel>> subscriptionPlans() {
    return _firestore
        .collection('subscription_plans')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final plans = snapshot.docs.map((doc) {
        return SubscriptionPlanModel.fromFirestore(
          doc.data(),
          doc.id,
        );
      }).toList();

      // Sort plans using displayOrder from Firestore.
      plans.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      return plans;
    });
  }

  // ==================== PENDING SUBSCRIPTION ====================

  Future<bool> hasPendingSubscription(String ownerId) async {
    final snapshot = await _firestore
        .collection('subscriptions')
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ==================== CREATE SUBSCRIPTION ====================

  Future<void> createSubscription({
    required String ownerId,
    required String planId,
    required String planName,
    required double amount,
    required String paymentMethod,
    required String paymentReference,
  }) async {
    await _firestore.collection('subscriptions').add({
      'ownerId': ownerId,
      'planId': planId,
      'planName': planName,
      'amount': amount,
      'currency': 'USD',
      'status': 'pending',
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'startDate': null,
      'endDate': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}