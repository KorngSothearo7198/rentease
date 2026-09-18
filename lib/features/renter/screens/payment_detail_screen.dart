import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/payment_model.dart';
import '../../../models/property_model.dart';
import '../../../models/user_model.dart';

class PaymentDetailScreen extends StatefulWidget {
  final PaymentModel payment;

  const PaymentDetailScreen({super.key, required this.payment});

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  // ==============================================================
  // FIRESTORE
  // ==============================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==============================================================
  // DATA
  // ==============================================================

  UserModel? owner;
  UserModel? renter;
  Property? property;

  bool isLoading = true;

  // ==============================================================
  // EXPAND / COLLAPSE
  // ==============================================================

  bool _showTransaction = false;
  bool _showProfile = false;
  bool _showPaymentActivity = false;

  // ==============================================================
  // PRIMARY COLOR
  // ==============================================================

  static const Color _primary = Color(0xFF6B46C1);

  // ==============================================================
  // THEME COLORS
  // ==============================================================

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _backgroundColor(BuildContext context) {
    return _isDark(context) ? const Color(0xFF000000) : const Color(0xFFF8F5FF);
  }

  Color _cardColor(BuildContext context) {
    return _isDark(context) ? const Color(0xFF121212) : Colors.white;
  }

  Color _textPrimaryColor(BuildContext context) {
    return _isDark(context) ? Colors.white : const Color(0xFF111827);
  }

  Color _textSecondaryColor(BuildContext context) {
    return _isDark(context) ? const Color(0xFFB0B0B0) : const Color(0xFF6B7280);
  }

  Color _borderColor(BuildContext context) {
    return _isDark(context) ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
  }

  Color _inactiveColor(BuildContext context) {
    return _isDark(context) ? const Color(0xFF444444) : const Color(0xFFD1D5DB);
  }

  // ==============================================================
  // INIT
  // ==============================================================

  @override
  void initState() {
    super.initState();

    _loadPaymentInformation();
  }

  // ==============================================================
  // LOAD PAYMENT INFORMATION
  // ==============================================================

  Future<void> _loadPaymentInformation() async {
    try {
      debugPrint('');
      debugPrint('==============================================');
      debugPrint('PAYMENT DETAIL LOAD');
      debugPrint('==============================================');

      debugPrint('Payment ID : ${widget.payment.id}');

      debugPrint('Booking ID : ${widget.payment.bookingId}');

      debugPrint('Renter ID  : ${widget.payment.renterId}');

      debugPrint('Owner ID   : ${widget.payment.ownerId}');

      debugPrint('House ID   : ${widget.payment.houseId}');

      // ==========================================================
      // OWNER
      // ==========================================================

      if (widget.payment.ownerId.isNotEmpty) {
        final ownerDoc = await _firestore
            .collection('users')
            .doc(widget.payment.ownerId)
            .get();

        if (ownerDoc.exists && ownerDoc.data() != null) {
          owner = UserModel.fromMap(ownerDoc.data()!);

          debugPrint('Owner found: ${owner?.fullName}');
        }
      }

      // ==========================================================
      // RENTER
      // ==========================================================

      if (widget.payment.renterId.isNotEmpty) {
        final renterDoc = await _firestore
            .collection('users')
            .doc(widget.payment.renterId)
            .get();

        if (renterDoc.exists && renterDoc.data() != null) {
          renter = UserModel.fromMap(renterDoc.data()!);

          debugPrint('Renter found: ${renter?.fullName}');
        }
      }

      // ==========================================================
      // PROPERTY
      // ==========================================================

      if (widget.payment.houseId.isNotEmpty) {
        final propertyDoc = await _firestore
            .collection('properties')
            .doc(widget.payment.houseId)
            .get();

        if (propertyDoc.exists && propertyDoc.data() != null) {
          property = Property.fromMap(propertyDoc.data()!, propertyDoc.id);

          debugPrint('Property found: ${property?.title}');
        }
      }

      debugPrint('==============================================');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('PAYMENT DETAIL ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ==============================================================
  // PAYMENT REFERENCE
  // ==============================================================

  String _paymentReference(String id) {
    if (id.isEmpty) {
      return "Not available";
    }

    final value = id.length > 8
        ? id.substring(0, 8).toUpperCase()
        : id.toUpperCase();

    return "PAY-$value";
  }

  // ==============================================================
  // BOOKING REFERENCE
  // ==============================================================

  String _bookingReference(String id) {
    if (id.isEmpty) {
      return "Not available";
    }

    final value = id.length > 8
        ? id.substring(0, 8).toUpperCase()
        : id.toUpperCase();

    return "BOOK-$value";
  }

  // ==============================================================
  // DATE
  // ==============================================================

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} • "
        "${twoDigits(date.hour)}:"
        "${twoDigits(date.minute)}";
  }

  // ==============================================================
  // PAYMENT STATUS
  // ==============================================================

  bool get _isPaid {
    final status = widget.payment.status.toLowerCase();

    return status == "paid" ||
        status == "completed" ||
        status == "success" ||
        status == "successful";
  }

  Color get _statusColor {
    if (_isPaid) {
      return Colors.green;
    }

    if (widget.payment.status.toLowerCase() == "pending") {
      return Colors.orange;
    }

    return Colors.red;
  }

  String get _statusTitle {
    if (_isPaid) {
      return "Payment Successful";
    }

    if (widget.payment.status.toLowerCase() == "pending") {
      return "Payment Pending";
    }

    return "Payment ${widget.payment.status}";
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor(context),

      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        backgroundColor: _backgroundColor(context),

        elevation: 0,

        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _textPrimaryColor(context),
            size: 20,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          "Payment Details",
          style: TextStyle(
            color: _primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        centerTitle: true,
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),

              child: Column(
                children: [
                  // ==================================================
                  // PAYMENT STATUS
                  // ==================================================
                  _buildPaymentStatusCard(),

                  const SizedBox(height: 24),

                  // ==================================================
                  // TRANSACTION
                  // ==================================================
                  _openSectionTile(
                    title: "Open Transaction",
                    subtitle:
                        "Payment reference, booking and payment information",
                    icon: Icons.receipt_long_outlined,
                    isOpen: _showTransaction,
                    onTap: () {
                      setState(() {
                        _showTransaction = !_showTransaction;
                      });
                    },
                  ),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),

                    curve: Curves.easeInOut,

                    child: _showTransaction
                        ? _buildTransactionSection()
                        : const SizedBox.shrink(),
                  ),

                  // ==================================================
                  // PROFILE
                  // ==================================================
                  _openSectionTile(
                    title: "Open Profile",
                    subtitle: "Owner, renter and property information",
                    icon: Icons.person_outline_rounded,
                    isOpen: _showProfile,
                    onTap: () {
                      setState(() {
                        _showProfile = !_showProfile;
                      });
                    },
                  ),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),

                    curve: Curves.easeInOut,

                    child: _showProfile
                        ? _buildProfileSection()
                        : const SizedBox.shrink(),
                  ),

                  // ==================================================
                  // PAYMENT ACTIVITY
                  // ==================================================
                  _openSectionTile(
                    title: "Open Payment Activity",
                    subtitle: "Payment status and transaction timeline",
                    icon: Icons.timeline_rounded,
                    isOpen: _showPaymentActivity,
                    onTap: () {
                      setState(() {
                        _showPaymentActivity = !_showPaymentActivity;
                      });
                    },
                  ),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),

                    curve: Curves.easeInOut,

                    child: _showPaymentActivity
                        ? _buildPaymentActivitySection()
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 12),

                  // ==================================================
                  // BILLING
                  // ==================================================
                  _sectionTitle("BILLING SUMMARY"),

                  const SizedBox(height: 12),

                  _buildBillingSummary(),

                  const SizedBox(height: 28),

                  // ==================================================
                  // RECEIPT
                  // ==================================================
                  SizedBox(
                    width: double.infinity,
                    height: 54,

                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showReceiptMessage(context);
                      },

                      icon: const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                      ),

                      label: const Text(
                        "Download Receipt",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isDark(context)
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFF1E293B),

                        foregroundColor: Colors.white,

                        elevation: 0,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // SUPPORT
                  // ==================================================
                  SizedBox(
                    width: double.infinity,
                    height: 54,

                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showSupportMessage(context);
                      },

                      icon: Icon(
                        Icons.headset_mic_outlined,
                        color: _textPrimaryColor(context),
                      ),

                      label: Text(
                        "Contact Support",
                        style: TextStyle(
                          fontSize: 16,
                          color: _textPrimaryColor(context),
                        ),
                      ),

                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textPrimaryColor(context),

                        side: BorderSide(color: _borderColor(context)),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // SECURITY
                  // ==================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: _textSecondaryColor(context),
                      ),

                      const SizedBox(width: 6),

                      Text(
                        "Secured by RentEase",
                        style: TextStyle(
                          color: _textSecondaryColor(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // ==============================================================
  // PAYMENT STATUS CARD
  // ==============================================================

  Widget _buildPaymentStatusCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: _cardColor(context),

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark(context) ? 0.25 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,

            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.10),

              shape: BoxShape.circle,
            ),

            child: Icon(
              _isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,

              color: _statusColor,

              size: 44,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            _statusTitle,

            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: _textPrimaryColor(context),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _isPaid
                ? "Your rental payment has been confirmed."
                : "Your payment is currently "
                      "${widget.payment.status.toLowerCase()}.",

            textAlign: TextAlign.center,

            style: TextStyle(fontSize: 14, color: _textSecondaryColor(context)),
          ),

          const SizedBox(height: 22),

          Text(
            "\$${widget.payment.amount.toStringAsFixed(2)}",

            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            "USD",

            style: TextStyle(
              fontSize: 13,
              color: _textSecondaryColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),

            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.08),

              borderRadius: BorderRadius.circular(20),
            ),

            child: Text(
              widget.payment.status.toUpperCase(),

              style: TextStyle(
                color: _statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // OPEN SECTION TILE
  // ==============================================================

  Widget _openSectionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isOpen,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: _cardColor(context),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: isOpen ? _primary.withOpacity(0.25) : _borderColor(context),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark(context) ? 0.20 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          borderRadius: BorderRadius.circular(18),

          onTap: onTap,

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,

                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.08),

                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: Icon(icon, color: _primary, size: 22),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        title,

                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textPrimaryColor(context),
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        subtitle,

                        style: TextStyle(
                          fontSize: 12,
                          color: _textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,

                  duration: const Duration(milliseconds: 200),

                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,

                    color: _textSecondaryColor(context),

                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // TRANSACTION SECTION
  // ==============================================================

  Widget _buildTransactionSection() {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: _cardColor(context),

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark(context) ? 0.25 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        children: [
          _infoRow(
            "PAYMENT REFERENCE",
            _paymentReference(widget.payment.id),
            icon: Icons.receipt_long_outlined,
          ),

          Divider(height: 24, color: _borderColor(context)),

          _infoRow(
            "BOOKING REFERENCE",
            _bookingReference(widget.payment.bookingId),
            icon: Icons.bookmark_border_rounded,
          ),

          Divider(height: 24, color: _borderColor(context)),

          _infoRow(
            "PAYMENT METHOD",
            widget.payment.paymentMethod,
            icon: Icons.payment_outlined,
          ),

          Divider(height: 24, color: _borderColor(context)),

          _infoRow(
            "STATUS",
            widget.payment.status,
            icon: Icons.check_circle_outline_rounded,
            valueColor: _statusColor,
          ),

          Divider(height: 24, color: _borderColor(context)),

          _infoRow(
            "DATE & TIME",
            _formatDate(widget.payment.createdAt),
            icon: Icons.calendar_today_outlined,
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // PROFILE SECTION
  // ==============================================================

  Widget _buildProfileSection() {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: _cardColor(context),

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark(context) ? 0.25 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        children: [
          _profileRow(
            icon: Icons.home_work_outlined,
            label: "PROPERTY",
            value: property?.title ?? "Loading...",
          ),

          Divider(height: 24, color: _borderColor(context)),

          _profileRow(
            icon: Icons.person_outline_rounded,
            label: "OWNER",
            value: owner?.fullName ?? "Loading...",
          ),

          Divider(height: 24, color: _borderColor(context)),

          _profileRow(
            icon: Icons.person_outline_rounded,
            label: "RENTER",
            value: renter?.fullName ?? "Loading...",
          ),

          if (property?.location != null && property!.location.isNotEmpty) ...[
            Divider(height: 24, color: _borderColor(context)),

            _profileRow(
              icon: Icons.location_on_outlined,
              label: "LOCATION",
              value: property!.location,
            ),
          ],
        ],
      ),
    );
  }

  // ==============================================================
  // PROFILE ROW
  // ==============================================================

  Widget _profileRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        Container(
          width: 42,
          height: 42,

          decoration: BoxDecoration(
            color: _primary.withOpacity(0.08),

            borderRadius: BorderRadius.circular(12),
          ),

          child: Icon(icon, color: _primary, size: 20),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                label,

                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _textSecondaryColor(context),
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value.isEmpty ? "Not available" : value,

                maxLines: 2,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimaryColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // PAYMENT ACTIVITY
  // ==============================================================

  Widget _buildPaymentActivitySection() {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: _cardColor(context),

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark(context) ? 0.25 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        children: [
          _processStep(
            title: "Payment Completed",
            time: _formatDate(widget.payment.createdAt),
            isActive: _isPaid,
            isLast: false,
          ),

          _processStep(
            title: "Payment Initiated",
            time: _formatDate(widget.payment.createdAt),
            isActive: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // SECTION TITLE
  // ==============================================================

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,

      child: Text(
        title,

        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _textSecondaryColor(context),
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ==============================================================
  // INFO ROW
  // ==============================================================

  Widget _infoRow(
    String label,
    String value, {
    IconData? icon,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          width: 38,
          height: 38,

          decoration: BoxDecoration(
            color: _primary.withOpacity(0.08),

            borderRadius: BorderRadius.circular(10),
          ),

          child: Icon(icon ?? Icons.info_outline, size: 19, color: _primary),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                label,

                style: TextStyle(
                  fontSize: 10,
                  color: _textSecondaryColor(context),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value.isEmpty ? "Not available" : value,

                maxLines: 3,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? _textPrimaryColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // BILLING SUMMARY
  // ==============================================================

  Widget _buildBillingSummary() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: _cardColor(context),

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark(context) ? 0.25 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        children: [
          _billingRow(
            "Rental Payment",
            "\$${widget.payment.amount.toStringAsFixed(2)}",
          ),

          const SizedBox(height: 8),

          Divider(color: _borderColor(context)),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                "Total Paid",

                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textPrimaryColor(context),
                ),
              ),

              Row(
                children: [
                  if (_isPaid)
                    const Icon(
                      Icons.verified_rounded,
                      color: Colors.green,
                      size: 20,
                    ),

                  if (_isPaid) const SizedBox(width: 6),

                  Text(
                    "\$${widget.payment.amount.toStringAsFixed(2)}",

                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // BILLING ROW
  // ==============================================================

  Widget _billingRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        Text(
          label,

          style: TextStyle(color: _textSecondaryColor(context), fontSize: 14),
        ),

        Text(
          amount,

          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: _textPrimaryColor(context),
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // PROCESS STEP
  // ==============================================================

  Widget _processStep({
    required String title,
    required String time,
    required bool isActive,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,

              decoration: BoxDecoration(
                color: isActive ? _primary : _inactiveColor(context),

                shape: BoxShape.circle,
              ),
            ),

            if (!isLast)
              Container(width: 2, height: 42, color: _inactiveColor(context)),
          ],
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: _textPrimaryColor(context),
                ),
              ),

              const SizedBox(height: 3),

              Text(
                time,

                style: TextStyle(
                  color: _textSecondaryColor(context),
                  fontSize: 13,
                ),
              ),

              if (!isLast) const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // RECEIPT
  // ==============================================================

  void _showReceiptMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Receipt download will be available soon.")),
    );
  }

  // ==============================================================
  // SUPPORT
  // ==============================================================

  void _showSupportMessage(BuildContext context) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardColor(context),

          title: Text(
            "Contact Support",
            style: TextStyle(color: _textPrimaryColor(context)),
          ),

          content: Text(
            "Please contact RentEase support if you have "
            "any problem with this payment.",

            style: TextStyle(color: _textSecondaryColor(context)),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text("OK", style: TextStyle(color: _primary)),
            ),
          ],
        );
      },
    );
  }
}
