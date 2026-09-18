import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _subscriptionCollection =>
      _firestore.collection('subscriptions');

  // IMPORTANT:
  // Your houses/properties are stored in "properties".
  CollectionReference<Map<String, dynamic>> get _propertyCollection =>
      _firestore.collection('properties');

  CollectionReference<Map<String, dynamic>> get _planCollection =>
      _firestore.collection('subscription_plans');

  // ==========================================================
  // GET ACTIVE SUBSCRIPTION
  // ==========================================================

  Future<Map<String, dynamic>?> getActiveSubscription(String ownerId) async {
    try {
      final snapshot = await _subscriptionCollection
          .where('ownerId', isEqualTo: ownerId)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No subscriptions found for owner: $ownerId');
        return null;
      }

      final now = DateTime.now();

      final activeSubscriptions =
          <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final status = data['status']?.toString().toLowerCase().trim();

        if (status != 'active' && status != 'approved') {
          continue;
        }

        DateTime? startDate;
        DateTime? endDate;

        final startValue = data['startDate'];
        final endValue = data['endDate'];

        if (startValue is Timestamp) {
          startDate = startValue.toDate();
        } else if (startValue is DateTime) {
          startDate = startValue;
        }

        if (endValue is Timestamp) {
          endDate = endValue.toDate();
        } else if (endValue is DateTime) {
          endDate = endValue;
        }

        // If the subscription has not started yet, ignore it.
        if (startDate != null && now.isBefore(startDate)) {
          continue;
        }

        // If the subscription has expired, ignore it.
        if (endDate != null && now.isAfter(endDate)) {
          continue;
        }

        activeSubscriptions.add(doc);
      }

      if (activeSubscriptions.isEmpty) {
        print('No active subscription found for owner: $ownerId');
        return null;
      }

      // Sort newest subscription first.
      activeSubscriptions.sort((a, b) {
        final aValue = a.data()['createdAt'];
        final bValue = b.data()['createdAt'];

        DateTime? aDate;
        DateTime? bDate;

        if (aValue is Timestamp) {
          aDate = aValue.toDate();
        } else if (aValue is DateTime) {
          aDate = aValue;
        }

        if (bValue is Timestamp) {
          bDate = bValue.toDate();
        } else if (bValue is DateTime) {
          bDate = bValue;
        }

        if (aDate == null && bDate == null) {
          return 0;
        }

        if (aDate == null) {
          return 1;
        }

        if (bDate == null) {
          return -1;
        }

        return bDate.compareTo(aDate);
      });

      final doc = activeSubscriptions.first;
      final data = doc.data();

      print('========== ACTIVE SUBSCRIPTION ==========');
      print('Subscription ID: ${doc.id}');
      print('Owner ID: ${data['ownerId']}');
      print('Status: ${data['status']}');
      print('Plan ID: ${data['planId']}');
      print('Plan Name: ${data['planName']}');
      print('Start Date: ${data['startDate']}');
      print('End Date: ${data['endDate']}');
      print('=========================================');

      return {...data, 'subscriptionId': doc.id};
    } catch (e) {
      print('ERROR getActiveSubscription: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getPlan(String planId) async {
    try {
      // First try the planId as the Firestore document ID.
      final directDoc = await _planCollection.doc(planId).get();

      if (directDoc.exists && directDoc.data() != null) {
        print('Plan found by document ID: $planId');

        return {...directDoc.data()!, 'documentId': directDoc.id};
      }

      // Your database stores the plan ID in the "id" field.
      final querySnapshot = await _planCollection
          .where('id', isEqualTo: planId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;

        print('Plan found by id field: $planId -> document: ${doc.id}');

        return {...doc.data(), 'documentId': doc.id};
      }

      print('Plan NOT FOUND: $planId');

      return null;
    } catch (e) {
      print('ERROR getPlan($planId): $e');
      rethrow;
    }
  }

  // ==========================================================
  // GET OWNER PROPERTY COUNT
  // ==========================================================

  Future<int> getOwnerPropertyCount(String ownerId) async {
    try {
      final snapshot = await _propertyCollection
          .where('ownerId', isEqualTo: ownerId)
          .get();

      print('========== PROPERTY COUNT ==========');
      print('Owner ID: $ownerId');
      print('Property Collection: properties');
      print('Property Count: ${snapshot.docs.length}');
      print('====================================');

      return snapshot.docs.length;
    } catch (e) {
      print('ERROR getOwnerPropertyCount: $e');
      rethrow;
    }
  }

  // ==========================================================
  // GET PROPERTY LIMIT
  // ==========================================================

  Future<int?> getLimitForPlan(String planId) async {
    final plan = await getPlan(planId);

    if (plan == null) {
      return null;
    }

    final value = plan['propertyLimit'];

    if (value is num) {
      return value.toInt();
    }

    return null;
  }

  // ==========================================================
  // CHECK WHETHER OWNER CAN ADD PROPERTY
  // ==========================================================

  Future<Map<String, dynamic>> canAddProperty(String ownerId) async {
    try {
      print('');
      print('========================================');
      print('CHECKING SUBSCRIPTION');
      print('Owner ID: $ownerId');
      print('========================================');

      // --------------------------------------------------------
      // 1. Get active subscription
      // --------------------------------------------------------

      final subscription = await getActiveSubscription(ownerId);

      if (subscription == null) {
        final result = {
          'canAdd': false,
          'reason':
              'You do not have an active subscription. Please choose a subscription plan first.',
          'currentCount': 0,
          'limit': 0,
          'planId': null,
          'planName': null,
        };

        _printResult(ownerId, result);

        return result;
      }

      // --------------------------------------------------------
      // 2. Get plan ID from subscription
      // --------------------------------------------------------

      final planId = subscription['planId']?.toString().trim();

      if (planId == null || planId.isEmpty) {
        final result = {
          'canAdd': false,
          'reason': 'Your subscription does not have a valid plan.',
          'currentCount': 0,
          'limit': 0,
          'planId': null,
          'planName': subscription['planName']?.toString(),
        };

        _printResult(ownerId, result);

        return result;
      }

      // --------------------------------------------------------
      // 3. Find plan
      // --------------------------------------------------------

      final plan = await getPlan(planId);

      if (plan == null) {
        final result = {
          'canAdd': false,
          'reason': 'The subscription plan "$planId" could not be found.',
          'currentCount': 0,
          'limit': 0,
          'planId': planId,
          'planName': subscription['planName']?.toString(),
        };

        _printResult(ownerId, result);

        return result;
      }

      // --------------------------------------------------------
      // 4. Check plan status
      // --------------------------------------------------------

      final planStatus = plan['status']?.toString().toLowerCase().trim();

      if (planStatus != 'active') {
        final result = {
          'canAdd': false,
          'reason': 'Your subscription plan is not active.',
          'currentCount': 0,
          'limit': 0,
          'planId': planId,
          'planName':
              plan['name']?.toString() ??
              plan['planName']?.toString() ??
              subscription['planName']?.toString(),
        };

        _printResult(ownerId, result);

        return result;
      }

      // --------------------------------------------------------
      // 5. Get property limit
      // --------------------------------------------------------

      final propertyLimitValue = plan['propertyLimit'];

      if (propertyLimitValue == null) {
        final result = {
          'canAdd': false,
          'reason':
              'The plan "${plan['name'] ?? planId}" does not have a property limit configured.',
          'currentCount': 0,
          'limit': 0,
          'planId': planId,
          'planName':
              plan['name']?.toString() ??
              plan['planName']?.toString() ??
              subscription['planName']?.toString(),
        };

        _printResult(ownerId, result);

        return result;
      }

      if (propertyLimitValue is! num) {
        final result = {
          'canAdd': false,
          'reason': 'The property limit for this plan is invalid.',
          'currentCount': 0,
          'limit': 0,
          'planId': planId,
          'planName':
              plan['name']?.toString() ??
              plan['planName']?.toString() ??
              subscription['planName']?.toString(),
        };

        _printResult(ownerId, result);

        return result;
      }

      final propertyLimit = propertyLimitValue.toInt();

      // --------------------------------------------------------
      // 6. Get current property count
      // --------------------------------------------------------

      final currentCount = await getOwnerPropertyCount(ownerId);

      // --------------------------------------------------------
      // 7. Unlimited plan
      // --------------------------------------------------------

      if (propertyLimit >= 999999) {
        final result = {
          'canAdd': true,
          'reason': 'Unlimited properties allowed.',
          'currentCount': currentCount,
          'limit': propertyLimit,
          'planId': planId,
          'planName':
              plan['name']?.toString() ??
              plan['planName']?.toString() ??
              subscription['planName']?.toString(),
        };

        _printResult(ownerId, result);

        return result;
      }

      // --------------------------------------------------------
      // 8. Invalid limit
      // --------------------------------------------------------

      if (propertyLimit <= 0) {
        final result = {
          'canAdd': false,
          'reason': 'This subscription plan does not allow properties.',
          'currentCount': currentCount,
          'limit': propertyLimit,
          'planId': planId,
          'planName':
              plan['name']?.toString() ??
              plan['planName']?.toString() ??
              subscription['planName']?.toString(),
        };

        _printResult(ownerId, result);

        return result;
      }

      // --------------------------------------------------------
      // 9. Check property limit
      // --------------------------------------------------------

      if (currentCount < propertyLimit) {
        final result = {
          'canAdd': true,
          'reason': 'You can add another property.',
          'currentCount': currentCount,
          'limit': propertyLimit,
          'planId': planId,
          'planName':
              plan['name']?.toString() ??
              plan['planName']?.toString() ??
              subscription['planName']?.toString(),
        };

        _printResult(ownerId, result);

        return result;
      }

      // --------------------------------------------------------
      // 10. Limit reached
      // --------------------------------------------------------

      final result = {
        'canAdd': false,
        'reason':
            'You have reached the ${plan['name'] ?? planId} plan limit of $propertyLimit properties.',
        'currentCount': currentCount,
        'limit': propertyLimit,
        'planId': planId,
        'planName':
            plan['name']?.toString() ??
            plan['planName']?.toString() ??
            subscription['planName']?.toString(),
      };

      _printResult(ownerId, result);

      return result;
    } catch (e) {
      print('ERROR canAddProperty: $e');

      final result = {
        'canAdd': false,
        'reason': 'Unable to check your subscription. Please try again.',
        'currentCount': 0,
        'limit': 0,
        'planId': null,
        'planName': null,
        'error': e.toString(),
      };

      _printResult(ownerId, result);

      return result;
    }
  }

  // ==========================================================
  // DEBUG RESULT
  // ==========================================================

  void _printResult(String ownerId, Map<String, dynamic> result) {
    print('========== SUBSCRIPTION CHECK ==========');
    print('Owner ID: $ownerId');
    print('Can Add: ${result['canAdd']}');
    print('Reason: ${result['reason']}');
    print('Current Count: ${result['currentCount']}');
    print('Limit: ${result['limit']}');
    print('Plan ID: ${result['planId']}');
    print('Plan Name: ${result['planName']}');
    print('========================================');
  }

  // ==========================================================
  // CREATE SUBSCRIPTION
  // ==========================================================

  Future<String> createSubscription({
    required String ownerId,
    required String planId,
    required String planName,
    required double amount,
    String currency = 'USD',
    required String paymentMethod,
    String paymentReference = '',
  }) async {
    final doc = _subscriptionCollection.doc();

    final subscription = SubscriptionModel(
      subscriptionId: doc.id,
      ownerId: ownerId,
      planId: planId,
      planName: planName,
      amount: amount,
      currency: currency,
      status: 'pending',
      paymentMethod: paymentMethod,
      paymentReference: paymentReference,
      startDate: null,
      endDate: null,
      createdAt: DateTime.now(),
      updatedAt: null,
      approvedBy: '',
      approvedAt: null,
    );

    await doc.set(subscription.toFirestore());

    return doc.id;
  }

  // ==========================================================
  // GET OWNER SUBSCRIPTIONS
  // ==========================================================

  Stream<List<SubscriptionModel>> ownerSubscriptions(String ownerId) {
    return _subscriptionCollection
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
          final subscriptions = snapshot.docs
              .map((doc) => SubscriptionModel.fromFirestore(doc))
              .toList();

          subscriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return subscriptions;
        });
  }

  // ==========================================================
  // GET PENDING SUBSCRIPTIONS
  // ==========================================================

  Stream<List<SubscriptionModel>> pendingSubscriptions() {
    return _subscriptionCollection
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final subscriptions = snapshot.docs
              .map((doc) => SubscriptionModel.fromFirestore(doc))
              .toList();

          subscriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return subscriptions;
        });
  }

  // ==========================================================
  // CHECK PENDING SUBSCRIPTION
  // ==========================================================

  Future<bool> hasPendingSubscription(String ownerId) async {
    final snapshot = await _subscriptionCollection
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ==========================================================
  // APPROVE SUBSCRIPTION
  // ==========================================================

  Future<void> approveSubscription({
    required String subscriptionId,
    required String adminId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _subscriptionCollection.doc(subscriptionId).update({
      'status': 'active',
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'approvedBy': adminId,
      'approvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // REJECT SUBSCRIPTION
  // ==========================================================

  Future<void> rejectSubscription({required String subscriptionId}) async {
    await _subscriptionCollection.doc(subscriptionId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
