// import 'dart:async';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:khqr_sdk/khqr_sdk.dart';
// import 'package:qr_flutter/qr_flutter.dart';
//
// import '../../../models/booking_model.dart';
// import '../../../models/property_model.dart';
// import '../../../models/user_model.dart';
// import '../../../services/payment_service.dart';
// import '../../../services/telegram_service.dart';
//
// import 'package:khqr_sdk/khqr_sdk.dart';
// import 'package:qr_flutter/qr_flutter.dart';
//
// class RenterPaymentScreen extends StatefulWidget {
//   final BookingModel booking;
//
//   const RenterPaymentScreen({super.key, required this.booking});
//
//   @override
//   State<RenterPaymentScreen> createState() => _RenterPaymentScreenState();
// }
//
// class _RenterPaymentScreenState extends State<RenterPaymentScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   final PaymentService paymentService = PaymentService();
//
//   Property? property;
//   UserModel? owner;
//   UserModel? renter;
//
//   bool isLoading = true;
//   bool _isGeneratingQr = true;
//   bool _isPaying = false;
//
//   bool _isTermsAgreed = false;
//
//   String? errorMessage;
//
//   String? _khqrString;
//   String? _khqrMd5;
//
//   DateTime? _qrExpiresAt;
//
//   Timer? _countdownTimer;
//
//   Duration _remainingTime = const Duration(minutes: 15);
//
//   // ============================================================
//   // COLORS
//   // ============================================================
//
//   static const Color _primary = Color(0xFF4F46E5);
//
//   static const Color _primaryDark = Color(0xFF3730A3);
//
//   static const Color _bg = Color(0xFFF8FAFC);
//
//   static const Color _card = Colors.white;
//
//   static const Color _textPrimary = Color(0xFF0F172A);
//
//   static const Color _textSecondary = Color(0xFF64748B);
//
//   static const Color _border = Color(0xFFE2E8F0);
//
//   Timer? _paymentCheckTimer;
//
//   bool _isCheckingPayment = false;
//
//   bool _paymentConfirmed = false;
//
//   bool _paymentRateLimited = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _loadPaymentData();
//   }
//
//   @override
//   void dispose() {
//     _countdownTimer?.cancel();
//
//     super.dispose();
//   }
//
//   // ============================================================
//   // LOAD PAYMENT DATA
//   // ============================================================
//
//   void _startAutomaticPaymentCheck() {
//     _paymentCheckTimer?.cancel();
//
//     // Check immediately once.
//     _checkPaymentAutomatically();
//
//     // Then check every 10 seconds.
//     _paymentCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
//       _checkPaymentAutomatically();
//     });
//   }
//
//   Future<void> _checkPaymentAutomatically() async {
//     if (!mounted) return;
//
//     // Prevent overlapping API requests.
//     if (_isCheckingPayment) return;
//
//     // Already paid.
//     if (_paymentConfirmed) return;
//
//     // Stop when QR expired.
//     if (_isQrExpired) {
//       _paymentCheckTimer?.cancel();
//       return;
//     }
//
//     // No MD5.
//     if (_khqrMd5 == null || _khqrMd5!.trim().isEmpty) {
//       return;
//     }
//
//     // User must agree to payment terms.
//     if (!_isTermsAgreed) {
//       return;
//     }
//
//     _isCheckingPayment = true;
//
//     try {
//       final bookingId = widget.booking.bookingId;
//
//       if (bookingId == null || bookingId.trim().isEmpty) {
//         throw Exception('Booking ID is missing.');
//       }
//
//       print('');
//       print('====================================');
//       print('AUTOMATIC BAKONG PAYMENT CHECK');
//       print('====================================');
//       print('Booking: $bookingId');
//       print('MD5: $_khqrMd5');
//
//       final verification = await paymentService.verifyBakongPayment(
//         md5: _khqrMd5!,
//         expectedAmount: PaymentService.testPaymentAmount,
//         expectedCurrency: PaymentService.testPaymentCurrency,
//       );
//
//       if (!mounted) return;
//
//       // ==========================================================
//       // RATE LIMIT
//       // ==========================================================
//
//       if (verification['rateLimited'] == true) {
//         _paymentCheckTimer?.cancel();
//
//         setState(() {
//           _paymentRateLimited = true;
//         });
//
//         print('BAKONG DAILY LIMIT EXCEEDED');
//
//         return;
//       }
//
//       // ==========================================================
//       // PAYMENT NOT CONFIRMED
//       // ==========================================================
//
//       if (verification['success'] != true) {
//         print('BAKONG PAYMENT NOT CONFIRMED');
//
//         print('Message: ${verification['message']}');
//
//         return;
//       }
//
//       // ==========================================================
//       // PAYMENT CONFIRMED
//       // ==========================================================
//
//       print('');
//       print('====================================');
//       print('BAKONG PAYMENT CONFIRMED');
//       print('====================================');
//
//       _paymentCheckTimer?.cancel();
//
//       _paymentConfirmed = true;
//
//       setState(() {
//         _isPaying = true;
//       });
//
//       // ==========================================================
//       // SAVE PAYMENT
//       // ==========================================================
//
//       await paymentService.completePayment(
//         bookingId: bookingId,
//         paymentMethod: 'Bakong',
//         khqrMd5: _khqrMd5!,
//       );
//
//       if (!mounted) return;
//
//       // ==========================================================
//       // TELEGRAM
//       // ==========================================================
//
//       try {
//         await _notifyPaymentSuccess();
//       } catch (e) {
//         print('Telegram notification failed: $e');
//       }
//
//       if (!mounted) return;
//
//       setState(() {
//         _isPaying = false;
//       });
//
//       // ==========================================================
//       // SUCCESS
//       // ==========================================================
//
//       _showPaymentSuccessDialog();
//     } catch (e, stackTrace) {
//       print('');
//       print('====================================');
//       print('AUTOMATIC PAYMENT CHECK ERROR');
//       print('====================================');
//       print(e);
//       print(stackTrace);
//
//       // IMPORTANT:
//       // Do not show an error dialog for every polling attempt.
//       // Before payment, "not found" is normal.
//
//       if (!mounted) return;
//
//       // If rate limit occurs, stop polling.
//       if (e.toString().toLowerCase().contains('daily request limit')) {
//         _paymentCheckTimer?.cancel();
//
//         setState(() {
//           _paymentRateLimited = true;
//         });
//       }
//     } finally {
//       _isCheckingPayment = false;
//     }
//   }
//
//   Future<void> _loadPaymentData() async {
//     try {
//       final propertyDoc = await _firestore
//           .collection('properties')
//           .doc(widget.booking.houseId)
//           .get();
//
//       if (propertyDoc.exists && propertyDoc.data() != null) {
//         property = Property.fromMap(propertyDoc.data()!, propertyDoc.id);
//       }
//
//       final ownerDoc = await _firestore
//           .collection('users')
//           .doc(widget.booking.ownerId)
//           .get();
//
//       if (ownerDoc.exists && ownerDoc.data() != null) {
//         owner = UserModel.fromMap(ownerDoc.data()!);
//       }
//
//       final renterDoc = await _firestore
//           .collection('users')
//           .doc(widget.booking.renterId)
//           .get();
//
//       if (renterDoc.exists && renterDoc.data() != null) {
//         renter = UserModel.fromMap(renterDoc.data()!);
//       }
//
//       if (!mounted) return;
//
//       setState(() {
//         isLoading = false;
//       });
//
//       // Generate the real KHQR.
//       await _generateBakongQr();
//     } catch (e) {
//       debugPrint('LOAD PAYMENT DATA ERROR: $e');
//
//       if (!mounted) return;
//
//       setState(() {
//         isLoading = false;
//         _isGeneratingQr = false;
//         errorMessage = e.toString();
//       });
//     }
//   }
//
//   Future<void> _generateBakongQr() async {
//     try {
//       if (!mounted) return;
//
//       setState(() {
//         _isGeneratingQr = true;
//         errorMessage = null;
//       });
//
//       // ============================================================
//       // TEST PAYMENT AMOUNT
//       // ============================================================
//       //
//       // Your real booking amount can be:
//       //
//       // widget.booking.totalAmount
//       //
//       // But for testing Bakong payment, we only charge:
//       //
//       // 100 Riel
//       //
//       const double testPaymentAmount = 100;
//
//       if (testPaymentAmount <= 0) {
//         throw Exception('Invalid test payment amount.');
//       }
//
//       // ============================================================
//       // QR EXPIRATION
//       // ============================================================
//
//       final expireAt = DateTime.now().add(const Duration(minutes: 2));
//
//       // ============================================================
//       // GENERATE KHQR
//       // ============================================================
//
//       final individualInfo = IndividualInfo(
//         bakongAccountId: PaymentService.bakongAccount,
//
//         merchantName: 'RentEase',
//
//         // KHQR account information.
//         //
//         // If your khqr_sdk version allows this field to be omitted,
//         // you can leave it out.
//         accountInformation: PaymentService.bakongAccount,
//
//         // IMPORTANT:
//         // 100 Riel, NOT booking.totalAmount
//         amount: testPaymentAmount,
//
//         // IMPORTANT:
//         // Riel, NOT USD
//         currency: KhqrCurrency.khr,
//
//         expirationTimestamp: expireAt.millisecondsSinceEpoch,
//       );
//
//       final result = KhqrSdk.generateIndividual(individualInfo);
//
//       // ============================================================
//       // CHECK GENERATION RESULT
//       // ============================================================
//
//       if (!result.isSuccess) {
//         throw Exception(result.status.message);
//       }
//
//       if (result.data == null) {
//         throw Exception('Bakong did not return KHQR data.');
//       }
//
//       // ============================================================
//       // GET QR STRING
//       // ============================================================
//
//       final qr = result.data!.qr;
//
//       if (qr.isEmpty) {
//         throw Exception('Generated KHQR is empty.');
//       }
//
//       // ============================================================
//       // GENERATE MD5
//       // ============================================================
//       //
//       // khqr_sdk does not provide generatedData.md5Hash.
//       //
//       // We calculate MD5 from the KHQR string ourselves.
//       //
//
//       final md5Hash = paymentService.generateKhqrMd5(qr);
//
//       if (md5Hash.isEmpty) {
//         throw Exception('Failed to generate KHQR MD5.');
//       }
//
//       // ============================================================
//       // SAVE QR DATA
//       // ============================================================
//
//       if (!mounted) return;
//
//       setState(() {
//         _khqrString = qr;
//         _khqrMd5 = md5Hash;
//
//         _qrExpiresAt = expireAt;
//
//         _remainingTime = const Duration(minutes: 2);
//
//         _isGeneratingQr = false;
//       });
//
//       // ============================================================
//       // START COUNTDOWN
//       // ============================================================
//
//       _startCountdown();
//
//       // ============================================================
//       // DEBUG
//       // ============================================================
//
//       debugPrint('====================================');
//       debugPrint('REAL BAKONG KHQR GENERATED');
//       debugPrint('====================================');
//       debugPrint('QR LENGTH: ${qr.length}');
//       debugPrint('MD5: $md5Hash');
//       debugPrint('TEST PAYMENT: 100 KHR');
//       debugPrint('REAL BOOKING AMOUNT: ${widget.booking.totalAmount}');
//       debugPrint('ACCOUNT: ${PaymentService.bakongAccount}');
//       debugPrint('====================================');
//     } catch (e) {
//       debugPrint('GENERATE KHQR ERROR: $e');
//
//       if (!mounted) return;
//
//       setState(() {
//         _isGeneratingQr = false;
//         errorMessage = 'Unable to generate Bakong QR.\n$e';
//       });
//     }
//   }
//
//   // ============================================================
//   // QR COUNTDOWN
//   // ============================================================
//
//   void _startCountdown() {
//     _countdownTimer?.cancel();
//
//     _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (!mounted) return;
//
//       if (_qrExpiresAt == null) {
//         return;
//       }
//
//       final difference = _qrExpiresAt!.difference(DateTime.now());
//
//       if (difference.isNegative || difference.inSeconds <= 0) {
//         _countdownTimer?.cancel();
//
//         setState(() {
//           _remainingTime = Duration.zero;
//         });
//
//         return;
//       }
//
//       setState(() {
//         _remainingTime = difference;
//       });
//     });
//   }
//
//   // ============================================================
//   // CHECK PAYMENT
//   // ============================================================
//
//   Future<void> _onPayNow() async {
//     if (_isPaying) return;
//
//     if (!_isTermsAgreed) {
//       _showErrorDialog(
//         title: 'Payment Terms',
//         message:
//             'Please agree to the payment terms and rental agreement before continuing.',
//       );
//
//       return;
//     }
//
//     if (_khqrMd5 == null || _khqrMd5!.isEmpty) {
//       _showErrorDialog(
//         title: 'QR Not Ready',
//         message: 'Bakong QR is not ready. Please generate the QR again.',
//       );
//
//       return;
//     }
//
//     if (_isQrExpired) {
//       _showErrorDialog(
//         title: 'QR Expired',
//         message: 'This Bakong QR has expired. Please generate a new QR code.',
//       );
//
//       return;
//     }
//
//     final bookingId = widget.booking.bookingId;
//
//     if (bookingId == null || bookingId.trim().isEmpty) {
//       _showErrorDialog(
//         title: 'Invalid Booking',
//         message: 'Booking ID is missing.',
//       );
//
//       return;
//     }
//
//     setState(() {
//       _isPaying = true;
//     });
//
//     _showCheckingPaymentDialog();
//
//     try {
//       debugPrint('');
//       debugPrint('====================================');
//       debugPrint('CHECKING REAL BAKONG PAYMENT');
//       debugPrint('====================================');
//
//       debugPrint('Booking: $bookingId');
//
//       debugPrint('Amount: ${widget.booking.totalAmount}');
//
//       debugPrint('MD5: $_khqrMd5');
//
//       // --------------------------------------------------------
//       // VERIFY WITH BAKONG
//       // --------------------------------------------------------
//
//       await paymentService.completePayment(
//         bookingId: bookingId,
//         paymentMethod: 'Bakong',
//         khqrMd5: _khqrMd5!,
//       );
//
//       debugPrint('BAKONG PAYMENT CONFIRMED');
//
//       // Close checking dialog.
//       if (mounted) {
//         Navigator.of(context, rootNavigator: true).pop();
//       }
//
//       // --------------------------------------------------------
//       // TELEGRAM
//       // --------------------------------------------------------
//
//       await _notifyPaymentSuccess();
//
//       if (!mounted) return;
//
//       setState(() {
//         _isPaying = false;
//       });
//
//       // --------------------------------------------------------
//       // SUCCESS DIALOG
//       // --------------------------------------------------------
//
//       _showPaymentSuccessDialog();
//     } catch (e) {
//       debugPrint('BAKONG PAYMENT NOT CONFIRMED');
//
//       debugPrint(e.toString());
//
//       if (!mounted) return;
//
//       // Close checking dialog.
//       Navigator.of(context, rootNavigator: true).pop();
//
//       setState(() {
//         _isPaying = false;
//       });
//
//       _showPaymentFailedDialog(e);
//     }
//   }
//
//   // ============================================================
//   // TELEGRAM
//   // ============================================================
//
//   Future<void> _notifyPaymentSuccess() async {
//     /*
//      * Replace this with the owner's real Telegram chat ID
//      * or retrieve it from Firestore.
//      */
//     const ownerChatId = '987654321';
//
//     final message =
//         '''
// 💰 ការទូទាត់ប្រាក់បានជោគជ័យ
//
// 📋 លេខ Booking:
// ${widget.booking.bookingId}
//
// 👤 អ្នកជួល
// ឈ្មោះ: ${renter?.fullName ?? 'មិនមាន'}
// ទូរស័ព្ទ: ${renter?.phone ?? 'មិនមាន'}
//
// 🏠 ផ្ទះ/បន្ទប់
// ${property?.title ?? 'មិនមាន'}
//
// 💵 ចំនួនទឹកប្រាក់
// \$${widget.booking.totalAmount.toStringAsFixed(2)}
//
// 💳 វិធីទូទាត់
// Bakong
//
// ស្ថានភាព:
// បានទូទាត់រួចរាល់ ✅
// ''';
//
//     try {
//       final success = await TelegramService.sendMessage(
//         chatId: ownerChatId,
//         message: message,
//       );
//
//       if (success) {
//         debugPrint('Telegram notification sent.');
//       } else {
//         debugPrint('Telegram notification failed.');
//       }
//     } catch (e) {
//       /*
//        * Do not fail the payment because
//        * Telegram failed.
//        */
//       debugPrint('Telegram error: $e');
//     }
//   }
//
//   // ============================================================
//   // QR EXPIRED
//   // ============================================================
//
//   bool get _isQrExpired {
//     if (_qrExpiresAt == null) {
//       return true;
//     }
//
//     return DateTime.now().isAfter(_qrExpiresAt!);
//   }
//
//   // ============================================================
//   // TIME FORMAT
//   // ============================================================
//
//   String get _remainingTimeText {
//     final minutes = _remainingTime.inMinutes
//         .remainder(60)
//         .toString()
//         .padLeft(2, '0');
//
//     final seconds = _remainingTime.inSeconds
//         .remainder(60)
//         .toString()
//         .padLeft(2, '0');
//
//     return '$minutes:$seconds';
//   }
//
//   // ============================================================
//   // REGENERATE QR
//   // ============================================================
//
//   Future<void> _regenerateQr() async {
//     await _generateBakongQr();
//   }
//
//   // ============================================================
//   // CHECKING DIALOG
//   // ============================================================
//
//   void _showCheckingPaymentDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) {
//         return const PopScope(
//           canPop: false,
//           child: AlertDialog(
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 SizedBox(height: 8),
//                 CircularProgressIndicator(color: _primary),
//                 SizedBox(height: 24),
//                 Text(
//                   'Checking Payment',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w700,
//                     color: _textPrimary,
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Please wait while we verify your Bakong transaction.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: _textSecondary,
//                     height: 1.4,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   // ============================================================
//   // SUCCESS DIALOG
//   // ============================================================
//
//   void _showPaymentSuccessDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(24),
//           ),
//           contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 80,
//                 height: 80,
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.12),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.check_rounded,
//                   size: 50,
//                   color: Colors.green,
//                 ),
//               ),
//
//               const SizedBox(height: 20),
//
//               const Text(
//                 'Payment Successful',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.w800,
//                   color: _textPrimary,
//                 ),
//               ),
//
//               const SizedBox(height: 10),
//
//               const Text(
//                 'Your Bakong payment has been successfully verified and recorded.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: _textSecondary,
//                   height: 1.5,
//                 ),
//               ),
//
//               const SizedBox(height: 24),
//
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: _bg,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: _border),
//                 ),
//                 child: Column(
//                   children: [
//                     const Text(
//                       'Amount Paid',
//                       style: TextStyle(fontSize: 12, color: _textSecondary),
//                     ),
//
//                     const SizedBox(height: 6),
//
//                     Text(
//                       '\$${widget.booking.totalAmount.toStringAsFixed(2)}',
//                       style: const TextStyle(
//                         fontSize: 30,
//                         fontWeight: FontWeight.w800,
//                         color: _primary,
//                       ),
//                     ),
//
//                     const SizedBox(height: 2),
//
//                     const Text(
//                       'USD',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: _textSecondary,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               const SizedBox(height: 18),
//
//               _successInfoRow('Booking ID', widget.booking.bookingId ?? 'N/A'),
//
//               _successInfoRow('Payment Method', 'Bakong'),
//
//               _successInfoRow('Status', 'Paid', valueColor: Colors.green),
//             ],
//           ),
//           actionsPadding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
//           actions: [
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.of(dialogContext).pop();
//
//                   Navigator.of(context).pop();
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: _primary,
//                   foregroundColor: Colors.white,
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                 ),
//                 child: const Text(
//                   'Done',
//                   style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   // ============================================================
//   // SUCCESS INFO
//   // ============================================================
//
//   Widget _successInfoRow(String label, String value, {Color? valueColor}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(fontSize: 13, color: _textSecondary),
//           ),
//           const SizedBox(width: 12),
//           Flexible(
//             child: Text(
//               value,
//               textAlign: TextAlign.right,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w700,
//                 color: valueColor ?? _textPrimary,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ============================================================
//   // FAILED DIALOG
//   // ============================================================
//
//   void _showPaymentFailedDialog(Object error) {
//     String message = error.toString();
//
//     if (message.startsWith('Exception:')) {
//       message = message.replaceFirst('Exception:', '').trim();
//     }
//
//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(24),
//           ),
//           contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 70,
//                 height: 70,
//                 decoration: BoxDecoration(
//                   color: Colors.red.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.close_rounded,
//                   size: 42,
//                   color: Colors.red,
//                 ),
//               ),
//
//               const SizedBox(height: 18),
//
//               const Text(
//                 'Payment Not Confirmed',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.w800,
//                   color: _textPrimary,
//                 ),
//               ),
//
//               const SizedBox(height: 10),
//
//               Text(
//                 message,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 13,
//                   color: _textSecondary,
//                   height: 1.5,
//                 ),
//               ),
//
//               const SizedBox(height: 20),
//             ],
//           ),
//           actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
//           actions: [
//             SizedBox(
//               width: double.infinity,
//               height: 48,
//               child: TextButton(
//                 onPressed: () {
//                   Navigator.of(dialogContext).pop();
//                 },
//                 child: const Text(
//                   'Close',
//                   style: TextStyle(fontWeight: FontWeight.w700),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   // ============================================================
//   // ERROR DIALOG
//   // ============================================================
//
//   void _showErrorDialog({required String title, required String message}) {
//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           title: Text(
//             title,
//             style: const TextStyle(fontWeight: FontWeight.w700),
//           ),
//           content: Text(
//             message,
//             style: const TextStyle(color: _textSecondary, height: 1.5),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(dialogContext).pop();
//               },
//               child: const Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   // ============================================================
//   // SECTION TITLE
//   // ============================================================
//
//   Widget _sectionTitle(String title) {
//     return Text(
//       title,
//       style: const TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.w700,
//         color: _textPrimary,
//       ),
//     );
//   }
//
//   // ============================================================
//   // INFO ROW
//   // ============================================================
//
//   Widget _infoRow(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 36,
//             height: 36,
//             decoration: BoxDecoration(
//               color: _primary.withOpacity(0.08),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, size: 18, color: _primary),
//           ),
//
//           const SizedBox(width: 12),
//
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: _textSecondary,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//
//                 const SizedBox(height: 2),
//
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: _textPrimary,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ============================================================
//   // SUMMARY ROW
//   // ============================================================
//
//   Widget _summaryRow(String label, String value, {bool isTotal = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: isTotal ? 16 : 14,
//               fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
//               color: isTotal ? _textPrimary : _textSecondary,
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: isTotal ? 22 : 15,
//               fontWeight: FontWeight.w700,
//               color: isTotal ? _primary : _textPrimary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ============================================================
//   // META CHIP
//   // ============================================================
//
//   Widget _metaChip(String label, String value) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//         decoration: BoxDecoration(
//           color: _bg,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: _border),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label.toUpperCase(),
//               style: const TextStyle(
//                 fontSize: 10,
//                 fontWeight: FontWeight.w700,
//                 color: _textSecondary,
//                 letterSpacing: 0.6,
//               ),
//             ),
//
//             const SizedBox(height: 4),
//
//             Text(
//               value,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//                 color: _textPrimary,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ============================================================
//   // QR WIDGET
//   // ============================================================
//
//   Widget _buildBakongQr() {
//     if (_isGeneratingQr) {
//       return Container(
//         width: 250,
//         height: 250,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: _border),
//         ),
//         child: const Center(child: CircularProgressIndicator(color: _primary)),
//       );
//     }
//
//     if (_khqrString == null || _khqrString!.isEmpty) {
//       return Container(
//         width: 250,
//         height: 250,
//         decoration: BoxDecoration(
//           color: _bg,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: const Center(
//           child: Text(
//             'QR unavailable',
//             style: TextStyle(color: _textSecondary),
//           ),
//         ),
//       );
//     }
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: _border, width: 1.5),
//       ),
//       child: QrImageView(
//         data: _khqrString!,
//         version: QrVersions.auto,
//         size: 220,
//         backgroundColor: Colors.white,
//         errorCorrectionLevel: QrErrorCorrectLevel.M,
//       ),
//     );
//   }
//
//   // ============================================================
//   // BUILD
//   // ============================================================
//
//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return const Scaffold(
//         backgroundColor: _bg,
//         body: Center(child: CircularProgressIndicator(color: _primary)),
//       );
//     }
//
//     if (errorMessage != null) {
//       return Scaffold(
//         backgroundColor: _bg,
//         appBar: AppBar(
//           backgroundColor: _bg,
//           elevation: 0,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         body: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(
//                   Icons.error_outline_rounded,
//                   size: 48,
//                   color: Colors.red,
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   errorMessage!,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(color: _textSecondary),
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: _regenerateQr,
//                   child: const Text('Try Again'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }
//
//     if (property == null || owner == null || renter == null) {
//       return const Scaffold(
//         backgroundColor: _bg,
//         body: Center(child: Text('Failed to load payment data.')),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: _bg,
//
//       // ========================================================
//       // APP BAR
//       // ========================================================
//       appBar: AppBar(
//         backgroundColor: _bg,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back_ios_new_rounded,
//             size: 20,
//             color: _textPrimary,
//           ),
//           onPressed: _isPaying ? null : () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Complete Payment',
//           style: TextStyle(
//             color: _textPrimary,
//             fontSize: 18,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         centerTitle: true,
//       ),
//
//       // ========================================================
//       // BODY
//       // ========================================================
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // ==================================================
//                   // PROPERTY
//                   // ==================================================
//                   Container(
//                     decoration: BoxDecoration(
//                       color: _card,
//                       borderRadius: BorderRadius.circular(20),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.04),
//                           blurRadius: 20,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         ClipRRect(
//                           borderRadius: const BorderRadius.vertical(
//                             top: Radius.circular(20),
//                           ),
//                           child: AspectRatio(
//                             aspectRatio: 16 / 9,
//                             child: Image.network(
//                               property!.imageUrl,
//                               fit: BoxFit.cover,
//                               errorBuilder: (_, __, ___) {
//                                 return Container(
//                                   color: _border,
//                                   child: const Icon(
//                                     Icons.home_rounded,
//                                     size: 48,
//                                     color: _textSecondary,
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         ),
//
//                         Padding(
//                           padding: const EdgeInsets.all(18),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 10,
//                                   vertical: 4,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: _primary.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(20),
//                                 ),
//                                 child: Text(
//                                   property!.category.toUpperCase(),
//                                   style: const TextStyle(
//                                     fontSize: 11,
//                                     fontWeight: FontWeight.w700,
//                                     color: _primary,
//                                   ),
//                                 ),
//                               ),
//
//                               const SizedBox(height: 10),
//
//                               Text(
//                                 property!.title,
//                                 style: const TextStyle(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.w700,
//                                   color: _textPrimary,
//                                 ),
//                               ),
//
//                               const SizedBox(height: 16),
//
//                               _infoRow(
//                                 Icons.location_on_outlined,
//                                 'Location',
//                                 property!.location,
//                               ),
//
//                               _infoRow(
//                                 Icons.bed_outlined,
//                                 'Bedrooms',
//                                 '${property!.bedrooms}',
//                               ),
//
//                               _infoRow(
//                                 Icons.bathtub_outlined,
//                                 'Bathrooms',
//                                 '${property!.bathrooms}',
//                               ),
//
//                               _infoRow(
//                                 Icons.person_outline_rounded,
//                                 'Owner',
//                                 owner!.fullName,
//                               ),
//
//                               _infoRow(
//                                 Icons.phone_outlined,
//                                 'Phone',
//                                 owner!.phone.isEmpty
//                                     ? 'Not provided'
//                                     : owner!.phone,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   // ==================================================
//                   // PAYMENT SUMMARY
//                   // ==================================================
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: _card,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _sectionTitle('Payment Summary'),
//
//                         const SizedBox(height: 16),
//
//                         _summaryRow(
//                           'Monthly Rent',
//                           '\$${widget.booking.totalAmount.toStringAsFixed(2)}',
//                         ),
//
//                         const Padding(
//                           padding: EdgeInsets.symmetric(vertical: 8),
//                           child: Divider(color: _border),
//                         ),
//
//                         _summaryRow(
//                           'Total Due',
//                           '\$${widget.booking.totalAmount.toStringAsFixed(2)}',
//                           isTotal: true,
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   // ==================================================
//                   // BOOKING
//                   // ==================================================
//                   Row(
//                     children: [
//                       _metaChip(
//                         'Status',
//                         widget.booking.paymentStatus ?? 'Pending',
//                       ),
//                       const SizedBox(width: 12),
//                       _metaChip('Booking ID', widget.booking.bookingId ?? '—'),
//                     ],
//                   ),
//
//                   const SizedBox(height: 12),
//
//                   Row(children: [_metaChip('Renter', renter!.fullName)]),
//
//                   const SizedBox(height: 24),
//
//                   // ==================================================
//                   // REAL BAKONG QR
//                   // ==================================================
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: _card,
//                       borderRadius: BorderRadius.circular(20),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.04),
//                           blurRadius: 20,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       children: [
//                         const Text(
//                           'Pay with Bakong',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w800,
//                             color: _textPrimary,
//                           ),
//                         ),
//
//                         const SizedBox(height: 8),
//
//                         const Text(
//                           'Scan this KHQR using Bakong or a supported bank app.',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 13,
//                             color: _textSecondary,
//                             height: 1.4,
//                           ),
//                         ),
//
//                         const SizedBox(height: 20),
//
//                         _buildBakongQr(),
//
//                         const SizedBox(height: 20),
//
//                         Text(
//                           '\$${widget.booking.totalAmount.toStringAsFixed(2)}',
//                           style: const TextStyle(
//                             fontSize: 30,
//                             fontWeight: FontWeight.w800,
//                             color: _primary,
//                           ),
//                         ),
//
//                         const Text(
//                           'USD',
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: _textSecondary,
//                           ),
//                         ),
//
//                         const SizedBox(height: 16),
//
//                         // ----------------------------------------------
//                         // COUNTDOWN
//                         // ----------------------------------------------
//                         if (!_isQrExpired)
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 14,
//                               vertical: 10,
//                             ),
//                             decoration: BoxDecoration(
//                               color: _primary.withOpacity(0.08),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 const Icon(
//                                   Icons.timer_outlined,
//                                   size: 18,
//                                   color: _primary,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   'QR expires in $_remainingTimeText',
//                                   style: const TextStyle(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w700,
//                                     color: _primary,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//
//                         // ----------------------------------------------
//                         // EXPIRED
//                         // ----------------------------------------------
//                         if (_isQrExpired)
//                           Column(
//                             children: [
//                               Container(
//                                 width: double.infinity,
//                                 padding: const EdgeInsets.all(12),
//                                 decoration: BoxDecoration(
//                                   color: Colors.red.withOpacity(0.08),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: const Row(
//                                   children: [
//                                     Icon(
//                                       Icons.error_outline,
//                                       size: 18,
//                                       color: Colors.red,
//                                     ),
//                                     SizedBox(width: 10),
//                                     Expanded(
//                                       child: Text(
//                                         'This QR code has expired.',
//                                         style: TextStyle(
//                                           fontSize: 12,
//                                           color: Colors.red,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//
//                               const SizedBox(height: 12),
//
//                               OutlinedButton(
//                                 onPressed: _regenerateQr,
//                                 child: const Text('Generate New QR'),
//                               ),
//                             ],
//                           ),
//
//                         const SizedBox(height: 16),
//
//                         // ----------------------------------------------
//                         // INFO
//                         // ----------------------------------------------
//                         Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.blue.withOpacity(0.06),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: const Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Icon(
//                                 Icons.info_outline,
//                                 size: 18,
//                                 color: _primary,
//                               ),
//                               SizedBox(width: 10),
//                               Expanded(
//                                 child: Text(
//                                   'Scan the QR and complete the payment first. Then tap "Check Payment".',
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: _textSecondary,
//                                     height: 1.4,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(height: 24),
//
//                   // ==================================================
//                   // TERMS
//                   // ==================================================
//                   GestureDetector(
//                     onTap: _isPaying
//                         ? null
//                         : () {
//                             setState(() {
//                               _isTermsAgreed = !_isTermsAgreed;
//                             });
//                           },
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         AnimatedContainer(
//                           duration: const Duration(milliseconds: 200),
//                           width: 22,
//                           height: 22,
//                           decoration: BoxDecoration(
//                             color: _isTermsAgreed
//                                 ? _primary
//                                 : Colors.transparent,
//                             borderRadius: BorderRadius.circular(6),
//                             border: Border.all(
//                               color: _isTermsAgreed ? _primary : _border,
//                               width: 1.8,
//                             ),
//                           ),
//                           child: _isTermsAgreed
//                               ? const Icon(
//                                   Icons.check_rounded,
//                                   size: 16,
//                                   color: Colors.white,
//                                 )
//                               : null,
//                         ),
//
//                         const SizedBox(width: 12),
//
//                         const Expanded(
//                           child: Text(
//                             'I agree to the payment terms and rental agreement.',
//                             style: TextStyle(
//                               fontSize: 13,
//                               color: _textSecondary,
//                               height: 1.4,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(height: 32),
//                 ],
//               ),
//             ),
//           ),
//
//           // ========================================================
//           // BOTTOM BUTTON
//           // ========================================================
//           Container(
//             padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
//             decoration: BoxDecoration(
//               color: _card,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.06),
//                   blurRadius: 20,
//                   offset: const Offset(0, -4),
//                 ),
//               ],
//             ),
//             child: SizedBox(
//               width: double.infinity,
//               height: 56,
//               child: ElevatedButton(
//                 onPressed: _isPaying || _isGeneratingQr || _isQrExpired
//                     ? null
//                     : _onPayNow,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: _primary,
//                   disabledBackgroundColor: _primary.withOpacity(0.45),
//                   foregroundColor: Colors.white,
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                 ),
//                 child: _isPaying
//                     ? const SizedBox(
//                         width: 24,
//                         height: 24,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2.5,
//                           color: Colors.white,
//                         ),
//                       )
//                     : const Text(
//                         'Check Payment',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:khqr_sdk/khqr_sdk.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../models/booking_model.dart';
import '../../../models/property_model.dart';
import '../../../models/user_model.dart';
import '../../../services/payment_service.dart';
import '../../../services/telegram_service.dart';

class RenterPaymentScreen extends StatefulWidget {
  final BookingModel booking;

  const RenterPaymentScreen({super.key, required this.booking});

  @override
  State<RenterPaymentScreen> createState() => _RenterPaymentScreenState();
}

class _RenterPaymentScreenState extends State<RenterPaymentScreen> {
  // ============================================================
  // SERVICES
  // ============================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final PaymentService _paymentService = PaymentService();

  // ============================================================
  // DATA
  // ============================================================

  Property? _property;
  UserModel? _owner;
  UserModel? _renter;

  // ============================================================
  // SCREEN STATE
  // ============================================================

  bool _isLoading = true;
  bool _isGeneratingQr = true;
  bool _isPaying = false;
  bool _isTermsAgreed = false;

  String? _errorMessage;

  // ============================================================
  // KHQR STATE
  // ============================================================

  String? _khqrString;
  String? _khqrMd5;

  DateTime? _qrExpiresAt;

  Duration _remainingTime = const Duration(minutes: 2);

  // ============================================================
  // TIMERS
  // ============================================================

  Timer? _countdownTimer;
  Timer? _paymentCheckTimer;

  // ============================================================
  // PAYMENT CHECK STATE
  // ============================================================

  bool _isCheckingPayment = false;
  bool _paymentVerified = false;

  int _paymentCheckAttempts = 0;

  static const Duration _paymentCheckInterval = Duration(seconds: 5);

  static const int _maxPaymentCheckAttempts = 24;

  // ============================================================
  // TEST PAYMENT
  // ============================================================

  static const double _testPaymentAmount = PaymentService.testPaymentAmount;

  static const String _testPaymentCurrency = PaymentService.testPaymentCurrency;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _primary = Color(0xFF4F46E5);

  static const Color _bg = Color(0xFFF8FAFC);

  static const Color _card = Colors.white;

  static const Color _textPrimary = Color(0xFF0F172A);

  static const Color _textSecondary = Color(0xFF64748B);

  static const Color _border = Color(0xFFE2E8F0);

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadPaymentData();
  }

  @override
  void dispose() {
    _cancelTimers();

    super.dispose();
  }

  // ============================================================
  // TIMER MANAGEMENT
  // ============================================================

  void _cancelTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    _paymentCheckTimer?.cancel();
    _paymentCheckTimer = null;
  }

  void _stopPaymentChecking() {
    _paymentCheckTimer?.cancel();
    _paymentCheckTimer = null;
  }

  // ============================================================
  // LOAD PAYMENT DATA
  // ============================================================

  Future<void> _loadPaymentData() async {
    try {
      final propertyFuture = _firestore
          .collection('properties')
          .doc(widget.booking.houseId)
          .get();

      final ownerFuture = _firestore
          .collection('users')
          .doc(widget.booking.ownerId)
          .get();

      final renterFuture = _firestore
          .collection('users')
          .doc(widget.booking.renterId)
          .get();

      final results = await Future.wait([
        propertyFuture,
        ownerFuture,
        renterFuture,
      ]);

      final propertyDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;

      final ownerDoc = results[1] as DocumentSnapshot<Map<String, dynamic>>;

      final renterDoc = results[2] as DocumentSnapshot<Map<String, dynamic>>;

      if (propertyDoc.exists && propertyDoc.data() != null) {
        _property = Property.fromMap(propertyDoc.data()!, propertyDoc.id);
      }

      if (ownerDoc.exists && ownerDoc.data() != null) {
        _owner = UserModel.fromMap(ownerDoc.data()!);
      }

      if (renterDoc.exists && renterDoc.data() != null) {
        _renter = UserModel.fromMap(renterDoc.data()!);
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      await _generateBakongQr();
    } catch (e, stackTrace) {
      debugPrint('LOAD PAYMENT DATA ERROR: $e');
      debugPrint(stackTrace.toString());

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isGeneratingQr = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // GENERATE BAKONG QR
  // ============================================================

  Future<void> _generateBakongQr() async {
    try {
      _stopPaymentChecking();
      _countdownTimer?.cancel();

      if (!mounted) return;

      setState(() {
        _isGeneratingQr = true;
        _errorMessage = null;

        _khqrString = null;
        _khqrMd5 = null;

        _qrExpiresAt = null;

        _remainingTime = const Duration(minutes: 2);

        _paymentCheckAttempts = 0;
        _paymentVerified = false;
        _isCheckingPayment = false;
      });

      // ----------------------------------------------------------
      // VALIDATE TEST AMOUNT
      // ----------------------------------------------------------

      if (_testPaymentAmount <= 0) {
        throw Exception('Invalid test payment amount.');
      }

      // ----------------------------------------------------------
      // QR EXPIRATION
      // ----------------------------------------------------------

      final expireAt = DateTime.now().add(const Duration(minutes: 2));

      // ----------------------------------------------------------
      // CREATE BAKONG INDIVIDUAL INFO
      // ----------------------------------------------------------

      final individualInfo = IndividualInfo(
        bakongAccountId: PaymentService.bakongAccount,
        merchantName: 'RentEase',
        accountInformation: PaymentService.bakongAccount,
        amount: _testPaymentAmount,
        currency: KhqrCurrency.khr,
        expirationTimestamp: expireAt.millisecondsSinceEpoch,
      );

      // ----------------------------------------------------------
      // GENERATE KHQR
      // ----------------------------------------------------------

      final result = KhqrSdk.generateIndividual(individualInfo);

      if (!result.isSuccess) {
        throw Exception(result.status.message);
      }

      if (result.data == null) {
        throw Exception('Bakong did not return KHQR data.');
      }

      // ----------------------------------------------------------
      // GET QR STRING
      // ----------------------------------------------------------

      final qr = result.data!.qr;

      if (qr.trim().isEmpty) {
        throw Exception('Generated KHQR is empty.');
      }

      // ----------------------------------------------------------
      // GENERATE MD5
      // ----------------------------------------------------------

      final md5 = _paymentService.generateKhqrMd5(qr);

      if (md5.trim().isEmpty) {
        throw Exception('Failed to generate KHQR MD5.');
      }

      if (!mounted) return;

      setState(() {
        _khqrString = qr;
        _khqrMd5 = md5;

        _qrExpiresAt = expireAt;

        _remainingTime = const Duration(minutes: 2);

        _isGeneratingQr = false;
      });

      // ----------------------------------------------------------
      // START COUNTDOWN
      // ----------------------------------------------------------

      _startCountdown();

      // ----------------------------------------------------------
      // START AUTOMATIC PAYMENT CHECK
      // ----------------------------------------------------------

      _startAutomaticPaymentCheck();

      // ----------------------------------------------------------
      // DEBUG
      // ----------------------------------------------------------

      debugPrint('');
      debugPrint('====================================');
      debugPrint('BAKONG TEST KHQR GENERATED');
      debugPrint('====================================');
      debugPrint(
        'Amount: '
        '$_testPaymentAmount $_testPaymentCurrency',
      );
      debugPrint(
        'Booking Amount: '
        '${widget.booking.totalAmount} USD',
      );
      debugPrint('MD5: $md5');
      debugPrint(
        'Account: '
        '${PaymentService.bakongAccount}',
      );
      debugPrint('Expires: $expireAt');
      debugPrint('====================================');
    } catch (e, stackTrace) {
      debugPrint('GENERATE BAKONG QR ERROR: $e');

      debugPrint(stackTrace.toString());

      if (!mounted) return;

      setState(() {
        _isGeneratingQr = false;

        _errorMessage = 'Unable to generate Bakong QR.\n$e';
      });
    }
  }

  // ============================================================
  // START AUTOMATIC PAYMENT CHECK
  // ============================================================

  void _startAutomaticPaymentCheck() {
    _stopPaymentChecking();

    _paymentCheckAttempts = 0;
    _paymentVerified = false;

    debugPrint('');
    debugPrint('====================================');
    debugPrint('START AUTOMATIC BAKONG PAYMENT CHECK');
    debugPrint('Interval: $_paymentCheckInterval');
    debugPrint('Max attempts: $_maxPaymentCheckAttempts');
    debugPrint('====================================');

    _paymentCheckTimer = Timer.periodic(_paymentCheckInterval, (_) {
      _checkPaymentAutomatically();
    });
  }

  // ============================================================
  // AUTOMATIC PAYMENT CHECK
  // ============================================================

  Future<void> _checkPaymentAutomatically() async {
    if (!mounted) return;

    if (_paymentVerified) return;

    if (_isCheckingPayment) return;

    if (_isPaying) return;

    if (_isQrExpired) {
      debugPrint('Bakong QR expired.');

      _stopPaymentChecking();

      return;
    }

    final md5 = _khqrMd5;

    if (md5 == null || md5.trim().isEmpty) {
      return;
    }

    final bookingId = _bookingId;

    if (bookingId == null) {
      return;
    }

    if (_paymentCheckAttempts >= _maxPaymentCheckAttempts) {
      _stopPaymentChecking();

      if (mounted && !_paymentVerified) {
        _showPaymentFailedDialog(
          Exception(
            'Payment was not detected within the allowed time. '
            'Please check your Bakong transaction and try again.',
          ),
        );
      }

      return;
    }

    _paymentCheckAttempts++;

    await _verifyPayment(
      bookingId: bookingId,
      md5: md5,
      showCheckingDialog: false,
      automatic: true,
    );
  }

  Future<void> _onPayNow() async {
    if (_isPaying) return;

    if (!_isTermsAgreed) {
      _showErrorDialog(
        title: 'Payment Terms',
        message:
            'Please agree to the payment terms and '
            'rental agreement before continuing.',
      );

      return;
    }

    final md5 = _khqrMd5;

    if (md5 == null || md5.trim().isEmpty) {
      _showErrorDialog(
        title: 'QR Not Ready',
        message:
            'Bakong QR is not ready. '
            'Please generate a new QR code.',
      );

      return;
    }

    // ----------------------------------------------------------
    // QR EXPIRATION
    // ----------------------------------------------------------

    if (_isQrExpired) {
      _showErrorDialog(
        title: 'QR Expired',
        message:
            'This Bakong QR has expired. '
            'Please generate a new QR code.',
      );

      return;
    }

    // ----------------------------------------------------------
    // BOOKING ID
    // ----------------------------------------------------------

    final bookingId = _bookingId;

    if (bookingId == null) {
      _showErrorDialog(
        title: 'Invalid Booking',
        message: 'Booking ID is missing.',
      );

      return;
    }

    // ----------------------------------------------------------
    // MANUAL PAYMENT VERIFICATION
    // ----------------------------------------------------------

    await _verifyPayment(
      bookingId: bookingId,
      md5: md5,
      showCheckingDialog: true,
      automatic: false,
    );
  }

  // ============================================================
  // CENTRAL PAYMENT VERIFICATION
  // ============================================================
  //
  // This is the ONLY place that calls:
  //
  // PaymentService.completePayment()
  //
  // completePayment() should perform:
  //
  // 1. Verify Bakong transaction
  // 2. Firestore transaction
  // 3. Save payment
  // 4. Update booking
  //
  // ============================================================

  Future<void> _verifyPayment({
    required String bookingId,
    required String md5,
    required bool showCheckingDialog,
    required bool automatic,
  }) async {
    if (_paymentVerified) {
      return;
    }

    if (_isCheckingPayment) {
      return;
    }

    _isCheckingPayment = true;

    if (!automatic) {
      if (mounted) {
        setState(() {
          _isPaying = true;
        });
      }

      _showCheckingPaymentDialog();
    }

    try {
      debugPrint('');
      debugPrint('====================================');
      debugPrint(
        automatic
            ? 'AUTOMATIC BAKONG PAYMENT CHECK'
            : 'MANUAL BAKONG PAYMENT CHECK',
      );
      debugPrint('Attempt: $_paymentCheckAttempts');
      debugPrint('Booking ID: $bookingId');
      debugPrint('MD5: $md5');
      debugPrint(
        'Test Amount: '
        '$_testPaymentAmount $_testPaymentCurrency',
      );
      debugPrint('====================================');

      final result = await _paymentService.completePayment(
        bookingId: bookingId,
        paymentMethod: 'Bakong',
        khqrMd5: md5,
      );

      if (!mounted) return;

      // --------------------------------------------------------
      // PAYMENT SUCCESS
      // --------------------------------------------------------

      _paymentVerified = true;

      _stopPaymentChecking();

      if (!automatic) {
        _closeCheckingDialog();
      }

      setState(() {
        _isPaying = false;
      });

      debugPrint('');
      debugPrint('====================================');
      debugPrint('BAKONG PAYMENT SUCCESS');
      debugPrint('====================================');

      // --------------------------------------------------------
      // TELEGRAM
      // --------------------------------------------------------

      await _sendPaymentNotification(result);

      if (!mounted) return;

      // --------------------------------------------------------
      // SUCCESS DIALOG
      // --------------------------------------------------------

      _showPaymentSuccessDialog(result);
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('====================================');
      debugPrint(
        automatic ? 'AUTOMATIC PAYMENT NOT CONFIRMED' : 'MANUAL PAYMENT FAILED',
      );
      debugPrint('====================================');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());

      if (!mounted) return;

      if (!automatic) {
        _closeCheckingDialog();

        setState(() {
          _isPaying = false;
        });

        _showPaymentFailedDialog(e);
      }
    } finally {
      _isCheckingPayment = false;
    }
  }

  // ============================================================
  // CLOSE CHECKING DIALOG
  // ============================================================

  void _closeCheckingDialog() {
    if (!mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);

    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  // ============================================================
  // QR COUNTDOWN
  // ============================================================

  void _startCountdown() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final expiresAt = _qrExpiresAt;

      if (expiresAt == null) {
        return;
      }

      final difference = expiresAt.difference(DateTime.now());

      if (difference.inSeconds <= 0) {
        _countdownTimer?.cancel();

        setState(() {
          _remainingTime = Duration.zero;
        });

        _stopPaymentChecking();

        return;
      }

      setState(() {
        _remainingTime = difference;
      });
    });
  }

  // ============================================================
  // QR EXPIRED
  // ============================================================

  bool get _isQrExpired {
    final expiresAt = _qrExpiresAt;

    if (expiresAt == null) {
      return true;
    }

    return DateTime.now().isAfter(expiresAt);
  }

  // ============================================================
  // REMAINING TIME
  // ============================================================

  String get _remainingTimeText {
    final minutes = _remainingTime.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    final seconds = _remainingTime.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return '$minutes:$seconds';
  }

  // ============================================================
  // BOOKING ID
  // ============================================================

  String? get _bookingId {
    final id = widget.booking.bookingId;

    if (id == null || id.trim().isEmpty) {
      return null;
    }

    return id.trim();
  }

  // ============================================================
  // REGENERATE QR
  // ============================================================

  Future<void> _regenerateQr() async {
    await _generateBakongQr();
  }

  // ============================================================
  // TELEGRAM PAYMENT NOTIFICATION
  // ============================================================

  Future<void> _sendPaymentNotification(Map<String, dynamic> result) async {
    /*
     * IMPORTANT:
     *
     * Replace this hard-coded chat ID with the owner's
     * real Telegram chat ID.
     *
     * Ideally, store the owner's Telegram chat ID
     * inside Firestore.
     */

    const ownerChatId = '987654321';

    try {
      final amount = result['amount'] ?? _testPaymentAmount;

      final currency = result['currency'] ?? _testPaymentCurrency;

      final paymentId = result['paymentId'] ?? 'N/A';

      final transactionHash = result['transactionHash'] ?? 'N/A';

      final message =
          '''
💰 ការទូទាត់ប្រាក់បានជោគជ័យ

📋 លេខ Booking:
${widget.booking.bookingId ?? 'N/A'}

💳 Payment ID:
$paymentId

🔗 Bakong Transaction:
$transactionHash

👤 អ្នកជួល:
${_renter?.fullName ?? 'មិនមាន'}

📞 ទូរស័ព្ទ:
${_renter?.phone ?? 'មិនមាន'}

🏠 ផ្ទះ/បន្ទប់:
${_property?.title ?? 'មិនមាន'}

💵 ប្រាក់ដែលបានទូទាត់:
${amount.toString()} $currency

💵 តម្លៃ Booking:
\$${widget.booking.totalAmount.toStringAsFixed(2)} USD

💳 វិធីទូទាត់:
Bakong

🧪 Test Mode:
100 KHR

ស្ថានភាព:
បានទូទាត់រួចរាល់ ✅
''';

      final success = await TelegramService.sendMessage(
        chatId: ownerChatId,
        message: message,
      );

      if (success) {
        debugPrint('Telegram notification sent.');
      } else {
        debugPrint('Telegram notification failed.');
      }
    } catch (e, stackTrace) {
      /*
       * IMPORTANT:
       *
       * Telegram failure must NOT make
       * the payment itself fail.
       */

      debugPrint('Telegram notification error: $e');

      debugPrint(stackTrace.toString());
    }
  }

  // ============================================================
  // CHECKING PAYMENT DIALOG
  // ============================================================

  void _showCheckingPaymentDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 8),

                CircularProgressIndicator(color: _primary),

                SizedBox(height: 24),

                Text(
                  'Checking Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Please wait while we verify your Bakong transaction.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PAYMENT SUCCESS DIALOG
  // ============================================================

  void _showPaymentSuccessDialog(Map<String, dynamic> result) {
    final paidAmount =
        (result['amount'] as num?)?.toDouble() ?? _testPaymentAmount;

    final paidCurrency = result['currency']?.toString() ?? _testPaymentCurrency;

    final paymentId = result['paymentId']?.toString() ?? 'N/A';

    final transactionHash = result['transactionHash']?.toString() ?? 'N/A';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ------------------------------------------------
                // SUCCESS ICON
                // ------------------------------------------------
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 50,
                    color: Colors.green,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Payment Successful',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Your Bakong test payment has been successfully verified and recorded.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // PAYMENT AMOUNT
                // ------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Test Payment',
                        style: TextStyle(fontSize: 12, color: _textSecondary),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        '${paidAmount.toStringAsFixed(0)} $paidCurrency',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: _primary,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        'Bakong Test Mode',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                _successInfoRow(
                  'Booking Amount',
                  '\$${widget.booking.totalAmount.toStringAsFixed(2)} USD',
                ),

                _successInfoRow('Payment Method', 'Bakong'),

                _successInfoRow('Status', 'Paid', valueColor: Colors.green),

                _successInfoRow('Payment ID', paymentId),

                _successInfoRow('Transaction', transactionHash),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();

                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SUCCESS INFO ROW
  // ============================================================

  Widget _successInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: _textSecondary),
          ),

          const SizedBox(width: 12),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT FAILED DIALOG
  // ============================================================

  void _showPaymentFailedDialog(Object error) {
    String message = error.toString();

    if (message.startsWith('Exception:')) {
      message = message.replaceFirst('Exception:', '').trim();
    }

    if (message.isEmpty) {
      message = 'Payment could not be confirmed.';
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 42,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Payment Not Confirmed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: _textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text(
                  'Close',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ERROR DIALOG
  // ============================================================

  void _showErrorDialog({required String title, required String message}) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            message,
            style: const TextStyle(color: _textSecondary, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _primary),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY ROW
  // ============================================================

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? _textPrimary : _textSecondary,
            ),
          ),

          const SizedBox(width: 12),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: isTotal ? 22 : 15,
                fontWeight: FontWeight.w700,
                color: isTotal ? _primary : _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // META CHIP
  // ============================================================

  Widget _metaChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _textSecondary,
                letterSpacing: 0.6,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BAKONG QR
  // ============================================================

  Widget _buildBakongQr() {
    // ----------------------------------------------------------
    // GENERATING
    // ----------------------------------------------------------

    if (_isGeneratingQr) {
      return Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: const Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    // ----------------------------------------------------------
    // QR UNAVAILABLE
    // ----------------------------------------------------------

    final qr = _khqrString;

    if (qr == null || qr.trim().isEmpty) {
      return Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'QR unavailable',
            style: TextStyle(color: _textSecondary),
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // QR
    // ----------------------------------------------------------

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: QrImageView(
        data: qr,
        version: QrVersions.auto,
        size: 220,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ),
    );
  }

  // ============================================================
  // PROPERTY IMAGE
  // ============================================================

  Widget _buildPropertyImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          _property!.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              color: _border,
              child: const Icon(
                Icons.home_rounded,
                size: 48,
                color: _textSecondary,
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // PROPERTY CARD
  // ============================================================

  Widget _buildPropertyCard() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPropertyImage(),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _property!.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  _property!.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                _infoRow(
                  Icons.location_on_outlined,
                  'Location',
                  _property!.location,
                ),

                _infoRow(
                  Icons.bed_outlined,
                  'Bedrooms',
                  '${_property!.bedrooms}',
                ),

                _infoRow(
                  Icons.bathtub_outlined,
                  'Bathrooms',
                  '${_property!.bathrooms}',
                ),

                _infoRow(
                  Icons.person_outline_rounded,
                  'Owner',
                  _owner!.fullName,
                ),

                _infoRow(
                  Icons.phone_outlined,
                  'Phone',
                  _owner!.phone.isEmpty ? 'Not provided' : _owner!.phone,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT SUMMARY CARD
  // ============================================================

  Widget _buildPaymentSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Payment Summary'),

          const SizedBox(height: 16),

          _summaryRow(
            'Monthly Rent',
            '\$${widget.booking.totalAmount.toStringAsFixed(2)}',
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: _border),
          ),

          _summaryRow(
            'Booking Total',
            '\$${widget.booking.totalAmount.toStringAsFixed(2)} USD',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOOKING INFORMATION
  // ============================================================

  Widget _buildBookingInformation() {
    return Column(
      children: [
        Row(
          children: [
            _metaChip('Status', widget.booking.paymentStatus ?? 'Pending'),

            const SizedBox(width: 12),

            _metaChip('Booking ID', widget.booking.bookingId ?? '—'),
          ],
        ),

        const SizedBox(height: 12),

        Row(children: [_metaChip('Renter', _renter!.fullName)]),
      ],
    );
  }

  // ============================================================
  // BAKONG PAYMENT CARD
  // ============================================================

  Widget _buildBakongPaymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Pay with Bakong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Scan this KHQR using Bakong or a supported bank app.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _textSecondary, height: 1.4),
          ),

          const SizedBox(height: 20),

          _buildBakongQr(),

          const SizedBox(height: 20),

          Text(
            '${_testPaymentAmount.toStringAsFixed(0)} $_testPaymentCurrency',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Bakong Test Payment',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Booking amount: '
            '\$${widget.booking.totalAmount.toStringAsFixed(2)} USD',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: _textSecondary),
          ),

          const SizedBox(height: 16),

          // ----------------------------------------------------
          // COUNTDOWN
          // ----------------------------------------------------
          if (!_isQrExpired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 18, color: _primary),

                  const SizedBox(width: 8),

                  Text(
                    'QR expires in '
                    '$_remainingTimeText',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                ],
              ),
            ),

          // ----------------------------------------------------
          // EXPIRED
          // ----------------------------------------------------
          if (_isQrExpired)
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.error_outline, size: 18, color: Colors.red),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'This QR code has expired.',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton(
                  onPressed: _regenerateQr,
                  child: const Text('Generate New QR'),
                ),
              ],
            ),

          const SizedBox(height: 16),

          // ----------------------------------------------------
          // INFORMATION
          // ----------------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: _primary),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Scan the QR and pay 100 KHR first. The app will automatically check your Bakong transaction.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TERMS
  // ============================================================

  Widget _buildTerms() {
    return GestureDetector(
      onTap: _isPaying
          ? null
          : () {
              setState(() {
                _isTermsAgreed = !_isTermsAgreed;
              });
            },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _isTermsAgreed ? _primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _isTermsAgreed ? _primary : _border,
                width: 1.8,
              ),
            ),
            child: _isTermsAgreed
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : null,
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              'I agree to the payment terms and rental agreement.',
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM PAYMENT BUTTON
  // ============================================================

  Widget _buildBottomButton() {
    final disabled =
        _isPaying || _isGeneratingQr || _isQrExpired || _paymentVerified;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: _card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: disabled ? null : _onPayNow,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            disabledBackgroundColor: _primary.withOpacity(0.45),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isPaying
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Check Payment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING SCREEN
  // ============================================================

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: _bg,
      body: Center(child: CircularProgressIndicator(color: _primary)),
    );
  }

  // ============================================================
  // ERROR SCREEN
  // ============================================================

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red,
              ),

              const SizedBox(height: 16),

              Text(
                _errorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textSecondary),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _regenerateQr,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INVALID DATA SCREEN
  // ============================================================

  Widget _buildInvalidDataScreen() {
    return const Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Text(
          'Failed to load payment data.',
          style: TextStyle(color: _textSecondary),
        ),
      ),
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ----------------------------------------------------------
    // LOADING
    // ----------------------------------------------------------

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    // ----------------------------------------------------------
    // VALIDATE DATA
    // ----------------------------------------------------------

    if (_property == null || _owner == null || _renter == null) {
      return _buildInvalidDataScreen();
    }

    // ----------------------------------------------------------
    // MAIN SCREEN
    // ----------------------------------------------------------

    return Scaffold(
      backgroundColor: _bg,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _textPrimary,
          ),
          onPressed: _isPaying ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Complete Payment',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------
                  // PROPERTY
                  // ------------------------------------------------
                  _buildPropertyCard(),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // PAYMENT SUMMARY
                  // ------------------------------------------------
                  _buildPaymentSummary(),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // BOOKING INFORMATION
                  // ------------------------------------------------
                  _buildBookingInformation(),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // BAKONG PAYMENT
                  // ------------------------------------------------
                  _buildBakongPaymentCard(),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // TERMS
                  // ------------------------------------------------
                  _buildTerms(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ======================================================
          // BOTTOM BUTTON
          // ======================================================
          _buildBottomButton(),
        ],
      ),
    );
  }
}

//
// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:khqr_sdk/khqr_sdk.dart';
// import 'package:qr_flutter/qr_flutter.dart';
//
// import '../../../models/booking_model.dart';
// import '../../../services/payment_service.dart';
//
// class RenterPaymentScreen extends StatefulWidget {
//   final BookingModel booking;
//
//   const RenterPaymentScreen({
//     super.key,
//     required this.booking,
//   });
//
//   @override
//   State<RenterPaymentScreen> createState() => _RenterPaymentScreenState();
// }
//
// class _RenterPaymentScreenState extends State<RenterPaymentScreen> {
//   bool isLoading = true;
//   bool _isGeneratingQr = true;
//   bool _isCheckingPayment = false;
//   bool _paymentConfirmed = false;
//   bool _paymentRateLimited = false;
//   bool _isTermsAgreed = false;
//   bool _isProcessingPayment = false;
//
//   String? errorMessage;
//   String? _khqrString;
//   String? _khqrMd5;
//
//   DateTime? _qrExpiresAt;
//
//   Timer? _countdownTimer;
//   Timer? _paymentCheckTimer;
//
//   Duration _remainingTime = const Duration(minutes: 2);
//
//   final PaymentService paymentService = PaymentService();
//
//   @override
//   void initState() {
//     super.initState();
//     _loadPaymentData();
//   }
//
//   @override
//   void dispose() {
//     _countdownTimer?.cancel();
//     _paymentCheckTimer?.cancel();
//     super.dispose();
//   }
//
//   // ============================================================
//   // LOAD PAYMENT DATA
//   // ============================================================
//
//   Future<void> _loadPaymentData() async {
//     if (!mounted) return;
//
//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });
//
//     try {
//       await _generateBakongQr();
//     } catch (e) {
//       debugPrint('LOAD PAYMENT ERROR: $e');
//
//       if (!mounted) return;
//
//       setState(() {
//         errorMessage = e.toString();
//       });
//     } finally {
//       if (!mounted) return;
//
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   // ============================================================
//   // GENERATE KHQR
//   // ============================================================
//
//   Future<void> _generateBakongQr() async {
//     _countdownTimer?.cancel();
//     _paymentCheckTimer?.cancel();
//
//     if (!mounted) return;
//
//     setState(() {
//       _isGeneratingQr = true;
//       _paymentConfirmed = false;
//       _paymentRateLimited = false;
//       _isProcessingPayment = false;
//       errorMessage = null;
//       _khqrString = null;
//       _khqrMd5 = null;
//     });
//
//     try {
//       const double amount =
//           PaymentService.testPaymentAmount;
//
//       const KhqrCurrency currency =
//           KhqrCurrency.khr;
//
//       // QR expires after 2 minutes.
//       final DateTime expiresAt =
//       DateTime.now().add(
//         const Duration(minutes: 2),
//       );
//
//       debugPrint('====================================');
//       debugPrint('GENERATING BAKONG KHQR');
//       debugPrint('====================================');
//       debugPrint(
//         'Account: ${PaymentService.bakongAccount}',
//       );
//       debugPrint('Amount: $amount KHR');
//       debugPrint('Expires: $expiresAt');
//
//       final individualInfo = IndividualInfo(
//         bakongAccountId:
//         PaymentService.bakongAccount,
//         merchantName: 'RentEase',
//         accountInformation:
//         PaymentService.bakongAccount,
//         amount: amount,
//         currency: currency,
//         expirationTimestamp:
//         expiresAt.millisecondsSinceEpoch,
//       );
//
//       // khqr_sdk 3.0.0:
//       // generateIndividual() takes IndividualInfo
//       // as a positional parameter and is synchronous.
//       final result =
//       KhqrSdk.generateIndividual(
//         individualInfo,
//       );
//
//       if (!result.isSuccess) {
//         throw Exception(
//           result.status?.toString() ??
//               'Unable to generate KHQR.',
//         );
//       }
//
//       if (result.data == null) {
//         throw Exception(
//           'Bakong QR data is empty.',
//         );
//       }
//
//       final String qr =
//           result.data!.qr;
//
//       if (qr.trim().isEmpty) {
//         throw Exception(
//           'Generated Bakong QR is empty.',
//         );
//       }
//
//       // Generate MD5 from the KHQR string.
//       final String md5 =
//       paymentService.generateKhqrMd5(qr);
//
//       debugPrint(
//         'KHQR generated successfully.',
//       );
//       debugPrint('MD5: $md5');
//
//       if (!mounted) return;
//
//       setState(() {
//         _khqrString = qr;
//         _khqrMd5 = md5;
//         _qrExpiresAt = expiresAt;
//         _remainingTime =
//         const Duration(minutes: 2);
//         _isGeneratingQr = false;
//       });
//
//       _startCountdown();
//
//       // Start automatic payment checking only
//       // after the renter accepts the terms.
//       if (_isTermsAgreed) {
//         _startAutomaticPaymentCheck();
//       }
//     } catch (e) {
//       debugPrint(
//         'GENERATE BAKONG QR ERROR: $e',
//       );
//
//       if (!mounted) return;
//
//       setState(() {
//         _isGeneratingQr = false;
//         errorMessage = e.toString();
//       });
//     }
//   }
//
//   // ============================================================
//   // COUNTDOWN
//   // ============================================================
//
//   void _startCountdown() {
//     _countdownTimer?.cancel();
//
//     _countdownTimer = Timer.periodic(
//       const Duration(seconds: 1),
//           (_) {
//         if (!mounted || _qrExpiresAt == null) {
//           _countdownTimer?.cancel();
//           return;
//         }
//
//         final remaining = _qrExpiresAt!.difference(
//           DateTime.now(),
//         );
//
//         if (remaining <= Duration.zero) {
//           _countdownTimer?.cancel();
//           _paymentCheckTimer?.cancel();
//
//           if (!mounted) return;
//
//           setState(() {
//             _remainingTime = Duration.zero;
//           });
//
//           return;
//         }
//
//         setState(() {
//           _remainingTime = remaining;
//         });
//       },
//     );
//   }
//
//   String _formatRemainingTime() {
//     final minutes = _remainingTime.inMinutes
//         .remainder(60)
//         .toString()
//         .padLeft(2, '0');
//
//     final seconds = _remainingTime.inSeconds
//         .remainder(60)
//         .toString()
//         .padLeft(2, '0');
//
//     return '$minutes:$seconds';
//   }
//
//   bool get _qrExpired {
//     if (_qrExpiresAt == null) return true;
//
//     return DateTime.now().isAfter(_qrExpiresAt!);
//   }
//
//   // ============================================================
//   // AUTOMATIC PAYMENT CHECK
//   // ============================================================
//
//   void _startAutomaticPaymentCheck() {
//     _paymentCheckTimer?.cancel();
//
//     if (_qrExpired) {
//       return;
//     }
//
//     if (_khqrMd5 == null || _khqrMd5!.isEmpty) {
//       return;
//     }
//
//     if (!_isTermsAgreed) {
//       return;
//     }
//
//     if (_paymentRateLimited) {
//       return;
//     }
//
//     // Check immediately.
//     _checkPaymentAutomatically();
//
//     // Then check every 10 seconds.
//     _paymentCheckTimer = Timer.periodic(
//       const Duration(seconds: 10),
//           (_) {
//         _checkPaymentAutomatically();
//       },
//     );
//   }
//
//   Future<void> _checkPaymentAutomatically() async {
//     if (!mounted) return;
//
//     if (_isCheckingPayment) {
//       return;
//     }
//
//     if (_paymentConfirmed) {
//       return;
//     }
//
//     if (_paymentRateLimited) {
//       return;
//     }
//
//     if (!_isTermsAgreed) {
//       return;
//     }
//
//     if (_khqrMd5 == null || _khqrMd5!.isEmpty) {
//       return;
//     }
//
//     if (_qrExpired) {
//       _paymentCheckTimer?.cancel();
//
//       if (!mounted) return;
//
//       setState(() {});
//
//       return;
//     }
//
//     setState(() {
//       _isCheckingPayment = true;
//     });
//
//     try {
//       // IMPORTANT:
//       // bookingId must be the actual BookingModel booking ID.
//       // Do NOT use totalAmount here.
//       final String bookingId =
//       widget.booking.bookingId.toString();
//
//       debugPrint('====================================');
//       debugPrint('AUTOMATIC BAKONG PAYMENT CHECK');
//       debugPrint('====================================');
//       debugPrint('Booking ID: $bookingId');
//       debugPrint(
//         'Booking Amount: ${widget.booking.totalAmount}',
//       );
//       debugPrint('MD5: $_khqrMd5');
//
//       /*
//      * completePayment() already:
//      *
//      * 1. Finds the booking
//      * 2. Verifies Bakong transaction
//      * 3. Checks amount/currency/account
//      * 4. Checks duplicate transaction
//      * 5. Creates payment document
//      * 6. Updates booking
//      *
//      * Therefore we call it only ONCE.
//      */
//
//       final result = await paymentService.completePayment(
//         bookingId: bookingId,
//         paymentMethod: 'Bakong',
//         khqrMd5: _khqrMd5!,
//       );
//
//       debugPrint('====================================');
//       debugPrint('PAYMENT SUCCESS');
//       debugPrint('====================================');
//       debugPrint('Booking ID: $bookingId');
//       debugPrint('Result: $result');
//
//       _paymentCheckTimer?.cancel();
//
//       if (!mounted) return;
//
//       setState(() {
//         _paymentConfirmed = true;
//         _isProcessingPayment = false;
//       });
//
//       await _notifyPaymentSuccess(result);
//
//       if (!mounted) return;
//
//       await _showPaymentSuccessDialog(result);
//     } catch (e, stackTrace) {
//       final String message = e.toString();
//
//       debugPrint('====================================');
//       debugPrint('AUTOMATIC PAYMENT CHECK RESULT');
//       debugPrint('====================================');
//       debugPrint('Exception: $message');
//       debugPrint('StackTrace: $stackTrace');
//
//       final String lowerMessage =
//       message.toLowerCase();
//
//       /*
//      * Bakong daily API limit.
//      *
//      * Stop polling when the limit is reached.
//      */
//       final bool isRateLimited =
//           lowerMessage.contains('daily request limit') ||
//               lowerMessage.contains('request limit') ||
//               lowerMessage.contains('too many requests') ||
//               lowerMessage.contains('rate limit');
//
//       if (isRateLimited) {
//         _paymentCheckTimer?.cancel();
//
//         if (!mounted) return;
//
//         setState(() {
//           _paymentRateLimited = true;
//           _isProcessingPayment = false;
//         });
//
//         debugPrint(
//           'Bakong daily request limit reached.',
//         );
//
//         return;
//       }
//
//       /*
//      * Booking errors should NOT be treated as
//      * "payment not completed".
//      *
//      * This helps us catch incorrect booking IDs.
//      */
//       if (lowerMessage.contains('booking not found')) {
//         _paymentCheckTimer?.cancel();
//
//         if (!mounted) return;
//
//         setState(() {
//           errorMessage = message;
//           _isProcessingPayment = false;
//         });
//
//         debugPrint(
//           'ERROR: Booking ID is incorrect.',
//         );
//
//         return;
//       }
//
//       /*
//      * Other errors are logged.
//      *
//      * The next automatic check can try again.
//      */
//       debugPrint(
//         'Payment not confirmed yet. '
//             'Automatic checking will continue.',
//       );
//     } finally {
//       if (!mounted) return;
//
//       setState(() {
//         _isCheckingPayment = false;
//       });
//     }
//   }
//
//   // ============================================================
//   // TERMS
//   // ============================================================
//
//   void _onTermsChanged(bool? value) {
//     final agreed = value ?? false;
//
//     setState(() {
//       _isTermsAgreed = agreed;
//     });
//
//     if (agreed) {
//       _startAutomaticPaymentCheck();
//     } else {
//       _paymentCheckTimer?.cancel();
//     }
//   }
//
//   // ============================================================
//   // REGENERATE QR
//   // ============================================================
//
//   Future<void> _regenerateQr() async {
//     if (_isGeneratingQr) {
//       return;
//     }
//
//     await _generateBakongQr();
//   }
//
//   // ============================================================
//   // PAYMENT SUCCESS NOTIFICATION
//   // ============================================================
//
//   Future<void> _notifyPaymentSuccess(
//       Map<String, dynamic> paymentResult,
//       ) async {
//     try {
//       /*
//        Keep Telegram notification optional.
//
//        If your existing project already has TelegramService,
//        put your existing notification implementation here.
//       */
//
//       debugPrint(
//         'Payment notification data: $paymentResult',
//       );
//     } catch (e) {
//       debugPrint(
//         'PAYMENT NOTIFICATION ERROR: $e',
//       );
//     }
//   }
//
//   // ============================================================
//   // SUCCESS DIALOG
//   // ============================================================
//
//   Future<void> _showPaymentSuccessDialog(
//       Map<String, dynamic> paymentResult,
//       ) async {
//     if (!mounted) return;
//
//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return AlertDialog(
//           title: const Row(
//             children: [
//               Icon(
//                 Icons.check_circle,
//                 color: Colors.green,
//                 size: 32,
//               ),
//               SizedBox(width: 10),
//               Expanded(
//                 child: Text(
//                   'Payment Successful',
//                 ),
//               ),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Your payment has been confirmed successfully.',
//               ),
//               const SizedBox(height: 16),
//               _dialogRow(
//                 'Payment',
//                 '${PaymentService.testPaymentAmount.toStringAsFixed(0)} KHR',
//               ),
//               const SizedBox(height: 8),
//               _dialogRow(
//                 'Method',
//                 'Bakong',
//               ),
//               const SizedBox(height: 8),
//               _dialogRow(
//                 'Booking',
//                 widget.booking.bookingId?.toString() ?? '',
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 Navigator.of(context).pop(true);
//               },
//               child: const Text('DONE'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _dialogRow(
//       String title,
//       String value,
//       ) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         SizedBox(
//           width: 80,
//           child: Text(
//             title,
//             style: const TextStyle(
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//         Expanded(
//           child: Text(value),
//         ),
//       ],
//     );
//   }
//
//   // ============================================================
//   // BUILD
//   // ============================================================
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Payment'),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: isLoading
//             ? const Center(
//           child: CircularProgressIndicator(),
//         )
//             : _buildBody(),
//       ),
//     );
//   }
//
//   Widget _buildBody() {
//     if (errorMessage != null &&
//         _khqrString == null) {
//       return _buildErrorView();
//     }
//
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           _buildBookingSummary(),
//
//           const SizedBox(height: 20),
//
//           _buildPaymentSection(),
//
//           const SizedBox(height: 20),
//
//           _buildTermsSection(),
//
//           const SizedBox(height: 20),
//
//           _buildPaymentStatus(),
//
//           const SizedBox(height: 20),
//
//           _buildBottomStatus(),
//         ],
//       ),
//     );
//   }
//
//   // ============================================================
//   // BOOKING SUMMARY
//   // ============================================================
//
//   Widget _buildBookingSummary() {
//     return Card(
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: BorderSide(
//           color: Theme.of(context)
//               .dividerColor,
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment:
//           CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Booking Summary',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             _summaryRow(
//               'Booking ID',
//               widget.booking.bookingId!,
//             ),
//
//             const SizedBox(height: 10),
//
//             _summaryRow(
//               'Booking Amount',
//               '${widget.booking.totalAmount} USD',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _summaryRow(
//       String title,
//       String value,
//       ) {
//     return Row(
//       crossAxisAlignment:
//       CrossAxisAlignment.start,
//       children: [
//         Expanded(
//           child: Text(
//             title,
//             style: TextStyle(
//               color: Theme.of(context)
//                   .textTheme
//                   .bodyMedium
//                   ?.color
//                   ?.withOpacity(0.7),
//             ),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Flexible(
//           child: Text(
//             value,
//             textAlign: TextAlign.end,
//             style: const TextStyle(
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // ============================================================
//   // PAYMENT SECTION
//   // ============================================================
//
//   Widget _buildPaymentSection() {
//     return Card(
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: BorderSide(
//           color: Theme.of(context)
//               .dividerColor,
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             const Text(
//               'Bakong Payment',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//
//             const SizedBox(height: 6),
//
//             const Text(
//               'Scan this QR code using your Bakong app.',
//               textAlign: TextAlign.center,
//             ),
//
//             const SizedBox(height: 20),
//
//             _buildQr(),
//
//             const SizedBox(height: 20),
//
//             const Text(
//               'TEST PAYMENT',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12,
//               ),
//             ),
//
//             const SizedBox(height: 4),
//
//             Text(
//               '${PaymentService.testPaymentAmount.toStringAsFixed(0)} KHR',
//               style: const TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//
//             const SizedBox(height: 8),
//
//             Text(
//               'QR expires in ${_formatRemainingTime()}',
//               style: TextStyle(
//                 color: _qrExpired
//                     ? Colors.red
//                     : null,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             if (_qrExpired &&
//                 !_paymentConfirmed)
//               SizedBox(
//                 width: double.infinity,
//                 child: OutlinedButton.icon(
//                   onPressed: _regenerateQr,
//                   icon: const Icon(
//                     Icons.refresh,
//                   ),
//                   label: const Text(
//                     'Generate New QR',
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildQr() {
//     if (_isGeneratingQr) {
//       return const SizedBox(
//         height: 280,
//         child: Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }
//
//     if (_khqrString == null) {
//       return Container(
//         height: 280,
//         alignment: Alignment.center,
//         child: const Text(
//           'Unable to generate QR code.',
//         ),
//       );
//     }
//
//     return Container(
//       width: 280,
//       height: 280,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: QrImageView(
//         data: _khqrString!,
//         version: QrVersions.auto,
//         size: 256,
//         backgroundColor: Colors.white,
//         errorCorrectionLevel: QrErrorCorrectLevel.M,
//       ),
//     );
//   }
//
//   // ============================================================
//   // TERMS
//   // ============================================================
//
//   Widget _buildTermsSection() {
//     return Card(
//       elevation: 0,
//       child: CheckboxListTile(
//         value: _isTermsAgreed,
//         onChanged: _paymentConfirmed
//             ? null
//             : _onTermsChanged,
//         controlAffinity:
//         ListTileControlAffinity.leading,
//         title: const Text(
//           'I agree to make this payment.',
//         ),
//         subtitle: const Text(
//           'Payment will be detected automatically after you scan and complete the QR payment.',
//         ),
//       ),
//     );
//   }
//
//   // ============================================================
//   // PAYMENT STATUS
//   // ============================================================
//
//   Widget _buildPaymentStatus() {
//     if (_paymentConfirmed) {
//       return _statusCard(
//         icon: Icons.check_circle,
//         title: 'Payment Confirmed',
//         message:
//         'Your Bakong payment has been confirmed successfully.',
//       );
//     }
//
//     if (_paymentRateLimited) {
//       return _statusCard(
//         icon: Icons.warning_amber_rounded,
//         title: 'Payment Checking Paused',
//         message:
//         'Bakong API daily request limit has been reached. Automatic checking has been stopped.',
//       );
//     }
//
//     if (_qrExpired) {
//       return _statusCard(
//         icon: Icons.timer_off,
//         title: 'QR Code Expired',
//         message:
//         'This QR code has expired. Generate a new QR code to continue.',
//       );
//     }
//
//     if (!_isTermsAgreed) {
//       return _statusCard(
//         icon: Icons.info_outline,
//         title: 'Waiting for Payment',
//         message:
//         'Accept the payment terms, then scan the QR code. Payment detection will start automatically.',
//       );
//     }
//
//     if (_isCheckingPayment) {
//       return _statusCard(
//         icon: Icons.sync,
//         title: 'Checking Payment...',
//         message:
//         'We are automatically checking your Bakong payment.',
//       );
//     }
//
//     return _statusCard(
//       icon: Icons.hourglass_top,
//       title: 'Waiting for Payment',
//       message:
//       'Scan the QR code and complete the payment. We will automatically detect your payment.',
//     );
//   }
//
//   Widget _statusCard({
//     required IconData icon,
//     required String title,
//     required String message,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: Theme.of(context)
//               .dividerColor,
//         ),
//       ),
//       child: Row(
//         crossAxisAlignment:
//         CrossAxisAlignment.start,
//         children: [
//           Icon(
//             icon,
//             size: 28,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//               CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 Text(message),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ============================================================
//   // BOTTOM STATUS
//   // ============================================================
//
//   Widget _buildBottomStatus() {
//     if (_paymentConfirmed) {
//       return SizedBox(
//         width: double.infinity,
//         child: ElevatedButton.icon(
//           onPressed: () {
//             Navigator.of(context).pop(true);
//           },
//           icon: const Icon(
//             Icons.check,
//           ),
//           label: const Text(
//             'DONE',
//           ),
//         ),
//       );
//     }
//
//     if (_paymentRateLimited) {
//       return const SizedBox(
//         width: double.infinity,
//         child: Text(
//           'Automatic payment checking is paused because the Bakong daily API limit was reached.',
//           textAlign: TextAlign.center,
//         ),
//       );
//     }
//
//     return const Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: 8,
//       ),
//       child: Text(
//         'Scan the QR and complete the payment. We will automatically detect your payment.',
//         textAlign: TextAlign.center,
//       ),
//     );
//   }
//
//   // ============================================================
//   // ERROR VIEW
//   // ============================================================
//
//   Widget _buildErrorView() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisAlignment:
//           MainAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.error_outline,
//               size: 64,
//               color: Colors.red,
//             ),
//
//             const SizedBox(height: 16),
//
//             const Text(
//               'Unable to load payment',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//
//             const SizedBox(height: 10),
//
//             Text(
//               errorMessage ??
//                   'Something went wrong.',
//               textAlign: TextAlign.center,
//             ),
//
//             const SizedBox(height: 20),
//
//             ElevatedButton(
//               onPressed: _loadPaymentData,
//               child: const Text(
//                 'TRY AGAIN',
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
