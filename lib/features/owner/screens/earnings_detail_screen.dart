import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EarningsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> payment;

  const EarningsDetailScreen({
    super.key,
    required this.payment,
  });

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _card = Colors.white;
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _success = Color(0xFF059669);

  @override
  Widget build(BuildContext context) {
    final double amount =
        (payment['amount'] as num?)?.toDouble() ?? 0.0;

    final String status =
        payment['status']?.toString() ?? 'Unknown';

    final String paymentMethod =
        payment['paymentMethod']?.toString() ?? 'Unknown';

    final String paymentId =
        payment['paymentId']?.toString() ?? '—';

    final String bookingId =
        payment['bookingId']?.toString() ?? '—';

    final String houseId =
        payment['houseId']?.toString() ?? '—';

    final String renterId =
        payment['renterId']?.toString() ?? '—';

    final String ownerId =
        payment['ownerId']?.toString() ?? '—';

    final Timestamp? timestamp =
    payment['createdAt'] is Timestamp
        ? payment['createdAt'] as Timestamp
        : null;

    final DateTime? createdAt = timestamp?.toDate();

    return Scaffold(
      backgroundColor: _bg,
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Earnings Details',
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
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          40,
        ),
        child: Column(
          children: [

            // =====================================================
            // AMOUNT CARD
            // =====================================================

            _buildAmountCard(
              amount: amount,
              status: status,
            ),

            const SizedBox(height: 20),

            // =====================================================
            // PAYMENT INFORMATION
            // =====================================================

            _sectionTitle('PAYMENT INFORMATION'),

            const SizedBox(height: 10),

            _buildInfoCard(
              children: [
                _detailRow(
                  icon: Icons.payments_outlined,
                  label: 'Amount',
                  value: '\$${amount.toStringAsFixed(2)}',
                  valueColor: _primary,
                  bold: true,
                ),

                _divider(),

                _detailRow(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Status',
                  value: status,
                  valueColor: _statusColor(status),
                  bold: true,
                ),

                _divider(),

                _detailRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Payment Method',
                  value: paymentMethod,
                ),

                _divider(),

                _detailRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'Payment ID',
                  value: _shortId(paymentId),
                ),

                if (createdAt != null) ...[
                  _divider(),
                  _detailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Date',
                    value: _formatDate(createdAt),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // =====================================================
            // BOOKING INFORMATION
            // =====================================================

            _sectionTitle('BOOKING INFORMATION'),

            const SizedBox(height: 10),

            _buildInfoCard(
              children: [
                _detailRow(
                  icon: Icons.bookmark_border_rounded,
                  label: 'Booking ID',
                  value: _shortId(bookingId),
                ),

                _divider(),

                _detailRow(
                  icon: Icons.home_work_outlined,
                  label: 'House ID',
                  value: _shortId(houseId),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // =====================================================
            // PEOPLE
            // =====================================================

            _sectionTitle('PARTICIPANTS'),

            const SizedBox(height: 10),

            _buildInfoCard(
              children: [
                _detailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Renter ID',
                  value: _shortId(renterId),
                ),

                _divider(),

                _detailRow(
                  icon: Icons.business_center_outlined,
                  label: 'Owner ID',
                  value: _shortId(ownerId),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // =====================================================
            // TRANSACTION ID
            // =====================================================

            _buildTransactionCard(
              paymentId: paymentId,
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // AMOUNT CARD
  // =============================================================

  Widget _buildAmountCard({
    required double amount,
    required String status,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        24,
        28,
        24,
        26,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4F46E5),
            Color(0xFF6366F1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [

          // Icon
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Total Earnings',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status == 'Paid'
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
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

  // =============================================================
  // INFO CARD
  // =============================================================

  Widget _buildInfoCard({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // =============================================================
  // DETAIL ROW
  // =============================================================

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
      ),
      child: Row(
        children: [

          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: _primary,
              size: 19,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ?? _textPrimary,
                fontSize: 14,
                fontWeight:
                bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // TRANSACTION CARD
  // =============================================================

  Widget _buildTransactionCard({
    required String paymentId,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        children: [

          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: _success,
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transaction',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  paymentId,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textPrimary,
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

  // =============================================================
  // SECTION TITLE
  // =============================================================

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: _textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // =============================================================
  // DIVIDER
  // =============================================================

  Widget _divider() {
    return const Divider(
      height: 1,
      color: _border,
    );
  }

  // =============================================================
  // STATUS COLOR
  // =============================================================

  Color _statusColor(String status) {
    switch (status) {
      case 'Paid':
        return _success;

      case 'Pending':
        return const Color(0xFFD97706);

      case 'Failed':
      case 'Cancelled':
        return const Color(0xFFDC2626);

      default:
        return _textSecondary;
    }
  }

  // =============================================================
  // SHORT ID
  // =============================================================

  String _shortId(String id) {
    if (id.isEmpty || id == '—') {
      return '—';
    }

    if (id.length <= 12) {
      return id;
    }

    return '${id.substring(0, 6)}...${id.substring(id.length - 4)}';
  }

  // =============================================================
  // DATE
  // =============================================================

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}