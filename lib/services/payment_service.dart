// import 'dart:convert';
// import 'dart:developer';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:crypto/crypto.dart';
//
// import '../models/payment_model.dart';
// import '../services/bakong_service.dart';
// import 'owner_notification_service.dart';
//
// class PaymentService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   final OwnerNotificationService _ownerNotificationService =
//       OwnerNotificationService();
//
//   // ============================================================
//   // BAKONG CONFIGURATION
//   // ============================================================
//
//   static const String bakongAccount = 'ly_minhchou@bkrt';
//
//   // ============================================================
//   // TEST PAYMENT CONFIGURATION
//   // ============================================================
//   //
//   // REAL BOOKING:
//   //
//   // Example:
//   //     1.48 USD
//   //
//   // TEST PAYMENT:
//   //
//   //     100 KHR
//   //
//   // During testing, these values are intentionally different.
//   //
//   // ============================================================
//
//   static const double testPaymentAmount = 100.0;
//
//   static const String testPaymentCurrency = 'KHR';
//
//   // ============================================================
//   // GENERATE MD5 FROM KHQR
//   // ============================================================
//
//   String generateKhqrMd5(String khqr) {
//     if (khqr.trim().isEmpty) {
//       throw Exception('KHQR string is empty.');
//     }
//
//     return md5.convert(utf8.encode(khqr)).toString();
//   }
//
//   // ============================================================
//   // VERIFY BAKONG PAYMENT
//   // ============================================================
//
//   Future<Map<String, dynamic>> verifyBakongPayment({
//     required String md5,
//     required double expectedAmount,
//     required String expectedCurrency,
//   }) async {
//     try {
//       log('');
//       log('==============================================');
//       log('VERIFYING BAKONG PAYMENT');
//       log('==============================================');
//
//       log('Expected Amount: $expectedAmount');
//       log('Expected Currency: $expectedCurrency');
//       log('MD5: $md5');
//
//       // ==========================================================
//       // CHECK BAKONG
//       // ==========================================================
//
//       final result = await BakongService.checkTransactionByMd5(md5);
//
//       log('Bakong paid: ${result.paid}');
//
//       log('Bakong message: ${result.responseMessage}');
//
//       // ==========================================================
//       // PAYMENT NOT FOUND
//       // ==========================================================
//
//       // ==========================================================
//       // BAKONG RATE LIMIT
//       // ==========================================================
//
//       if (result.rateLimited) {
//         return {
//           'success': false,
//           'paid': false,
//           'rateLimited': true,
//           'message':
//               'Bakong daily request limit has been exceeded. '
//               'Please try again tomorrow.',
//           'data': result.data,
//         };
//       }
//
//       // ==========================================================
//       // UNAUTHORIZED
//       // ==========================================================
//
//       if (result.unauthorized) {
//         return {
//           'success': false,
//           'paid': false,
//           'unauthorized': true,
//           'message':
//               'Bakong authentication failed. '
//               'Please check the Bakong API token.',
//           'data': result.data,
//         };
//       }
//
//       // ==========================================================
//       // PAYMENT NOT FOUND YET
//       // ==========================================================
//
//       if (!result.paid) {
//         return {
//           'success': false,
//           'paid': false,
//           'message':
//               result.responseMessage ?? 'Payment has not been found yet.',
//           'data': result.data,
//         };
//       }
//
//       // ==========================================================
//       // TRANSACTION DATA
//       // ==========================================================
//
//       final data = result.data;
//
//       if (data == null) {
//         return {
//           'success': false,
//           'paid': false,
//           'message': 'Bakong returned no transaction data.',
//         };
//       }
//
//       // ==========================================================
//       // AMOUNT
//       // ==========================================================
//
//       final transactionAmount = _parseDouble(data['amount']);
//
//       // ==========================================================
//       // CURRENCY
//       // ==========================================================
//
//       final currency = data['currency']?.toString().trim().toUpperCase() ?? '';
//
//       log('');
//       log('==============================================');
//       log('BAKONG TRANSACTION DATA');
//       log('==============================================');
//
//       log('Amount: $transactionAmount');
//
//       log('Currency: $currency');
//
//       // ==========================================================
//       // VERIFY CURRENCY
//       // ==========================================================
//
//       if (currency != expectedCurrency.trim().toUpperCase()) {
//         return {
//           'success': false,
//           'paid': false,
//           'message':
//               'Payment currency does not match. '
//               'Expected $expectedCurrency '
//               'but received $currency.',
//           'data': data,
//         };
//       }
//
//       // ==========================================================
//       // VERIFY AMOUNT
//       // ==========================================================
//
//       if ((transactionAmount - expectedAmount).abs() > 0.001) {
//         return {
//           'success': false,
//           'paid': false,
//           'message':
//               'Payment amount does not match. '
//               'Expected '
//               '$expectedAmount $expectedCurrency, '
//               'but Bakong returned '
//               '$transactionAmount $currency.',
//           'data': data,
//         };
//       }
//
//       log('');
//       log('==============================================');
//       log('AMOUNT VERIFIED');
//       log('==============================================');
//
//       log('$transactionAmount $currency');
//
//       // ==========================================================
//       // VERIFY RECEIVER
//       // ==========================================================
//
//       final receiver = data['toAccountId']?.toString().trim() ?? '';
//
//       log('Receiver: $receiver');
//
//       if (receiver.isNotEmpty &&
//           receiver.toLowerCase() != bakongAccount.toLowerCase()) {
//         return {
//           'success': false,
//           'paid': false,
//           'message':
//               'Payment receiver does not match. '
//               'Expected $bakongAccount '
//               'but received $receiver.',
//           'data': data,
//         };
//       }
//
//       log('');
//       log('==============================================');
//       log('BAKONG PAYMENT VERIFIED');
//       log('==============================================');
//
//       return {
//         'success': true,
//         'paid': true,
//         'message': result.responseMessage ?? 'Payment verified successfully.',
//         'data': data,
//       };
//     } catch (e, stackTrace) {
//       log('BAKONG VERIFY ERROR', error: e, stackTrace: stackTrace);
//
//       rethrow;
//     }
//   }
//
//   // ============================================================
//   // COMPLETE PAYMENT
//   // ============================================================
//
//   Future<Map<String, dynamic>> completePayment({
//     required String bookingId,
//     required String paymentMethod,
//     required String khqrMd5,
//   }) async {
//     try {
//       log('');
//       log('==============================================');
//       log('COMPLETE PAYMENT - TEST MODE');
//       log('==============================================');
//
//       // ==========================================================
//       // TEST PAYMENT
//       // ==========================================================
//
//       const double paymentAmount = testPaymentAmount;
//
//       const String paymentCurrency = testPaymentCurrency;
//
//       log(
//         'TEST PAYMENT: '
//         '$paymentAmount $paymentCurrency',
//       );
//
//       // ==========================================================
//       // GET BOOKING
//       // ==========================================================
//
//       final bookingRef = _firestore.collection('bookings').doc(bookingId);
//
//       final bookingDoc = await bookingRef.get();
//
//       if (!bookingDoc.exists) {
//         throw Exception('Booking not found: $bookingId');
//       }
//
//       final bookingData = bookingDoc.data() as Map<String, dynamic>;
//
//       // ==========================================================
//       // BOOKING INFORMATION
//       // ==========================================================
//
//       final renterId = bookingData['renterId']?.toString() ?? '';
//
//       final ownerId = bookingData['ownerId']?.toString() ?? '';
//
//       final houseId = bookingData['houseId']?.toString() ?? '';
//
//       // ==========================================================
//       // REAL BOOKING AMOUNT
//       // ==========================================================
//       //
//       // Example:
//       //
//       //     1.48 USD
//       //
//       // This is stored separately.
//       //
//       // It is NOT used to verify the 100 KHR
//       // test payment.
//       //
//       // ==========================================================
//
//       final bookingAmount = _parseDouble(bookingData['totalAmount']);
//
//       // ==========================================================
//       // VALIDATION
//       // ==========================================================
//
//       if (renterId.isEmpty) {
//         throw Exception('Booking does not contain renterId.');
//       }
//
//       if (ownerId.isEmpty) {
//         throw Exception('Booking does not contain ownerId.');
//       }
//
//       if (houseId.isEmpty) {
//         throw Exception('Booking does not contain houseId.');
//       }
//
//       if (bookingAmount <= 0) {
//         throw Exception('Invalid booking amount: $bookingAmount');
//       }
//
//       // ==========================================================
//       // CHECK BOOKING PAYMENT STATUS
//       // ==========================================================
//
//       final paymentStatus = bookingData['paymentStatus']
//           ?.toString()
//           .toLowerCase();
//
//       if (paymentStatus == 'paid') {
//         throw Exception('This booking has already been paid.');
//       }
//
//       log('');
//       log(
//         'REAL BOOKING AMOUNT: '
//         '$bookingAmount USD',
//       );
//
//       log(
//         'TEST PAYMENT: '
//         '$paymentAmount $paymentCurrency',
//       );
//
//       // ==========================================================
//       // VERIFY BAKONG
//       // ==========================================================
//
//       final verification = await verifyBakongPayment(
//         md5: khqrMd5,
//
//         // Test amount = 100 KHR
//         expectedAmount: paymentAmount,
//
//         // Test currency = KHR
//         expectedCurrency: paymentCurrency,
//       );
//
//       // ==========================================================
//       // CHECK VERIFICATION
//       // ==========================================================
//
//       if (verification['success'] != true) {
//         throw Exception(
//           verification['message'] ?? 'Bakong payment has not been verified.',
//         );
//       }
//
//       // ==========================================================
//       // TRANSACTION DATA
//       // ==========================================================
//
//       final transactionData = verification['data'] as Map<String, dynamic>?;
//
//       if (transactionData == null) {
//         throw Exception('Bakong transaction data is missing.');
//       }
//
//       // ==========================================================
//       // TRANSACTION INFORMATION
//       // ==========================================================
//
//       final transactionHash = transactionData['hash']?.toString();
//
//       final fromAccount = transactionData['fromAccountId']?.toString();
//
//       final toAccount = transactionData['toAccountId']?.toString();
//
//       final currency =
//           transactionData['currency']?.toString().trim().toUpperCase() ??
//           paymentCurrency;
//
//       final transactionAmount = _parseDouble(transactionData['amount']);
//
//       log('');
//       log('==============================================');
//       log('BAKONG TRANSACTION');
//       log('==============================================');
//
//       log('Amount: $transactionAmount');
//
//       log('Currency: $currency');
//
//       log('Hash: $transactionHash');
//
//       log('From: $fromAccount');
//
//       log('To: $toAccount');
//
//       // ==========================================================
//       // FINAL CURRENCY CHECK
//       // ==========================================================
//
//       if (currency != paymentCurrency) {
//         throw Exception(
//           'Payment currency does not match. '
//           'Expected $paymentCurrency, '
//           'but Bakong returned $currency.',
//         );
//       }
//
//       // ==========================================================
//       // FINAL AMOUNT CHECK
//       // ==========================================================
//
//       if ((transactionAmount - paymentAmount).abs() > 0.001) {
//         throw Exception(
//           'Payment amount does not match. '
//           'Expected '
//           '$paymentAmount $paymentCurrency, '
//           'but Bakong returned '
//           '$transactionAmount $currency.',
//         );
//       }
//
//       // ==========================================================
//       // VERIFY RECEIVER
//       // ==========================================================
//
//       if (toAccount != null &&
//           toAccount.isNotEmpty &&
//           toAccount.toLowerCase() != bakongAccount.toLowerCase()) {
//         throw Exception(
//           'Payment receiver does not match. '
//           'Expected $bakongAccount, '
//           'but received $toAccount.',
//         );
//       }
//
//       log('');
//       log('==============================================');
//       log('TEST PAYMENT VERIFIED');
//       log('==============================================');
//
//       // ==========================================================
//       // PREVENT DUPLICATE TRANSACTION
//       // ==========================================================
//
//       if (transactionHash != null && transactionHash.isNotEmpty) {
//         final duplicate = await _firestore
//             .collection('payments')
//             .where('bakongTransactionHash', isEqualTo: transactionHash)
//             .limit(1)
//             .get();
//
//         if (duplicate.docs.isNotEmpty) {
//           throw Exception('This Bakong transaction has already been recorded.');
//         }
//       }
//
//       // ==========================================================
//       // CREATE PAYMENT
//       // ==========================================================
//
//       final paymentRef = _firestore.collection('payments').doc();
//
//       final paymentId = paymentRef.id;
//
//       final paymentData = {
//         // --------------------------------------------------------
//         // PAYMENT
//         // --------------------------------------------------------
//         'paymentId': paymentId,
//
//         'bookingId': bookingId,
//
//         'renterId': renterId,
//
//         'ownerId': ownerId,
//
//         'houseId': houseId,
//
//         // --------------------------------------------------------
//         // REAL BOOKING
//         // --------------------------------------------------------
//         'bookingAmount': bookingAmount,
//
//         'bookingCurrency': 'USD',
//
//         // --------------------------------------------------------
//         // ACTUAL TEST PAYMENT
//         // --------------------------------------------------------
//         'amount': transactionAmount,
//
//         'expectedAmount': paymentAmount,
//
//         'currency': currency,
//
//         // --------------------------------------------------------
//         // PAYMENT METHOD
//         // --------------------------------------------------------
//         'paymentMethod': paymentMethod,
//
//         // --------------------------------------------------------
//         // BAKONG
//         // --------------------------------------------------------
//         'bakongAccount': bakongAccount,
//
//         'bakongMd5': khqrMd5,
//
//         'bakongTransactionHash': transactionHash,
//
//         'fromAccountId': fromAccount,
//
//         'toAccountId': toAccount,
//
//         // --------------------------------------------------------
//         // STATUS
//         // --------------------------------------------------------
//         'status': 'Paid',
//
//         // --------------------------------------------------------
//         // TEST MODE
//         // --------------------------------------------------------
//         'testPayment': true,
//
//         // --------------------------------------------------------
//         // TIMESTAMP
//         // --------------------------------------------------------
//         'createdAt': FieldValue.serverTimestamp(),
//
//         'paidAt': FieldValue.serverTimestamp(),
//       };
//
//       // ==========================================================
//       // FIRESTORE BATCH
//       // ==========================================================
//
//       final batch = _firestore.batch();
//
//       // Save payment
//       batch.set(paymentRef, paymentData);
//
//       // Update booking
//       batch.update(bookingRef, {
//         'paymentId': paymentId,
//
//         'paymentMethod': paymentMethod,
//
//         'paymentStatus': 'Paid',
//
//         // Real booking amount
//         'bookingAmount': bookingAmount,
//
//         'bookingCurrency': 'USD',
//
//         // Test payment
//         'paidAmount': transactionAmount,
//
//         'paidCurrency': currency,
//
//         'testPayment': true,
//
//         'updatedAt': FieldValue.serverTimestamp(),
//
//         'paidAt': FieldValue.serverTimestamp(),
//       });
//
//       // ==========================================================
//       // COMMIT
//       // ==========================================================
//
//       await batch.commit();
//
//       log('');
//       log('==============================================');
//       log('PAYMENT SAVED TO FIRESTORE');
//       log('==============================================');
//
//       log('Payment ID: $paymentId');
//
//       log('Booking ID: $bookingId');
//
//       log(
//         'Real Booking: '
//         '$bookingAmount USD',
//       );
//
//       log(
//         'Test Paid: '
//         '$transactionAmount $currency',
//       );
//
//       // owner Notifaction
//       try {
//         await _ownerNotificationService.createNotification(
//           userId: ownerId,
//           role: 'owner',
//
//           title: 'Payment Received',
//
//           body:
//               'Test payment of '
//               '${transactionAmount.toStringAsFixed(0)} $currency '
//               'has been received for booking $bookingId.',
//
//           type: 'rental_payment',
//
//           relatedId: paymentId,
//           relatedType: 'payment',
//
//           bookingId: bookingId,
//           houseId: houseId,
//           paymentId: paymentId,
//
//           amount: transactionAmount,
//           currency: currency,
//         );
//
//         log('');
//         log('==============================================');
//         log('OWNER PAYMENT NOTIFICATION CREATED');
//         log('==============================================');
//
//         log('Owner ID: $ownerId');
//
//         log('Payment ID: $paymentId');
//
//         log('Booking ID: $bookingId');
//
//         log('Amount: $transactionAmount $currency');
//       } catch (notificationError, notificationStackTrace) {
//         // ----------------------------------------------------------
//         // DO NOT FAIL PAYMENT IF NOTIFICATION FAILS
//         // ----------------------------------------------------------
//
//         log(
//           'OWNER NOTIFICATION ERROR',
//           error: notificationError,
//           stackTrace: notificationStackTrace,
//         );
//       }
//
//       // ==========================================================
//       // RETURN
//       // ==========================================================
//
//       return {
//         'success': true,
//
//         'paymentId': paymentId,
//
//         'transactionHash': transactionHash,
//
//         'amount': transactionAmount,
//
//         'currency': currency,
//
//         'bookingAmount': bookingAmount,
//
//         'bookingCurrency': 'USD',
//
//         'testPayment': true,
//
//         'data': transactionData,
//       };
//     } catch (e, stackTrace) {
//       log('COMPLETE PAYMENT ERROR', error: e, stackTrace: stackTrace);
//
//       rethrow;
//     }
//   }
//
//   // ============================================================
//   // RENTER PAYMENTS
//   // ============================================================
//
//   Stream<List<PaymentModel>> getRenterPayments(String renterId) {
//     return _firestore
//         .collection('payments')
//         .where('renterId', isEqualTo: renterId)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map(
//           (snapshot) => snapshot.docs
//               .map((doc) => PaymentModel.fromMap(doc.id, doc.data()))
//               .toList(),
//         );
//   }
//
//   // ============================================================
//   // GET PAYMENT BY ID
//   // ============================================================
//
//   Future<PaymentModel?> getPaymentById(String paymentId) async {
//     try {
//       final doc = await _firestore.collection('payments').doc(paymentId).get();
//
//       if (!doc.exists) {
//         return null;
//       }
//
//       return PaymentModel.fromMap(doc.id, doc.data()!);
//     } catch (e) {
//       log('GET PAYMENT ERROR: $e');
//
//       return null;
//     }
//   }
//
//   // ============================================================
//   // PARSE DOUBLE
//   // ============================================================
//
//   double _parseDouble(dynamic value) {
//     if (value == null) {
//       return 0.0;
//     }
//
//     if (value is num) {
//       return value.toDouble();
//     }
//
//     return double.tryParse(value.toString()) ?? 0.0;
//   }
// }

import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../models/payment_model.dart';
import '../services/bakong_service.dart';
import 'owner_notification_service.dart';

class PaymentService {
  PaymentService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final OwnerNotificationService _ownerNotificationService =
      OwnerNotificationService();

  // ============================================================
  // BAKONG CONFIGURATION
  // ============================================================

  static const String bakongAccount = 'thearith_panha@bkrt';

  // ============================================================
  // TEST PAYMENT CONFIGURATION
  // ============================================================
  //
  // IMPORTANT:
  //
  // This version is TEST MODE.
  //
  // Actual booking amount may be:
  //
  //     1.48 USD
  //
  // But the Bakong test QR/payment is:
  //
  //     100 KHR
  //
  // ============================================================

  static const double testPaymentAmount = 100.0;

  static const String testPaymentCurrency = 'KHR';

  // ============================================================
  // GENERATE KHQR MD5
  // ============================================================

  String generateKhqrMd5(String khqr) {
    final value = khqr.trim();

    if (value.isEmpty) {
      throw ArgumentError('KHQR string cannot be empty.');
    }

    return md5.convert(utf8.encode(value)).toString();
  }

  // ============================================================
  // VERIFY BAKONG PAYMENT
  // ============================================================
  //
  // IMPORTANT:
  //
  // This method ONLY verifies the Bakong transaction.
  //
  // It does NOT:
  //
  // - create Firestore payment
  // - update booking
  // - create owner notification
  //
  // completePayment() handles those operations.
  //
  // ============================================================

  Future<Map<String, dynamic>> verifyBakongPayment({
    required String md5,
    required double expectedAmount,
    required String expectedCurrency,
  }) async {
    final md5Value = md5.trim();
    final expectedCurrencyValue = expectedCurrency.trim().toUpperCase();

    if (md5Value.isEmpty) {
      throw ArgumentError('Bakong MD5 cannot be empty.');
    }

    if (expectedAmount <= 0) {
      throw ArgumentError('Expected payment amount must be greater than 0.');
    }

    if (expectedCurrencyValue.isEmpty) {
      throw ArgumentError('Expected payment currency cannot be empty.');
    }

    try {
      log('');
      log('==============================================');
      log('VERIFY BAKONG PAYMENT');
      log('==============================================');

      log('MD5: $md5Value');
      log('Expected Amount: $expectedAmount');
      log('Expected Currency: $expectedCurrencyValue');

      // ==========================================================
      // CALL BAKONG
      // ==========================================================

      final result = await BakongService.checkTransactionByMd5(md5Value);

      log('HTTP Status: ${result.httpStatus}');
      log('Response Code: ${result.responseCode}');
      log('Message: ${result.responseMessage}');
      log('Paid: ${result.paid}');

      // ==========================================================
      // RATE LIMIT
      // ==========================================================

      if (result.rateLimited) {
        return {
          'success': false,
          'paid': false,
          'rateLimited': true,
          'message':
              'Bakong daily request limit has been exceeded. '
              'Please try again later.',
          'data': result.data,
        };
      }

      // ==========================================================
      // UNAUTHORIZED
      // ==========================================================

      if (result.unauthorized) {
        return {
          'success': false,
          'paid': false,
          'unauthorized': true,
          'message':
              'Bakong authentication failed. '
              'Please check the Bakong API token.',
          'data': result.data,
        };
      }

      // ==========================================================
      // BAKONG DID NOT CONFIRM TRANSACTION
      // ==========================================================

      if (!result.paid) {
        return {
          'success': false,
          'paid': false,
          'message':
              result.responseMessage ?? 'Payment has not been found yet.',
          'data': result.data,
        };
      }

      // ==========================================================
      // TRANSACTION DATA
      // ==========================================================

      final data = result.data;

      if (data == null) {
        return {
          'success': false,
          'paid': false,
          'message': 'Bakong returned no transaction data.',
        };
      }

      // ==========================================================
      // TRANSACTION HASH
      // ==========================================================

      final transactionHash = data['hash']?.toString().trim() ?? '';

      if (transactionHash.isEmpty) {
        return {
          'success': false,
          'paid': false,
          'message': 'Bakong transaction hash is missing.',
          'data': data,
        };
      }

      // ==========================================================
      // AMOUNT
      // ==========================================================

      final transactionAmount = _parseDouble(data['amount']);

      if (transactionAmount <= 0) {
        return {
          'success': false,
          'paid': false,
          'message': 'Bakong returned an invalid transaction amount.',
          'data': data,
        };
      }

      // ==========================================================
      // CURRENCY
      // ==========================================================

      final currency = data['currency']?.toString().trim().toUpperCase() ?? '';

      if (currency.isEmpty) {
        return {
          'success': false,
          'paid': false,
          'message': 'Bakong transaction currency is missing.',
          'data': data,
        };
      }

      // ==========================================================
      // RECEIVER
      // ==========================================================

      final receiver = data['toAccountId']?.toString().trim() ?? '';

      if (receiver.isEmpty) {
        return {
          'success': false,
          'paid': false,
          'message': 'Bakong transaction receiver is missing.',
          'data': data,
        };
      }

      // ==========================================================
      // SENDER
      // ==========================================================

      final sender = data['fromAccountId']?.toString().trim() ?? '';

      // ==========================================================
      // LOG TRANSACTION
      // ==========================================================

      log('');
      log('==============================================');
      log('BAKONG TRANSACTION');
      log('==============================================');
      log('Hash: $transactionHash');
      log('Amount: $transactionAmount');
      log('Currency: $currency');
      log('From: $sender');
      log('To: $receiver');

      // ==========================================================
      // VERIFY CURRENCY
      // ==========================================================

      if (currency != expectedCurrencyValue) {
        return {
          'success': false,
          'paid': false,
          'message':
              'Payment currency does not match. '
              'Expected $expectedCurrencyValue '
              'but received $currency.',
          'data': data,
        };
      }

      // ==========================================================
      // VERIFY AMOUNT
      // ==========================================================

      if ((transactionAmount - expectedAmount).abs() > 0.001) {
        return {
          'success': false,
          'paid': false,
          'message':
              'Payment amount does not match. '
              'Expected '
              '$expectedAmount $expectedCurrencyValue '
              'but received '
              '$transactionAmount $currency.',
          'data': data,
        };
      }

      // ==========================================================
      // VERIFY RECEIVER
      // ==========================================================

      if (receiver.toLowerCase() != bakongAccount.toLowerCase()) {
        return {
          'success': false,
          'paid': false,
          'message':
              'Payment receiver does not match. '
              'Expected $bakongAccount '
              'but received $receiver.',
          'data': data,
        };
      }

      // ==========================================================
      // VERIFIED
      // ==========================================================

      log('');
      log('==============================================');
      log('BAKONG PAYMENT VERIFIED');
      log('==============================================');

      return {
        'success': true,
        'paid': true,
        'message': result.responseMessage ?? 'Payment verified successfully.',
        'data': data,
        'transactionHash': transactionHash,
        'amount': transactionAmount,
        'currency': currency,
        'fromAccountId': sender,
        'toAccountId': receiver,
      };
    } catch (e, stackTrace) {
      log('VERIFY BAKONG PAYMENT ERROR', error: e, stackTrace: stackTrace);

      rethrow;
    }
  }

  // ============================================================
  // COMPLETE PAYMENT
  // ============================================================
  //
  // This is the ONLY method that should be called by the UI
  // to complete a Bakong payment.
  //
  // Flow:
  //
  // 1. Load booking
  // 2. Check booking payment status
  // 3. Verify Bakong transaction ONCE
  // 4. Use transaction hash as payment document ID
  // 5. Firestore transaction
  // 6. Create payment
  // 7. Update booking
  // 8. Return payment information
  //
  // ============================================================

  Future<Map<String, dynamic>> completePayment({
    required String bookingId,
    required String paymentMethod,
    required String khqrMd5,
  }) async {
    final cleanBookingId = bookingId.trim();
    final cleanPaymentMethod = paymentMethod.trim();
    final cleanMd5 = khqrMd5.trim();

    if (cleanBookingId.isEmpty) {
      throw ArgumentError('Booking ID cannot be empty.');
    }

    if (cleanPaymentMethod.isEmpty) {
      throw ArgumentError('Payment method cannot be empty.');
    }

    if (cleanMd5.isEmpty) {
      throw ArgumentError('KHQR MD5 cannot be empty.');
    }

    try {
      log('');
      log('==============================================');
      log('COMPLETE BAKONG TEST PAYMENT');
      log('==============================================');

      log('Booking ID: $cleanBookingId');
      log('Payment Method: $cleanPaymentMethod');
      log('MD5: $cleanMd5');
      log(
        'Test Payment: '
        '$testPaymentAmount $testPaymentCurrency',
      );

      // ==========================================================
      // BOOKING REFERENCE
      // ==========================================================

      final bookingRef = _firestore.collection('bookings').doc(cleanBookingId);

      // ==========================================================
      // GET BOOKING
      // ==========================================================

      final bookingDoc = await bookingRef.get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found: $cleanBookingId');
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;

      // ==========================================================
      // BOOKING INFORMATION
      // ==========================================================

      final renterId = bookingData['renterId']?.toString().trim() ?? '';

      final ownerId = bookingData['ownerId']?.toString().trim() ?? '';

      final houseId = bookingData['houseId']?.toString().trim() ?? '';

      final bookingAmount = _parseDouble(bookingData['totalAmount']);

      final currentPaymentStatus =
          bookingData['paymentStatus']?.toString().trim().toLowerCase() ?? '';

      // ==========================================================
      // VALIDATE BOOKING
      // ==========================================================

      if (renterId.isEmpty) {
        throw Exception('Booking does not contain renterId.');
      }

      if (ownerId.isEmpty) {
        throw Exception('Booking does not contain ownerId.');
      }

      if (houseId.isEmpty) {
        throw Exception('Booking does not contain houseId.');
      }

      if (bookingAmount <= 0) {
        throw Exception('Invalid booking amount: $bookingAmount');
      }

      // ==========================================================
      // ALREADY PAID
      // ==========================================================

      if (currentPaymentStatus == 'paid') {
        throw Exception('This booking has already been paid.');
      }

      log(
        'Real Booking Amount: '
        '$bookingAmount USD',
      );

      // ==========================================================
      // VERIFY BAKONG
      // ==========================================================
      //
      // ONLY ONE Bakong verification happens here.
      //
      // The UI must NOT call verifyBakongPayment()
      // separately before calling this method.
      //
      // ==========================================================

      final verification = await verifyBakongPayment(
        md5: cleanMd5,
        expectedAmount: testPaymentAmount,
        expectedCurrency: testPaymentCurrency,
      );

      if (verification['rateLimited'] == true) {
        throw Exception(
          verification['message'] ?? 'Bakong daily request limit exceeded.',
        );
      }

      if (verification['unauthorized'] == true) {
        throw Exception(
          verification['message'] ?? 'Bakong authentication failed.',
        );
      }

      if (verification['success'] != true) {
        throw Exception(
          verification['message'] ?? 'Bakong payment has not been verified.',
        );
      }

      // ==========================================================
      // VERIFIED TRANSACTION
      // ==========================================================

      final transactionData = verification['data'] as Map<String, dynamic>?;

      if (transactionData == null) {
        throw Exception('Bakong transaction data is missing.');
      }

      final transactionHash = transactionData['hash']?.toString().trim() ?? '';

      final fromAccount =
          transactionData['fromAccountId']?.toString().trim() ?? '';

      final toAccount = transactionData['toAccountId']?.toString().trim() ?? '';

      final transactionAmount = _parseDouble(transactionData['amount']);

      final currency =
          transactionData['currency']?.toString().trim().toUpperCase() ??
          testPaymentCurrency;

      if (transactionHash.isEmpty) {
        throw Exception('Bakong transaction hash is missing.');
      }

      // ==========================================================
      // PAYMENT DOCUMENT
      // ==========================================================
      //
      // IMPORTANT:
      //
      // Instead of:
      //
      // collection('payments').doc()
      //
      // we use the Bakong transaction hash.
      //
      // Therefore:
      //
      // payments/{transactionHash}
      //
      // The same Bakong transaction cannot create
      // another payment document.
      //
      // ==========================================================

      final paymentRef = _firestore.collection('payments').doc(transactionHash);

      final paymentId = paymentRef.id;

      // ==========================================================
      // FIRESTORE TRANSACTION
      // ==========================================================
      //
      // This protects against two simultaneous requests:
      //
      // Request A -> Check payment
      // Request B -> Check payment
      //
      // Both cannot create the same payment.
      //
      // ==========================================================

      await _firestore.runTransaction((transaction) async {
        // --------------------------------------------------------
        // READ PAYMENT FIRST
        // --------------------------------------------------------

        final existingPayment = await transaction.get(paymentRef);

        if (existingPayment.exists) {
          throw Exception('This Bakong transaction has already been recorded.');
        }

        // --------------------------------------------------------
        // READ BOOKING AGAIN INSIDE TRANSACTION
        // --------------------------------------------------------

        final latestBooking = await transaction.get(bookingRef);

        if (!latestBooking.exists) {
          throw Exception('Booking no longer exists.');
        }

        final latestBookingData = latestBooking.data() as Map<String, dynamic>;

        final latestPaymentStatus =
            latestBookingData['paymentStatus']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

        // --------------------------------------------------------
        // CHECK BOOKING PAYMENT STATUS AGAIN
        // --------------------------------------------------------

        if (latestPaymentStatus == 'paid') {
          throw Exception('This booking has already been paid.');
        }

        // --------------------------------------------------------
        // PAYMENT DATA
        // --------------------------------------------------------

        final paymentData = {
          'paymentId': paymentId,
          'bookingId': cleanBookingId,
          'renterId': renterId,
          'ownerId': ownerId,
          'houseId': houseId,

          // ------------------------------------------------------
          // REAL BOOKING AMOUNT
          // ------------------------------------------------------
          'bookingAmount': bookingAmount,
          'bookingCurrency': 'USD',

          // ------------------------------------------------------
          // ACTUAL TEST PAYMENT
          // ------------------------------------------------------
          'amount': transactionAmount,
          'expectedAmount': testPaymentAmount,
          'currency': currency,

          // ------------------------------------------------------
          // PAYMENT
          // ------------------------------------------------------
          'paymentMethod': cleanPaymentMethod,
          'status': 'Paid',

          // ------------------------------------------------------
          // BAKONG
          // ------------------------------------------------------
          'bakongAccount': bakongAccount,
          'bakongMd5': cleanMd5,
          'bakongTransactionHash': transactionHash,

          'fromAccountId': fromAccount,
          'toAccountId': toAccount,

          // ------------------------------------------------------
          // TEST MODE
          // ------------------------------------------------------
          'testPayment': true,

          // ------------------------------------------------------
          // TIMESTAMP
          // ------------------------------------------------------
          'createdAt': FieldValue.serverTimestamp(),
          'paidAt': FieldValue.serverTimestamp(),
        };

        // --------------------------------------------------------
        // CREATE PAYMENT
        // --------------------------------------------------------

        transaction.set(paymentRef, paymentData);

        // --------------------------------------------------------
        // UPDATE BOOKING
        // --------------------------------------------------------

        transaction.update(bookingRef, {
          'paymentId': paymentId,
          'paymentMethod': cleanPaymentMethod,

          'paymentStatus': 'Paid',

          // Real booking amount
          'bookingAmount': bookingAmount,
          'bookingCurrency': 'USD',

          // Actual test payment
          'paidAmount': transactionAmount,
          'paidCurrency': currency,

          'testPayment': true,

          'paidAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // ==========================================================
      // FIRESTORE SUCCESS
      // ==========================================================

      log('');
      log('==============================================');
      log('PAYMENT SAVED SUCCESSFULLY');
      log('==============================================');

      log('Payment ID: $paymentId');
      log('Booking ID: $cleanBookingId');
      log(
        'Paid: '
        '$transactionAmount $currency',
      );
      log(
        'Booking: '
        '$bookingAmount USD',
      );
      log('Transaction Hash: $transactionHash');

      // ==========================================================
      // OWNER NOTIFICATION
      // ==========================================================
      //
      // Notification failure must NOT make the payment fail.
      //
      // ==========================================================

      try {
        await _ownerNotificationService.createNotification(
          userId: ownerId,
          role: 'owner',
          title: 'Payment Received',
          body:
              'Test payment of '
              '${transactionAmount.toStringAsFixed(0)} '
              '$currency '
              'has been received for booking '
              '$cleanBookingId.',
          type: 'rental_payment',
          relatedId: paymentId,
          relatedType: 'payment',
          bookingId: cleanBookingId,
          houseId: houseId,
          paymentId: paymentId,
          amount: transactionAmount,
          currency: currency,
        );

        log('OWNER PAYMENT NOTIFICATION CREATED');
      } catch (e, stackTrace) {
        log('OWNER NOTIFICATION ERROR', error: e, stackTrace: stackTrace);
      }

      // ==========================================================
      // RETURN
      // ==========================================================

      return {
        'success': true,
        'paymentId': paymentId,
        'bookingId': cleanBookingId,

        'transactionHash': transactionHash,

        'amount': transactionAmount,
        'currency': currency,

        'bookingAmount': bookingAmount,
        'bookingCurrency': 'USD',

        'testPayment': true,

        'fromAccountId': fromAccount,
        'toAccountId': toAccount,

        'data': transactionData,
      };
    } catch (e, stackTrace) {
      log('COMPLETE PAYMENT ERROR', error: e, stackTrace: stackTrace);

      rethrow;
    }
  }

  // ============================================================
  // RENTER PAYMENTS
  // ============================================================

  Stream<List<PaymentModel>> getRenterPayments(String renterId) {
    return _firestore
        .collection('payments')
        .where('renterId', isEqualTo: renterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // ============================================================
  // GET PAYMENT BY ID
  // ============================================================

  Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data();

      if (data == null) {
        return null;
      }

      return PaymentModel.fromMap(doc.id, data);
    } catch (e) {
      log('GET PAYMENT ERROR: $e');
      return null;
    }
  }

  // ============================================================
  // PARSE DOUBLE
  // ============================================================

  double _parseDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0.0;
  }
}
