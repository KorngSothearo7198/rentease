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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final PaymentService paymentService = PaymentService();

  Property? property;
  UserModel? owner;
  UserModel? renter;

  bool isLoading = true;

  bool _isGeneratingQr = true;

  bool _isPaying = false;

  bool _isCheckingPayment = false;

  bool _isTermsAgreed = false;

  bool _paymentConfirmed = false;

  String? errorMessage;

  String? _khqrString;

  String? _khqrMd5;

  DateTime? _qrExpiresAt;

  Timer? _countdownTimer;

  Duration _remainingTime = const Duration(minutes: 2);

  static const Color _primary = Color(0xFF4F46E5);

  static const Color _primaryDark = Color(0xFF3730A3);

  static const Color _bg = Color(0xFFF8FAFC);

  static const Color _card = Colors.white;

  static const Color _textPrimary = Color(0xFF0F172A);

  static const Color _textSecondary = Color(0xFF64748B);

  static const Color _border = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();

    _loadPaymentData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();

    super.dispose();
  }

  Future<void> _loadPaymentData() async {
    try {
      final propertyDoc = await _firestore
          .collection('properties')
          .doc(widget.booking.houseId)
          .get();

      if (propertyDoc.exists && propertyDoc.data() != null) {
        property = Property.fromMap(propertyDoc.data()!, propertyDoc.id);
      }

      final ownerDoc = await _firestore
          .collection('users')
          .doc(widget.booking.ownerId)
          .get();

      if (ownerDoc.exists && ownerDoc.data() != null) {
        owner = UserModel.fromMap(ownerDoc.data()!);
      }

      final renterDoc = await _firestore
          .collection('users')
          .doc(widget.booking.renterId)
          .get();

      if (renterDoc.exists && renterDoc.data() != null) {
        renter = UserModel.fromMap(renterDoc.data()!);
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      await _generateBakongQr();
    } catch (e) {
      debugPrint('LOAD PAYMENT DATA ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        _isGeneratingQr = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _generateBakongQr() async {
    try {
      if (!mounted) return;

      setState(() {
        _isGeneratingQr = true;
        errorMessage = null;

        // Reset payment state when creating
        // a new QR.
        _paymentConfirmed = false;
        _isCheckingPayment = false;
        _isPaying = false;
      });

      // ========================================================
      // TEST PAYMENT
      // ========================================================
      //
      // IMPORTANT:
      //
      // Bakong test payment = 100 KHR
      //
      // Real booking amount remains USD.
      //
      // Example:
      //
      // Test payment = 100 KHR
      // Booking amount = $2.22 USD
      //
      // ========================================================

      const double testPaymentAmount = 100;

      if (testPaymentAmount <= 0) {
        throw Exception('Invalid test payment amount.');
      }

      // ========================================================
      // QR EXPIRATION
      // ========================================================

      final expireAt = DateTime.now().add(const Duration(minutes: 2));

      // ========================================================
      // GENERATE KHQR
      // ========================================================

      final individualInfo = IndividualInfo(
        bakongAccountId: PaymentService.bakongAccount,

        merchantName: 'RentEase',

        accountInformation: PaymentService.bakongAccount,

        // Test payment only.
        amount: testPaymentAmount,

        // Test currency.
        currency: KhqrCurrency.khr,

        expirationTimestamp: expireAt.millisecondsSinceEpoch,
      );

      final result = KhqrSdk.generateIndividual(individualInfo);

      // ========================================================
      // CHECK RESULT
      // ========================================================

      if (!result.isSuccess) {
        throw Exception(result.status.message);
      }

      if (result.data == null) {
        throw Exception('Bakong did not return KHQR data.');
      }

      // ========================================================
      // GET QR STRING
      // ========================================================

      final qr = result.data!.qr;

      if (qr.isEmpty) {
        throw Exception('Generated KHQR is empty.');
      }

      // ========================================================
      // GENERATE MD5
      // ========================================================

      final md5Hash = paymentService.generateKhqrMd5(qr);

      if (md5Hash.isEmpty) {
        throw Exception('Failed to generate KHQR MD5.');
      }

      if (!mounted) return;

      // ========================================================
      // SAVE QR STATE
      // ========================================================

      setState(() {
        _khqrString = qr;

        _khqrMd5 = md5Hash;

        _qrExpiresAt = expireAt;

        _remainingTime = const Duration(minutes: 2);

        _isGeneratingQr = false;
      });

      // ========================================================
      // START QR COUNTDOWN ONLY
      // ========================================================
      //
      // IMPORTANT:
      //
      // This timer DOES NOT call Bakong.
      //
      // It only counts down QR expiration.
      //
      // ========================================================

      _startCountdown();

      // ========================================================
      // DEBUG
      // ========================================================

      debugPrint('====================================');

      debugPrint('REAL BAKONG KHQR GENERATED');

      debugPrint('====================================');

      debugPrint('QR LENGTH: ${qr.length}');

      debugPrint('MD5: $md5Hash');

      debugPrint('TEST PAYMENT: 100 KHR');

      debugPrint(
        'REAL BOOKING AMOUNT: '
        '${widget.booking.totalAmount} USD',
      );

      debugPrint(
        'ACCOUNT: '
        '${PaymentService.bakongAccount}',
      );

      debugPrint('====================================');
    } catch (e) {
      debugPrint('GENERATE KHQR ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isGeneratingQr = false;

        errorMessage = 'Unable to generate Bakong QR.\n$e';
      });
    }
  }

  // ============================================================
  // QR COUNTDOWN
  // ============================================================

  void _startCountdown() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      if (_qrExpiresAt == null) {
        return;
      }

      final difference = _qrExpiresAt!.difference(DateTime.now());

      if (difference.isNegative || difference.inSeconds <= 0) {
        _countdownTimer?.cancel();

        setState(() {
          _remainingTime = Duration.zero;
        });

        return;
      }

      setState(() {
        _remainingTime = difference;
      });
    });
  }

  // ============================================================
  // CHECK PAYMENT
  // ============================================================
  //
  // IMPORTANT:
  //
  // This function runs ONLY when the user
  // presses "Check Payment".
  //
  // There is NO automatic polling.
  //
  // ============================================================

  Future<void> _onPayNow() async {
    // Prevent double tap.
    if (_isPaying || _isCheckingPayment) {
      return;
    }

    // Already confirmed.
    if (_paymentConfirmed) {
      return;
    }

    // ==========================================================
    // TERMS
    // ==========================================================

    if (!_isTermsAgreed) {
      _showErrorDialog(
        title: 'Payment Terms',
        message:
            'Please agree to the payment terms '
            'and rental agreement before continuing.',
      );

      return;
    }

    // ==========================================================
    // MD5
    // ==========================================================

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

    // ==========================================================
    // QR EXPIRED
    // ==========================================================

    if (_isQrExpired) {
      _showErrorDialog(
        title: 'QR Expired',
        message:
            'This Bakong QR has expired. '
            'Please generate a new QR code.',
      );

      return;
    }

    // ==========================================================
    // BOOKING ID
    // ==========================================================

    final bookingId = widget.booking.bookingId;

    if (bookingId == null || bookingId.trim().isEmpty) {
      _showErrorDialog(
        title: 'Invalid Booking',
        message: 'Booking ID is missing.',
      );

      return;
    }

    // ==========================================================
    // START MANUAL CHECK
    // ==========================================================

    setState(() {
      _isCheckingPayment = true;
      _isPaying = true;
    });

    _showCheckingPaymentDialog();

    try {
      debugPrint('');

      debugPrint('====================================');

      debugPrint('MANUAL BAKONG PAYMENT CHECK');

      debugPrint('====================================');

      debugPrint('Booking ID: $bookingId');

      debugPrint('MD5: $md5');

      debugPrint(
        'Test Amount: '
        '${PaymentService.testPaymentAmount} '
        '${PaymentService.testPaymentCurrency}',
      );

      debugPrint(
        'Real Booking Amount: '
        '${widget.booking.totalAmount} USD',
      );

      debugPrint('====================================');

      // ========================================================
      // ONE PAYMENT CALL
      // ========================================================
      //
      // PaymentService.completePayment()
      //
      // will:
      //
      // 1. Verify Bakong
      // 2. Create payment document
      // 3. Update booking
      // 4. Notify owner
      //
      // ========================================================

      final result = await paymentService.completePayment(
        bookingId: bookingId,
        paymentMethod: 'Bakong',
        khqrMd5: md5,
      );

      if (!mounted) return;

      // ========================================================
      // PAYMENT SUCCESS
      // ========================================================

      _paymentConfirmed = true;

      _closeCheckingDialog();

      setState(() {
        _isPaying = false;
      });

      debugPrint('');

      debugPrint('====================================');

      debugPrint('PAYMENT SUCCESS');

      debugPrint('====================================');

      debugPrint(
        'Payment ID: '
        '${result['paymentId']}',
      );

      debugPrint(
        'Booking Amount: '
        '${result['bookingAmount']} USD',
      );

      debugPrint(
        'Test Payment: '
        '${result['amount']} '
        '${result['currency']}',
      );

      // ========================================================
      // TELEGRAM
      // ========================================================

      try {
        await _notifyPaymentSuccess();
      } catch (e) {
        debugPrint('Telegram notification failed: $e');
      }

      if (!mounted) return;

      // ========================================================
      // SUCCESS DIALOG
      // ========================================================

      _showPaymentSuccessDialog();
    } catch (e, stackTrace) {
      debugPrint('');

      debugPrint('====================================');

      debugPrint('MANUAL PAYMENT NOT CONFIRMED');

      debugPrint('====================================');

      debugPrint(e.toString());

      debugPrint(stackTrace.toString());

      if (!mounted) return;

      _closeCheckingDialog();

      setState(() {
        _isPaying = false;
      });

      _showPaymentFailedDialog(e);
    } finally {
      _isCheckingPayment = false;
    }
  }

  // ============================================================
  // TELEGRAM NOTIFICATION
  // ============================================================

  Future<void> _notifyPaymentSuccess() async {
    /*
     * Replace this with your owner's
     * real Telegram chat ID.
     */

    const ownerChatId = '987654321';

    final message =
        '''
💰 ការទូទាត់ប្រាក់បានជោគជ័យ

📋 លេខ Booking:
${widget.booking.bookingId}

👤 អ្នកជួល
ឈ្មោះ: ${renter?.fullName ?? 'មិនមាន'}
ទូរស័ព្ទ: ${renter?.phone ?? 'មិនមាន'}

🏠 ផ្ទះ/បន្ទប់
${property?.title ?? 'មិនមាន'}

💵 ចំនួនទឹកប្រាក់
\$${widget.booking.totalAmount.toStringAsFixed(2)} USD

💳 វិធីទូទាត់
Bakong

💰 Test Payment
100 KHR

ស្ថានភាព:
បានទូទាត់រួចរាល់ ✅
''';

    try {
      final success = await TelegramService.sendMessage(
        chatId: ownerChatId,
        message: message,
      );

      if (success) {
        debugPrint('Telegram notification sent.');
      } else {
        debugPrint('Telegram notification failed.');
      }
    } catch (e) {
      debugPrint('Telegram error: $e');
    }
  }

  // ============================================================
  // QR EXPIRED
  // ============================================================

  bool get _isQrExpired {
    if (_qrExpiresAt == null) {
      return true;
    }

    return DateTime.now().isAfter(_qrExpiresAt!);
  }

  // ============================================================
  // TIME FORMAT
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
  // REGENERATE QR
  // ============================================================

  Future<void> _regenerateQr() async {
    await _generateBakongQr();
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

  void _showCheckingPaymentDialog() {
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
  // SUCCESS DIALOG
  // ============================================================

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                'Your Bakong payment has been successfully verified and recorded.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

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
                      'Amount Paid',
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '\$${widget.booking.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: _primary,
                      ),
                    ),

                    const SizedBox(height: 2),

                    const Text(
                      'USD',
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

              _successInfoRow('Booking ID', widget.booking.bookingId ?? 'N/A'),

              _successInfoRow('Payment Method', 'Bakong'),

              _successInfoRow('Status', 'Paid', valueColor: Colors.green),
            ],
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

  void _showPaymentFailedDialog(Object error) {
    String message = error.toString();

    if (message.startsWith('Exception:')) {
      message = message.replaceFirst('Exception:', '').trim();
    }

    final lowerMessage = message.toLowerCase();

    // ==========================================================
    // DAILY RATE LIMIT
    // ==========================================================

    final bool isRateLimited =
        lowerMessage.contains('daily request limit') ||
        lowerMessage.contains('rate limit') ||
        lowerMessage.contains('try again tomorrow');

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
                  color: isRateLimited
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRateLimited
                      ? Icons.hourglass_empty_rounded
                      : Icons.close_rounded,
                  size: 42,
                  color: isRateLimited ? Colors.orange : Colors.red,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                isRateLimited
                    ? 'Verification Temporarily Unavailable'
                    : 'Payment Not Confirmed',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                isRateLimited
                    ? 'Bakong verification cannot be completed right now because the Bakong API daily request limit has been reached.\n\nThis does not necessarily mean your payment failed. Please try again later.'
                    : message,
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

          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 22 : 15,
              fontWeight: FontWeight.w700,
              color: isTotal ? _primary : _textPrimary,
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
  // BAKONG QR WIDGET
  // ============================================================

  Widget _buildBakongQr() {
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

    if (_khqrString == null || _khqrString!.isEmpty) {
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: QrImageView(
        data: _khqrString!,
        version: QrVersions.auto,
        size: 220,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (isLoading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (errorMessage != null) {
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
                  errorMessage!,
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

    // ==========================================================
    // DATA ERROR
    // ==========================================================

    if (property == null || owner == null || renter == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: Text('Failed to load payment data.')),
      );
    }

    // ==========================================================
    // MAIN SCREEN
    // ==========================================================

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
                  // ==================================================
                  // PROPERTY
                  // ==================================================
                  Container(
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
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              property!.imageUrl,
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
                        ),

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
                                  property!.category.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _primary,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                property!.title,
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
                                property!.location,
                              ),

                              _infoRow(
                                Icons.bed_outlined,
                                'Bedrooms',
                                '${property!.bedrooms}',
                              ),

                              _infoRow(
                                Icons.bathtub_outlined,
                                'Bathrooms',
                                '${property!.bathrooms}',
                              ),

                              _infoRow(
                                Icons.person_outline_rounded,
                                'Owner',
                                owner!.fullName,
                              ),

                              _infoRow(
                                Icons.phone_outlined,
                                'Phone',
                                owner!.phone.isEmpty
                                    ? 'Not provided'
                                    : owner!.phone,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // PAYMENT SUMMARY
                  // ==================================================
                  Container(
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
                          'Total Due',
                          '\$${widget.booking.totalAmount.toStringAsFixed(2)}',
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // BOOKING META
                  // ==================================================

                  // Row(
                  //   children: [
                  //     _metaChip(
                  //       'Status',
                  //       widget.booking.paymentStatus ?? 'Pending',
                  //     ),
                  //
                  //     const SizedBox(width: 12),
                  //
                  //     _metaChip('Booking ID', widget.booking.bookingId ?? '—'),
                  //   ],
                  // ),

                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: _firestore
                              .collection('bookings')
                              .doc(widget.booking.bookingId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return _metaChip('Status', 'Error');
                            }

                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return _metaChip('Status', 'Loading...');
                            }

                            final data = snapshot.data!.data();

                            final paymentStatus =
                                data?['paymentStatus']?.toString() ?? 'Pending';

                            return _metaChip('Status', paymentStatus);
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _metaChip(
                          'Booking ID',
                          widget.booking.bookingId ?? '—',
                        ),
                      ),
                    ],
                  ),



                  const SizedBox(height: 12),

                  Row(children: [_metaChip('Renter', renter!.fullName)]),

                  const SizedBox(height: 24),

                  // ==================================================
                  // BAKONG QR
                  // ==================================================
                  Container(
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
                          style: TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 20),

                        _buildBakongQr(),

                        const SizedBox(height: 20),

                        Text(
                          '\$${widget.booking.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: _primary,
                          ),
                        ),

                        const Text(
                          'USD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ==========================================
                        // COUNTDOWN
                        // ==========================================
                        if (!_isQrExpired)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 18,
                                  color: _primary,
                                ),

                                const SizedBox(width: 8),

                                Text(
                                  'QR expires in $_remainingTimeText',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // ==========================================
                        // EXPIRED
                        // ==========================================
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
                                    Icon(
                                      Icons.error_outline,
                                      size: 18,
                                      color: Colors.red,
                                    ),

                                    SizedBox(width: 10),

                                    Expanded(
                                      child: Text(
                                        'This QR code has expired.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red,
                                        ),
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

                        // ==========================================
                        // MANUAL CHECK INFORMATION
                        // ==========================================
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
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: _primary,
                              ),

                              SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  'Scan the QR and complete your payment first. After payment is completed, press "Check Payment" to verify the transaction.',
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
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // TERMS
                  // ==================================================
                  GestureDetector(
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
                            color: _isTermsAgreed
                                ? _primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _isTermsAgreed ? _primary : _border,
                              width: 1.8,
                            ),
                          ),
                          child: _isTermsAgreed
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                )
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
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ========================================================
          // BOTTOM BUTTON
          // ========================================================
          Container(
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
                // ==================================================
                // MANUAL ONLY
                // ==================================================
                onPressed:
                    _isPaying ||
                        _isCheckingPayment ||
                        _isGeneratingQr ||
                        _isQrExpired ||
                        _paymentConfirmed
                    ? null
                    : _onPayNow,

                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  disabledBackgroundColor: _primary.withOpacity(0.45),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                child: _isPaying || _isCheckingPayment
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _paymentConfirmed
                            ? 'Payment Confirmed'
                            : 'Check Payment',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
