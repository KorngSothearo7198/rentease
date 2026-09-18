import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/booking_model.dart';
import '../../../services/booking_service.dart';
import 'booking_detail_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  final BookingService bookingService = BookingService();

  late TabController _tabController;

  final Map<String, String> _propertyNames = {};
  final Set<String> _loadingPropertyNames = {};

  String? renterId;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _primary = Color(0xFF4F46E5);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    renterId = FirebaseAuth.instance.currentUser?.uid;

    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ============================================================
  // THEME COLORS
  // ============================================================

  Color get _backgroundColor {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  Color get _cardColor {
    return Theme.of(context).cardColor;
  }

  Color get _textPrimary {
    return Theme.of(context).colorScheme.onSurface;
  }

  Color get _textSecondary {
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.60);
  }

  Color get _borderColor {
    return Theme.of(context).dividerColor;
  }

  // ============================================================
  // LOAD PROPERTY NAME
  // ============================================================

  Future<void> _loadPropertyName(String houseId) async {
    if (houseId.isEmpty) return;

    if (_propertyNames.containsKey(houseId)) {
      return;
    }

    if (_loadingPropertyNames.contains(houseId)) {
      return;
    }

    _loadingPropertyNames.add(houseId);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('properties')
          .doc(houseId)
          .get();

      if (!mounted) return;

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;

        final title = data['title']?.toString().trim();

        setState(() {
          _propertyNames[houseId] = title != null && title.isNotEmpty
              ? title
              : 'Unnamed Property';
        });
      } else {
        setState(() {
          _propertyNames[houseId] = 'Property not found';
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading property $houseId: $e');

      if (!mounted) return;

      setState(() {
        _propertyNames[houseId] = 'Unknown Property';
      });
    } finally {
      _loadingPropertyNames.remove(houseId);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (renterId == null) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: Text(
            "User not logged in",
            style: TextStyle(color: _textPrimary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: _textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _textPrimary,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(
          "Booking History",
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),

        centerTitle: true,

        // ======================================================
        // TAB BAR
        // ======================================================
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),

          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),

            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(14),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    theme.brightness == Brightness.dark ? 0.20 : 0.03,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),

            child: TabBar(
              controller: _tabController,

              isScrollable: true,

              tabAlignment: TabAlignment.start,

              indicatorSize: TabBarIndicatorSize.tab,

              indicator: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(12),
              ),

              labelColor: Colors.white,

              unselectedLabelColor: _textSecondary,

              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),

              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),

              dividerColor: Colors.transparent,

              padding: const EdgeInsets.all(4),

              tabs: const [
                Tab(text: "All"),
                Tab(text: "Active"),
                Tab(text: "Completed"),
                Tab(text: "Cancelled"),
              ],
            ),
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: StreamBuilder<List<BookingModel>>(
        stream: bookingService.getRenterBookings(renterId!),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),

                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,

                  style: TextStyle(color: _textSecondary),
                ),
              ),
            );
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return _emptyState();
          }

          // ====================================================
          // FILTER
          // ====================================================

          // ====================================================

          final all = bookings;

          // ACTIVE
          // Owner approved the booking, but renter has NOT paid yet.
          // Pending bookings are also considered active.
          final active = bookings.where((b) {
            final status = b.status.trim().toLowerCase();
            final paymentStatus = (b.paymentStatus ?? '').trim().toLowerCase();

            final isCancelled =
                status == 'cancelled' ||
                    status == 'rejected';

            final isPaid =
                paymentStatus == 'paid';

            if (isCancelled) {
              return false;
            }

            // Already paid -> Completed, not Active
            if (isPaid) {
              return false;
            }

            return status == 'approved' ||
                status == 'pending';
          }).toList();

          // COMPLETED
          // Booking has been approved AND payment has been completed.
          //
          // Firebase example:
          // status       = Approved
          // paymentStatus = Paid
          //
          // => Completed
          final completed = bookings.where((b) {
            final status = b.status.trim().toLowerCase();
            final paymentStatus = (b.paymentStatus ?? '').trim().toLowerCase();

            final isCancelled =
                status == 'cancelled' ||
                    status == 'rejected';

            final isPaid =
                paymentStatus == 'paid';

            return !isCancelled &&
                isPaid &&
                (
                    status == 'approved' ||
                        status == 'completed'
                );
          }).toList();

          // CANCELLED
          // Show all rejected/cancelled bookings.
          final cancelled = bookings.where((b) {
            final status = b.status.trim().toLowerCase();

            return status == 'cancelled' ||
                status == 'rejected';
          }).toList();

          // ====================================================
          // TABS
          // ====================================================

          return TabBarView(
            controller: _tabController,

            children: [
              _bookingList(all),
              _bookingList(active),
              _bookingList(completed),
              _bookingList(cancelled),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // BOOKING LIST
  // ============================================================

  Widget _bookingList(List<BookingModel> data) {
    if (data.isEmpty) {
      return _emptyState(message: "No bookings in this category");
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),

      physics: const BouncingScrollPhysics(),

      itemCount: data.length,

      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),

          duration: Duration(milliseconds: 350 + (index * 60).clamp(0, 400)),

          curve: Curves.easeOutCubic,

          builder: (context, value, child) {
            return Opacity(
              opacity: value,

              child: Transform.translate(
                offset: Offset(0, 24 * (1 - value)),

                child: child,
              ),
            );
          },

          child: _bookingCard(data[index]),
        );
      },
    );
  }

  // ============================================================
  // BOOKING CARD
  // ============================================================

  String _displayStatus(BookingModel booking) {
    final status = booking.status.trim().toLowerCase();
    final paymentStatus =
    (booking.paymentStatus ?? '').trim().toLowerCase();

    if (status == 'cancelled' || status == 'rejected') {
      return 'Cancelled';
    }

    if (paymentStatus == 'paid') {
      return 'Completed';
    }

    if (status == 'approved') {
      return 'Approved';
    }

    if (status == 'pending') {
      return 'Pending';
    }

    return booking.status;
  }

  Widget _bookingCard(BookingModel booking) {
    final displayStatus = _displayStatus(booking);

    final color = _statusColor(displayStatus);

    final start = booking.startDate.toDate();

    final end = booking.endDate.toDate();

    _loadPropertyName(booking.houseId);

    final houseName = _propertyNames[booking.houseId] ?? 'Loading house...';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      decoration: BoxDecoration(
        color: _cardColor,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.04,
            ),

            blurRadius: 14,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        borderRadius: BorderRadius.circular(18),

        child: InkWell(
          borderRadius: BorderRadius.circular(18),

          onTap: () {
            Navigator.push(
              context,

              MaterialPageRoute(
                builder: (_) => BookingDetailScreen(booking: booking),
              ),
            );
          },

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // =================================================
                // TOP ROW
                // =================================================
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,

                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.12),

                        borderRadius: BorderRadius.circular(14),
                      ),

                      child: const Icon(
                        Icons.home_rounded,

                        color: _primary,

                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          // HOUSE NAME
                          Text(
                            houseName,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              fontSize: 15,

                              fontWeight: FontWeight.w700,

                              color: _textPrimary,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // BOOKING ID
                          Text(
                            "Booking #${_shortId(booking.bookingId)}",

                            style: TextStyle(
                              fontSize: 12,

                              color: _textSecondary,

                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // STATUS
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),

                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),

                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Text(
                        displayStatus,

                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Divider(height: 1, color: _borderColor),

                const SizedBox(height: 14),

                // =================================================
                // DATES
                // =================================================
                Row(
                  children: [
                    _dateBox("From", _formatDate(start)),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),

                      child: Icon(
                        Icons.arrow_forward_rounded,

                        size: 16,

                        color: _textSecondary.withOpacity(0.5),
                      ),
                    ),

                    _dateBox("To", _formatDate(end)),
                  ],
                ),

                const SizedBox(height: 16),

                // =================================================
                // BOTTOM
                // =================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,

                          size: 14,

                          color: _textSecondary,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          "${booking.totalDays} days",

                          style: TextStyle(
                            fontSize: 13,

                            color: _textSecondary,

                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    Text(
                      "\$${(booking.totalAmount ?? 0).toStringAsFixed(2)}",

                      style: const TextStyle(
                        fontSize: 20,

                        fontWeight: FontWeight.w800,

                        color: _primary,

                        letterSpacing: -0.3,
                      ),
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
  // DATE BOX
  // ============================================================

  Widget _dateBox(String label, String date) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

        decoration: BoxDecoration(
          color: _backgroundColor,

          borderRadius: BorderRadius.circular(12),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              label,

              style: TextStyle(
                fontSize: 11,

                color: _textSecondary,

                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              date,

              style: TextStyle(
                fontSize: 13,

                fontWeight: FontWeight.w700,

                color: _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState({String message = "No booking history yet"}) {
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

            child: const Icon(Icons.history_rounded, size: 36, color: _primary),
          ),

          const SizedBox(height: 18),

          Text(
            message,

            style: TextStyle(
              fontSize: 16,

              fontWeight: FontWeight.w700,

              color: _textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Your bookings will appear here",

            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _shortId(String? id) {
    if (id == null || id.isEmpty) {
      return "—";
    }

    if (id.length <= 8) {
      return id;
    }

    return id.substring(0, 8);
  }

  String _formatDate(DateTime d) {
    return "${d.day}/${d.month}/${d.year}";
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return const Color(0xFF059669);

      case "pending":
        return const Color(0xFFD97706);

      case "completed":
        return const Color(0xFF2563EB);

      case "cancelled":
      case "rejected":
        return const Color(0xFFDC2626);

      default:
        return _textSecondary;
    }
  }
}
