
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';

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
      final currency = data['currency']?.toString().trim().toUpperCase() ?? '';

      if (currency.isEmpty) {
        return {
          'success': false,
          'paid': false,
          'message': 'Bakong transaction currency is missing.',
          'data': data,
        };
      }

      final receiver = data['toAccountId']?.toString().trim() ?? '';

      if (receiver.isEmpty) {
        return {
          'success': false,
          'paid': false,
          'message': 'Bakong transaction receiver is missing.',
          'data': data,
        };
      }

      final sender = data['fromAccountId']?.toString().trim() ?? '';

      log('');
      log('==============================================');
      log('BAKONG TRANSACTION');
      log('==============================================');
      log('Hash: $transactionHash');
      log('Amount: $transactionAmount');
      log('Currency: $currency');
      log('From: $sender');
      log('To: $receiver');

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

      final bookingRef = _firestore.collection('bookings').doc(cleanBookingId);

      final bookingDoc = await bookingRef.get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found: $cleanBookingId');
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;

      final renterId = bookingData['renterId']?.toString().trim() ?? '';

      final ownerId = bookingData['ownerId']?.toString().trim() ?? '';

      final houseId = bookingData['houseId']?.toString().trim() ?? '';

      final bookingAmount = _parseDouble(bookingData['totalAmount']);

      final currentPaymentStatus = bookingData['paymentStatus']?.toString().trim().toLowerCase() ?? '';

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
          body: 'Payment has been received successfully.',
          type: 'rental_payment',
          relatedId: paymentId,
          relatedType: 'payment',
          bookingId: cleanBookingId,
          houseId: houseId,
          paymentId: paymentId,
          amount: bookingAmount,
          currency: 'USD',
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



  Future<Map<String, dynamic>?> getPaymentByBookingId(
      String bookingId,
      ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint(
          '[PAYMENT] No payment found for booking: $bookingId',
        );
        return null;
      }

      final data = snapshot.docs.first.data();

      debugPrint(
        '[PAYMENT] bookingAmount = ${data['bookingAmount']}',
      );

      debugPrint(
        '[PAYMENT] bookingCurrency = ${data['bookingCurrency']}',
      );

      return data;
    } catch (e) {
      debugPrint(
        '[PAYMENT] Get payment error: $e',
      );

      return null;
    }
  }


}
