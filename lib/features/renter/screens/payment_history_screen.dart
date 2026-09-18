import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rentease/features/renter/screens/payment_detail_screen.dart';

import '../../../models/payment_model.dart';
import '../../../services/payment_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  String selectedFilter = "This Month";

  final PaymentService paymentService = PaymentService();

  late final String renterId;

  // ============================================================
  // THEME COLORS
  // ============================================================

  static const Color _primary = Color(0xFF4F46E5);

  Color get _background {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark
        ? const Color(0xFF0F1115)
        : const Color(0xFFF8FAFC);
  }

  Color get _card {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark
        ? const Color(0xFF181B21)
        : Colors.white;
  }

  Color get _textPrimary {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark
        ? Colors.white
        : const Color(0xFF0F172A);
  }

  Color get _textSecondary {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF64748B);
  }

  Color get _border {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark
        ? const Color(0xFF2A2F38)
        : const Color(0xFFE2E8F0);
  }

  Color get _inputBackground {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark
        ? const Color(0xFF20242B)
        : Colors.white;
  }

  bool get _isDark =>
      Theme.of(context).brightness == Brightness.dark;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    print("");
    print("==============================================");
    print(" PAYMENT HISTORY SCREEN");
    print("==============================================");

    if (user == null) {
      print("❌ FirebaseAuth.currentUser == NULL");
      print("❌ User is NOT logged in");

      renterId = "";
    } else {
      renterId = user.uid;

      print("✅ Firebase user found");
      print("UID       : ${user.uid}");
      print("Email     : ${user.email}");
      print("Display   : ${user.displayName}");
    }

    print("Renter ID : $renterId");
    print("==============================================");
    print("");
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    print("🔵 PaymentHistoryScreen build()");
    print("🔵 renterId = $renterId");

    if (renterId.isEmpty) {
      return _buildNoUserScreen();
    }

    return Scaffold(
      backgroundColor: _background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: Text(
          "Payment History",
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),

        centerTitle: true,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ======================================================
          // FILTER
          // ======================================================

          SizedBox(
            height: 48,

            child: ListView(
              scrollDirection: Axis.horizontal,

              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),

              children: [
                _filterChip("This Month"),
                _filterChip("Last 3 Months"),
                _filterChip("This Year"),
                _filterChip("All"),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ======================================================
          // PAYMENT LIST
          // ======================================================

          Expanded(
            child: StreamBuilder<List<PaymentModel>>(
              stream: paymentService.getRenterPayments(renterId),

              builder: (context, snapshot) {

                // ------------------------------------------------
                // DEBUG
                // ------------------------------------------------

                print("");
                print("----------------------------------------------");
                print(" PAYMENT STREAM DEBUG");
                print("----------------------------------------------");

                print(
                  "Connection State : ${snapshot.connectionState}",
                );

                print(
                  "Has Data         : ${snapshot.hasData}",
                );

                print(
                  "Has Error        : ${snapshot.hasError}",
                );

                if (snapshot.hasError) {
                  print("❌ STREAM ERROR:");
                  print(snapshot.error);
                }

                if (snapshot.hasData) {
                  print(
                    "Payment Count    : ${snapshot.data!.length}",
                  );
                }

                print("----------------------------------------------");
                print("");

                // ==================================================
                // LOADING
                // ==================================================

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {

                  return const Center(
                    child: CircularProgressIndicator(
                      color: _primary,
                    ),
                  );
                }

                // ==================================================
                // ERROR
                // ==================================================

                if (snapshot.hasError) {

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Color(0xFFEF4444),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            "Something went wrong",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // ==================================================
                // NO DATA
                // ==================================================

                if (!snapshot.hasData ||
                    snapshot.data!.isEmpty) {

                  return _buildEmptyState();
                }

                // ==================================================
                // PAYMENTS FOUND
                // ==================================================

                final payments = snapshot.data!;

                print("");
                print("==============================================");
                print(" ✅ PAYMENTS FOUND");
                print(" COUNT: ${payments.length}");
                print("==============================================");

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    28,
                  ),

                  itemCount: payments.length,

                  itemBuilder: (context, index) {

                    final payment = payments[index];

                    return _paymentCard(payment);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NO USER
  // ============================================================

  Widget _buildNoUserScreen() {
    return Scaffold(
      backgroundColor: _background,

      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,

        title: Text(
          "Payment History",
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: Center(
        child: Text(
          "No logged-in user found.",
          style: TextStyle(
            color: _textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Container(
            width: 72,
            height: 72,

            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.receipt_long_rounded,
              size: 36,
              color: _primary,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            "No payments yet",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "No payment records were found.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER CHIP
  // ============================================================

  Widget _filterChip(String label) {

    final isSelected =
        selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 10),

      child: GestureDetector(

        onTap: () {

          print(
            "🔵 Filter selected: $label",
          );

          setState(() {
            selectedFilter = label;
          });
        },

        child: AnimatedContainer(

          duration:
          const Duration(milliseconds: 200),

          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),

          decoration: BoxDecoration(

            color: isSelected
                ? _primary
                : _card,

            borderRadius:
            BorderRadius.circular(24),

            border: Border.all(
              color: isSelected
                  ? _primary
                  : _border,
              width: 1.2,
            ),

            boxShadow: isSelected
                ? [
              BoxShadow(
                color:
                _primary.withOpacity(0.25),
                blurRadius: 12,
                offset:
                const Offset(0, 4),
              ),
            ]
                : null,
          ),

          child: Text(
            label,

            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,

              color: isSelected
                  ? Colors.white
                  : _textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT CARD
  // ============================================================

  Widget _paymentCard(
      PaymentModel payment,
      ) {

    print(
      "🟣 Building payment card: ${payment.bookingId}",
    );

    final status =
    payment.status.toLowerCase();

    final isRefunded =
        status == "refunded";

    final isPending =
        status == "pending";

    final isPaid =
        status == "paid" ||
            status == "completed";

    Color statusBg;
    Color statusText;
    IconData statusIcon;

    if (isRefunded) {

      statusBg =
      _isDark
          ? const Color(0xFF3A1D22)
          : const Color(0xFFFEE2E2);

      statusText =
      const Color(0xFFDC2626);

      statusIcon =
          Icons.undo_rounded;

    } else if (isPending) {

      statusBg =
      _isDark
          ? const Color(0xFF3A2E18)
          : const Color(0xFFFEF3C7);

      statusText =
      const Color(0xFFD97706);

      statusIcon =
          Icons.schedule_rounded;

    } else {

      statusBg =
      _isDark
          ? const Color(0xFF173329)
          : const Color(0xFFD1FAE5);

      statusText =
      const Color(0xFF059669);

      statusIcon =
          Icons.check_circle_rounded;
    }

    return GestureDetector(

      onTap: () {

        print(
          "🟢 Payment clicked: ${payment.id}",
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PaymentDetailScreen(
                  payment: payment,
                ),
          ),
        );
      },

      child: Container(

        margin:
        const EdgeInsets.only(bottom: 14),

        padding:
        const EdgeInsets.all(16),

        decoration: BoxDecoration(

          color: _card,

          borderRadius:
          BorderRadius.circular(18),

          border: Border.all(
            color: _border,
            width: 0.7,
          ),

          boxShadow: _isDark
              ? null
              : [
            BoxShadow(
              color:
              Colors.black.withOpacity(
                0.04,
              ),
              blurRadius: 16,
              offset:
              const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          children: [

            // ==================================================
            // ICON
            // ==================================================

            Container(
              width: 56,
              height: 56,

              decoration: BoxDecoration(
                color:
                _primary.withOpacity(0.08),

                borderRadius:
                BorderRadius.circular(14),
              ),

              child: const Icon(
                Icons.home_rounded,
                size: 28,
                color: _primary,
              ),
            ),

            const SizedBox(width: 14),

            // ==================================================
            // INFO
            // ==================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Text(
                    "Booking #${_shortId(payment.bookingId)}",

                    style: TextStyle(
                      fontWeight:
                      FontWeight.w700,

                      fontSize: 15,

                      color:
                      _textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    payment.paymentMethod,

                    style: TextStyle(
                      fontSize: 13,

                      color:
                      _textSecondary,

                      fontWeight:
                      FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "\$${payment.amount.toStringAsFixed(2)}",

                    style: const TextStyle(
                      fontSize: 17,

                      fontWeight:
                      FontWeight.w800,

                      color: _primary,

                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // STATUS
            // ==================================================

            Container(

              padding:
              const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),

              decoration:
              BoxDecoration(
                color: statusBg,

                borderRadius:
                BorderRadius.circular(20),
              ),

              child: Row(
                mainAxisSize:
                MainAxisSize.min,

                children: [

                  Icon(
                    statusIcon,
                    size: 13,
                    color: statusText,
                  ),

                  const SizedBox(width: 4),

                  Text(
                    payment.status,

                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                      FontWeight.w700,
                      color: statusText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SHORT ID
  // ============================================================

  String _shortId(String? id) {

    if (id == null ||
        id.isEmpty) {
      return "—";
    }

    if (id.length <= 8) {
      return id;
    }

    return id.substring(0, 8);
  }
}