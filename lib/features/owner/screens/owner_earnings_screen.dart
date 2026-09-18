import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'earnings_detail_screen.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _card = Colors.white;
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _success = Color(0xFF059669);
  static const Color _warning = Color(0xFFD97706);
  static const Color _danger = Color(0xFFDC2626);

  bool _isLoading = true;

  List<Map<String, dynamic>> _payments = [];

  double _totalEarnings = 0;
  int _paidCount = 0;

  final Map<String, String> _propertyNames = {};

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  // ============================================================
  // LOAD PAYMENTS
  // ============================================================

  Future<void> _loadEarnings() async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        debugPrint('❌ No authenticated user');
        return;
      }

      final ownerId = currentUser.uid;

      debugPrint('======================================');
      debugPrint('💰 LOADING OWNER EARNINGS');
      debugPrint('Owner ID: $ownerId');
      debugPrint('======================================');

      final snapshot = await _firestore
          .collection('payments')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      double total = 0;
      int paid = 0;

      final List<Map<String, dynamic>> loadedPayments = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final amount = _toDouble(data['amount']);

        final status = data['status']?.toString() ?? 'Unknown';

        if (status.toLowerCase() == 'paid') {
          total += amount;
          paid++;
        }

        loadedPayments.add({'id': doc.id, ...data});

        // Load property name
        final houseId = data['houseId']?.toString() ?? '';

        if (houseId.isNotEmpty) {
          await _loadPropertyName(houseId);
        }
      }

      // Sort newest first
      loadedPayments.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;

        if (aDate == null || bDate == null) {
          return 0;
        }

        return bDate.compareTo(aDate);
      });

      if (!mounted) return;

      setState(() {
        _payments = loadedPayments;
        _totalEarnings = total;
        _paidCount = paid;
        _isLoading = false;
      });

      debugPrint('======================================');
      debugPrint('✅ PAYMENTS LOADED');
      debugPrint('Payments : ${loadedPayments.length}');
      debugPrint('Paid     : $paid');
      debugPrint('Total    : \$${total.toStringAsFixed(2)}');
      debugPrint('======================================');
    } catch (e, stackTrace) {
      debugPrint('❌ Load earnings error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // LOAD PROPERTY NAME
  // ============================================================

  Future<void> _loadPropertyName(String houseId) async {
    if (_propertyNames.containsKey(houseId)) {
      return;
    }

    try {
      final doc = await _firestore.collection('properties').doc(houseId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        _propertyNames[houseId] =
            data['title']?.toString() ??
            data['name']?.toString() ??
            'Rental Property';
      } else {
        _propertyNames[houseId] = 'Unknown Property';
      }
    } catch (e) {
      debugPrint('❌ Load property name error: $e');

      _propertyNames[houseId] = 'Unknown Property';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
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
          'Earnings & Payments',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              color: _primary,
              onRefresh: _loadEarnings,
              child: _buildContent(),
            ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    if (_payments.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.35),
          _emptyState(),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _buildEarningsCard(),

        const SizedBox(height: 20),

        _buildSummaryRow(),

        const SizedBox(height: 28),

        _buildSectionTitle('PAYMENT HISTORY'),

        const SizedBox(height: 12),

        ..._payments.map((payment) => _buildPaymentCard(payment)),
      ],
    );
  }

  // ============================================================
  // EARNINGS CARD
  // ============================================================

  Widget _buildEarningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Total Earnings',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            '\$${_totalEarnings.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'From $_paidCount paid payment${_paidCount == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.payments_outlined,
            title: 'Paid',
            value: '$_paidCount',
            color: _success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            icon: Icons.receipt_long_outlined,
            title: 'Transactions',
            value: '${_payments.length}',
            color: _primary,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
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
  // PAYMENT CARD
  // ============================================================

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final amount = _toDouble(payment['amount']);

    final status = payment['status']?.toString() ?? 'Unknown';

    final paymentMethod = payment['paymentMethod']?.toString() ?? 'Unknown';

    final houseId = payment['houseId']?.toString() ?? '';

    final createdAt = payment['createdAt'] as Timestamp?;

    final statusColor = _paymentStatusColor(status);

    // Get actual property name
    final houseName = _propertyNames[houseId] ?? 'Loading property...';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              isDismissible: true,
              enableDrag: true,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return DraggableScrollableSheet(
                  initialChildSize: 0.65,
                  minChildSize: 0.45,
                  maxChildSize: 0.95,
                  expand: false,
                  builder: (context, scrollController) {
                    return EarningsDetailScreen(
                      payment: payment,
                      // scrollController: scrollController,
                    );
                  },
                );
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =================================================
                // PROPERTY + STATUS
                // =================================================
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.home_work_outlined,
                        color: _success,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 13),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            houseName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            'Rental payment',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // STATUS
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                const Divider(height: 1, color: _border),

                const SizedBox(height: 14),

                // =================================================
                // AMOUNT + PAYMENT METHOD
                // =================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount received',
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '\$${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: _primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            paymentMethod.toLowerCase() == 'cash'
                                ? Icons.payments_outlined
                                : Icons.credit_card_outlined,
                            size: 15,
                            color: _textSecondary,
                          ),

                          const SizedBox(width: 5),

                          Text(
                            paymentMethod,
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // =================================================
                // DATE
                // =================================================
                Row(
                  children: [
                    _paymentInfo(
                      Icons.access_time_rounded,
                      _formatDateTime(createdAt),
                    ),

                    const Spacer(),

                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT INFO
  // ============================================================

  Widget _paymentInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: _textSecondary),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: _primary,
              size: 38,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'No payments yet',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Your rental earnings will appear here.',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  String _shortId(String? id) {
    if (id == null || id.isEmpty) {
      return '—';
    }

    if (id.length <= 8) {
      return id;
    }

    return id.substring(0, 8);
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Unknown date';
    }

    final date = timestamp.toDate();

    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    final year = date.year;

    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  Color _paymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return _success;

      case 'pending':
        return _warning;

      case 'failed':
      case 'cancelled':
        return _danger;

      default:
        return _textSecondary;
    }
  }
}
