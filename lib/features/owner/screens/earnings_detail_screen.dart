import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EarningsDetailScreen extends StatefulWidget {
  final Map<String, dynamic> payment;

  const EarningsDetailScreen({super.key, required this.payment});

  @override
  State<EarningsDetailScreen> createState() => _EarningsDetailScreenState();
}

class _EarningsDetailScreenState extends State<EarningsDetailScreen> {
  static const Color _primary = Color(0xFF4F46E5);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _card = Colors.white;
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _success = Color(0xFF059669);

  String _bookingTitle = 'Loading...';
  String _houseTitle = 'Loading...';
  String _renterName = 'Loading...';
  String _ownerName = 'Loading...';
  bool _loadingDetails = true;

  // Expand / collapse sections
  bool _showBooking = true;
  bool _showParticipants = false;
  bool _showPaymentIds = false;

  @override
  void initState() {
    super.initState();
    _loadRelatedInformation();
  }

  Future<void> _loadRelatedInformation() async {
    try {
      final String bookingId = widget.payment['bookingId']?.toString() ?? '';
      String houseId = widget.payment['houseId']?.toString() ?? '';
      String renterId = widget.payment['renterId']?.toString() ?? '';
      String ownerId = widget.payment['ownerId']?.toString() ?? '';

      if (bookingId.isNotEmpty) {
        final bookingDoc = await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .get();

        if (bookingDoc.exists && bookingDoc.data() != null) {
          final bookingData = bookingDoc.data()!;

          if (houseId.isEmpty) {
            houseId = bookingData['houseId']?.toString() ?? '';
          }
          if (renterId.isEmpty) {
            renterId = bookingData['renterId']?.toString() ?? '';
          }
          if (ownerId.isEmpty) {
            ownerId = bookingData['ownerId']?.toString() ?? '';
          }

          final String bookingTitle =
              bookingData['bookingTitle']?.toString() ??
              bookingData['title']?.toString() ??
              '';

          if (bookingTitle.isNotEmpty) {
            _bookingTitle = bookingTitle;
          }
        }
      }

      if (houseId.isNotEmpty) {
        final propertyDoc = await FirebaseFirestore.instance
            .collection('properties')
            .doc(houseId)
            .get();

        if (propertyDoc.exists && propertyDoc.data() != null) {
          final propertyTitle = propertyDoc.data()!['title']?.toString() ?? '';

          if (propertyTitle.isNotEmpty) {
            _houseTitle = propertyTitle;
            if (_bookingTitle == 'Loading...' || _bookingTitle.isEmpty) {
              _bookingTitle = propertyTitle;
            }
          }
        } else {
          _houseTitle = 'Property not found';
        }
      } else {
        _houseTitle = 'No house ID';
      }

      if (renterId.isNotEmpty) {
        final renterDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(renterId)
            .get();

        if (renterDoc.exists && renterDoc.data() != null) {
          final d = renterDoc.data()!;
          _renterName =
              d['fullName']?.toString() ?? d['name']?.toString() ?? 'Unknown';
        } else {
          _renterName = 'Renter not found';
        }
      } else {
        _renterName = 'No renter ID';
      }

      if (ownerId.isNotEmpty) {
        final ownerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerId)
            .get();

        if (ownerDoc.exists && ownerDoc.data() != null) {
          final d = ownerDoc.data()!;
          _ownerName =
              d['fullName']?.toString() ?? d['name']?.toString() ?? 'Unknown';
        } else {
          _ownerName = 'Owner not found';
        }
      } else {
        _ownerName = 'No owner ID';
      }
    } catch (e) {
      debugPrint('❌ Earnings detail loading error: $e');
      _bookingTitle = 'Unable to load';
      _houseTitle = 'Unable to load';
      _renterName = 'Unable to load';
      _ownerName = 'Unable to load';
    }

    if (!mounted) return;
    setState(() => _loadingDetails = false);
  }

  @override
  Widget build(BuildContext context) {
    final double bookingAmount = _toDouble(widget.payment['bookingAmount']);
    final double fallbackAmount = _toDouble(widget.payment['totalAmount']);
    final double displayAmount = bookingAmount > 0
        ? bookingAmount
        : fallbackAmount;

    final double transactionAmount = _toDouble(widget.payment['amount']);
    final String transactionCurrency =
        widget.payment['currency']?.toString() ?? 'KHR';
    final String bookingCurrency =
        widget.payment['bookingCurrency']?.toString() ?? 'USD';

    final String status = widget.payment['status']?.toString() ?? 'Unknown';
    final String paymentMethod =
        widget.payment['paymentMethod']?.toString() ?? 'Unknown';
    final String paymentId = widget.payment['paymentId']?.toString() ?? '—';
    final String bookingId = widget.payment['bookingId']?.toString() ?? '—';
    final String houseId = widget.payment['houseId']?.toString() ?? '—';
    final String renterId = widget.payment['renterId']?.toString() ?? '—';
    final String ownerId = widget.payment['ownerId']?.toString() ?? '—';

    final Timestamp? timestamp = widget.payment['createdAt'] is Timestamp
        ? widget.payment['createdAt'] as Timestamp
        : null;
    final DateTime? createdAt = timestamp?.toDate();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Earning Details',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          children: [
            // ── Hero amount (horizontal style) ─────────────────
            _buildAmountCard(
              amount: displayAmount,
              currency: bookingCurrency,
              status: status,
            ),

            const SizedBox(height: 16),

            // ── Stats grid (no duplicates) ─────────────────────
            _buildStatsGrid(
              status: status,
              paymentMethod: paymentMethod,
              date: createdAt != null ? _formatDate(createdAt) : '—',
              currency: bookingCurrency,
            ),

            const SizedBox(height: 20),

            // ── Booking header (single place for titles) ───────
            if (_loadingDetails) _buildLoadingCard() else _buildBookingHeader(),

            const SizedBox(height: 16),

            // ── Expandable: Booking & Property ─────────────────
            _expandableSection(
              title: 'Booking & Property',
              icon: Icons.home_work_rounded,
              isOpen: _showBooking,
              onToggle: () => setState(() => _showBooking = !_showBooking),
              child: Column(
                children: [
                  _horizontalItem(
                    icon: Icons.bookmark_rounded,
                    label: 'Booking',
                    value: _bookingTitle,
                  ),
                  // const SizedBox(height: 10),
                  // _horizontalItem(
                  //   icon: Icons.home_outlined,
                  //   label: 'Property',
                  //   value: _houseTitle,
                  // ),
                  // const SizedBox(height: 10),
                  // _horizontalItem(
                  //   icon: Icons.tag_rounded,
                  //   label: 'Booking ID',
                  //   value: _shortId(bookingId),
                  // ),
                  // const SizedBox(height: 10),
                  // _horizontalItem(
                  //   icon: Icons.tag_rounded,
                  //   label: 'House ID',
                  //   value: _shortId(houseId),
                  // ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Expandable: Participants ───────────────────────
            _expandableSection(
              title: 'Participants',
              icon: Icons.people_outline_rounded,
              isOpen: _showParticipants,
              onToggle: () =>
                  setState(() => _showParticipants = !_showParticipants),
              child: Column(
                children: [
                  _horizontalItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Renter',
                    value: _renterName,
                  ),
                  // const SizedBox(height: 10),
                  // _horizontalItem(
                  //   icon: Icons.badge_outlined,
                  //   label: 'Renter ID',
                  //   value: _shortId(renterId),
                  // ),
                  const SizedBox(height: 10),
                  _horizontalItem(
                    icon: Icons.business_center_outlined,
                    label: 'Owner',
                    value: _ownerName,
                  ),
                  // const SizedBox(height: 10),
                  // _horizontalItem(
                  //   icon: Icons.badge_outlined,
                  //   label: 'Owner ID',
                  //   value: _shortId(ownerId),
                  // ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Expandable: Payment IDs & transaction ──────────
            _expandableSection(
              title: 'Payment & Transaction',
              icon: Icons.receipt_long_rounded,
              isOpen: _showPaymentIds,
              onToggle: () =>
                  setState(() => _showPaymentIds = !_showPaymentIds),
              child: Column(
                children: [
                  _horizontalItem(
                    icon: Icons.payments_outlined,
                    label: 'Booking Amount',
                    value: _formatMoney(displayAmount, bookingCurrency),
                    valueColor: _primary,
                    bold: true,
                  ),
                  if (transactionAmount > 0 &&
                      (transactionCurrency.toUpperCase() != bookingCurrency.toUpperCase() ||
                          (transactionAmount - displayAmount).abs() > 0.01)) ...[
                    const SizedBox(height: 10),
                    _horizontalItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Transaction',
                      value: _formatMoney(
                        bookingAmount,
                        bookingCurrency,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  // _horizontalItem(
                  //   icon: Icons.receipt_outlined,
                  //   label: 'Payment ID',
                  //   value: _shortId(paymentId),
                  // ),
                  const SizedBox(height: 10),
                  _horizontalItem(
                    icon: Icons.wallet_outlined,
                    label: 'Method',
                    value: paymentMethod,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero amount (horizontal layout) ──────────────────────────

  Widget _buildAmountCard({
    required double amount,
    required String currency,
    required String status,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Earning',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMoney(amount, currency),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status.toLowerCase() == 'paid'
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 15,
                ),
                const SizedBox(width: 5),
                Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2x2 Stats grid ───────────────────────────────────────────

  Widget _buildStatsGrid({
    required String status,
    required String paymentMethod,
    required String date,
    required String currency,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _statTile(
          icon: Icons.check_circle_outline_rounded,
          label: 'Status',
          value: status,
          valueColor: _statusColor(status),
        ),
        _statTile(
          icon: Icons.wallet_outlined,
          label: 'Method',
          value: paymentMethod,
        ),
        _statTile(icon: Icons.access_time_rounded, label: 'Date', value: date),
        _statTile(
          icon: Icons.attach_money_rounded,
          label: 'Currency',
          value: currency.toUpperCase(),
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: valueColor ?? _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Booking header (titles only once) ────────────────────────

  Widget _buildBookingHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: _primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bookingTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_houseTitle != _bookingTitle) ...[
                  const SizedBox(height: 3),
                  Text(
                    _houseTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
          ),
          SizedBox(width: 12),
          Text(
            'Loading details...',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Expandable section with animation ────────────────────────

  Widget _expandableSection({
    required String title,
    required IconData icon,
    required bool isOpen,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: _primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
            crossFadeState: isOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 280),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  // ── Horizontal detail row ────────────────────────────────────

  Widget _horizontalItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool bold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ?? _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return _success;
      case 'pending':
        return const Color(0xFFD97706);
      case 'failed':
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return _textSecondary;
    }
  }

  String _formatMoney(double amount, String currency) {
    if (currency.toUpperCase() == 'USD') {
      return '\$${amount.toStringAsFixed(2)}';
    }
    return '${amount.toStringAsFixed(2)} ${currency.toUpperCase()}';
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _shortId(String id) {
    if (id.isEmpty || id == '—') return '—';
    if (id.length <= 12) return id;
    return '${id.substring(0, 6)}...${id.substring(id.length - 4)}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
