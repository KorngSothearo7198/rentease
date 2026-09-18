import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rentease/features/renter/screens/payment_screen.dart';

import '../../../models/booking_model.dart';
import '../../../models/notification_model.dart';
import '../../../models/user_model.dart';
import '../../owner/screens/owner_public_profile_screen.dart';

class NotificationDetailScreen extends StatefulWidget {
  final NotificationModel notification;
  final BookingModel booking;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
    required this.booking,
  });

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  UserModel? owner;
  bool isLoading = true;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _primary = Color(0xFF4F46E5);

  // Light mode
  static const Color _lightBg = Color(0xFFF8FAFC);
  static const Color _lightCard = Colors.white;
  static const Color _lightTextPrimary = Color(0xFF0F172A);
  static const Color _lightTextSecondary = Color(0xFF64748B);
  static const Color _lightBorder = Color(0xFFE2E8F0);

  // Dark mode
  static const Color _darkBg = Colors.black;
  static const Color _darkCard = Color(0xFF121212);
  static const Color _darkTextPrimary = Colors.white;
  static const Color _darkTextSecondary = Color(0xFF9CA3AF);
  static const Color _darkBorder = Color(0xFF2A2A2A);

  // ============================================================
  // THEME HELPERS
  // ============================================================

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _bg(BuildContext context) {
    return _isDark(context) ? _darkBg : _lightBg;
  }

  Color _card(BuildContext context) {
    return _isDark(context) ? _darkCard : _lightCard;
  }

  Color _textPrimary(BuildContext context) {
    return _isDark(context) ? _darkTextPrimary : _lightTextPrimary;
  }

  Color _textSecondary(BuildContext context) {
    return _isDark(context) ? _darkTextSecondary : _lightTextSecondary;
  }

  Color _border(BuildContext context) {
    return _isDark(context) ? _darkBorder : _lightBorder;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadOwner();
  }

  // ============================================================
  // OWNER PROFILE BOTTOM SHEET
  // ============================================================

  void _openOwnerProfileSheet() {
    if (owner == null) return;

    final dark = _isDark(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: dark ? _darkCard : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Handle
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dark ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Close
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: _textPrimary(context),
                      ),
                    ),
                  ),

                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: OwnerPublicProfileScreen(owner: owner!),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();

    return "${date.day}/${date.month}/${date.year}";
  }

  String _formatDateTime(Timestamp ts) {
    final d = ts.toDate();

    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');

    return "${d.day}/${d.month}/${d.year}  •  $h:$m";
  }

  // ============================================================
  // LOAD OWNER
  // ============================================================

  Future<void> loadOwner() async {
    if (widget.notification.ownerId.isEmpty) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.notification.ownerId)
          .get();

      if (snapshot.exists && mounted) {
        setState(() {
          owner = UserModel.fromMap(snapshot.data()!);
        });
      }
    } catch (e) {
      debugPrint("LOAD OWNER ERROR: $e");
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  // ============================================================
  // STATUS COLORS
  // ============================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return const Color(0xFF10B981);

      case "pending":
        return const Color(0xFFF59E0B);

      case "rejected":
      case "cancelled":
        return const Color(0xFFEF4444);

      default:
        return _primary;
    }
  }

  Color _statusBg(BuildContext context, String status) {
    final dark = _isDark(context);

    switch (status.toLowerCase()) {
      case "approved":
        return dark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);

      case "pending":
        return dark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7);

      case "rejected":
      case "cancelled":
        return dark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2);

      default:
        return _primary.withOpacity(dark ? 0.20 : 0.10);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),

      appBar: AppBar(
        backgroundColor: _bg(context),
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _textPrimary(context),
          ),
          onPressed: () => Navigator.maybePop(context),
        ),

        title: Text(
          "Notification Detail",
          style: TextStyle(
            color: _textPrimary(context),
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),

        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              physics: const BouncingScrollPhysics(),

              child: Column(
                children: [
                  _animatedItem(0, _buildNotificationCard()),

                  const SizedBox(height: 14),

                  _animatedItem(1, _buildBookingInfoCard()),

                  const SizedBox(height: 14),

                  _animatedItem(2, _buildOwnerInfoCard()),

                  const SizedBox(height: 14),

                  if (widget.booking.status.toLowerCase() == "approved")
                    _animatedItem(3, _buildPaymentCard()),

                  const SizedBox(height: 20),

                  Text(
                    "Received ${_formatDateTime(widget.notification.createdAt)}",
                    style: TextStyle(
                      color: _textSecondary(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // ANIMATION
  // ============================================================

  Widget _animatedItem(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + (index * 80)),
      curve: Curves.easeOutCubic,

      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },

      child: child,
    );
  }

  // ============================================================
  // 1. NOTIFICATION CARD
  // ============================================================

  Widget _buildNotificationCard() {
    final isApproved =
        widget.notification.title.toLowerCase().contains("approved") ||
        widget.booking.status.toLowerCase() == "approved";

    final iconColor = isApproved ? const Color(0xFF10B981) : _primary;

    final bgColor = isApproved
        ? (_isDark(context) ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
        : _primary.withOpacity(_isDark(context) ? 0.20 : 0.10);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark(context) ? 0.30 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(
              isApproved
                  ? Icons.check_circle_rounded
                  : Icons.notifications_active_rounded,
              color: iconColor,
              size: 26,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.notification.title,

                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary(context),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  widget.notification.body,

                  style: TextStyle(
                    fontSize: 13,
                    color: _textSecondary(context),
                    height: 1.45,
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
  // 2. BOOKING INFORMATION
  // ============================================================

  Widget _buildBookingInfoCard() {
    final status = widget.booking.status;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark(context) ? 0.30 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,

                decoration: BoxDecoration(
                  color: _primary.withOpacity(_isDark(context) ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),

                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: _primary,
                  size: 18,
                ),
              ),

              const SizedBox(width: 10),

              Text(
                "Booking Information",

                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Status",

                style: TextStyle(
                  fontSize: 13,
                  color: _textSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),

                decoration: BoxDecoration(
                  color: _statusBg(context, status),
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Text(
                  status,

                  style: TextStyle(
                    color: _statusColor(status),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),

            child: Divider(height: 1, color: _border(context)),
          ),

          _infoRow(
            "Dates",
            "${formatDate(widget.booking.startDate)} – "
                "${formatDate(widget.booking.endDate)}",
          ),

          const SizedBox(height: 12),

          _infoRow("Duration", "${widget.booking.totalDays} days"),

          const SizedBox(height: 12),

          _infoRow(
            "Total amount",
            "\$${widget.booking.totalAmount.toStringAsFixed(2)}",
            valueColor: _primary,
            bold: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,

          style: TextStyle(
            fontSize: 13,
            color: _textSecondary(context),
            fontWeight: FontWeight.w500,
          ),
        ),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,

            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? _textPrimary(context),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 3. OWNER INFORMATION
  // ============================================================

  Widget _buildOwnerInfoCard() {
    if (owner == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),

        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: BorderRadius.circular(18),
        ),

        child: Center(
          child: Text(
            "Owner information unavailable",

            style: TextStyle(color: _textSecondary(context), fontSize: 13),
          ),
        ),
      );
    }

    final image = owner!.profileImage?.trim() ?? '';

    return Material(
      color: _card(context),
      borderRadius: BorderRadius.circular(18),

      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _openOwnerProfileSheet,

        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDark(context) ? 0.30 : 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,

                    decoration: BoxDecoration(
                      color: _primary.withOpacity(
                        _isDark(context) ? 0.20 : 0.10,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: _primary,
                      size: 18,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      "Owner Information",

                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary(context),
                      ),
                    ),
                  ),

                  Icon(
                    Icons.chevron_right_rounded,
                    color: _textSecondary(context),
                    size: 22,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  CircleAvatar(
                    radius: 28,

                    backgroundColor: _primary.withOpacity(
                      _isDark(context) ? 0.20 : 0.10,
                    ),

                    backgroundImage: image.isNotEmpty
                        ? NetworkImage(image)
                        : null,

                    child: image.isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: _primary,
                          )
                        : null,
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          owner!.fullName.trim().isEmpty
                              ? "Unknown Owner"
                              : owner!.fullName,

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary(context),
                          ),
                        ),

                        const SizedBox(height: 4),

                        if (owner!.phone.trim().isNotEmpty)
                          Text(
                            owner!.phone,

                            style: TextStyle(
                              fontSize: 13,
                              color: _textSecondary(context),
                            ),
                          ),

                        if (owner!.email.trim().isNotEmpty)
                          Text(
                            owner!.email,

                            style: TextStyle(
                              fontSize: 12,
                              color: _textSecondary(context),
                            ),

                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 44,

                child: OutlinedButton.icon(
                  onPressed: _openOwnerProfileSheet,

                  icon: const Icon(Icons.badge_outlined, size: 18),

                  label: const Text(
                    "View Owner Profile",

                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),

                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,

                    side: BorderSide(
                      color: _primary.withOpacity(
                        _isDark(context) ? 0.50 : 0.35,
                      ),
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 4. PAYMENT CARD
  // ============================================================

  Widget _buildPaymentCard() {
    final paymentStatus = widget.booking.paymentStatus ?? "Pending";

    final isPaid = paymentStatus.toLowerCase() == "paid";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: _card(context),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: isPaid
              ? const Color(
                  0xFF059669,
                ).withOpacity(_isDark(context) ? 0.50 : 0.30)
              : _primary.withOpacity(_isDark(context) ? 0.45 : 0.25),
          width: 1.2,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark(context) ? 0.30 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,

                decoration: BoxDecoration(
                  color: _primary.withOpacity(_isDark(context) ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),

                child: const Icon(
                  Icons.payments_outlined,
                  color: _primary,
                  size: 18,
                ),
              ),

              const SizedBox(width: 10),

              Text(
                "Payment",

                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            isPaid
                ? "Payment completed. Your rental is confirmed."
                : "Your booking is approved. Complete payment "
                      "to confirm your rental.",

            style: TextStyle(
              fontSize: 13,
              color: _textSecondary(context),
              height: 1.45,
            ),
          ),

          const SizedBox(height: 14),

          // Payment status
          Container(
            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: _isDark(context) ? const Color(0xFF1C1C1C) : _lightBg,
              borderRadius: BorderRadius.circular(12),
            ),

            child: Row(
              children: [
                Icon(
                  isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,

                  size: 18,

                  color: isPaid
                      ? const Color(0xFF059669)
                      : const Color(0xFFD97706),
                ),

                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      "PAYMENT STATUS",

                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _textSecondary(context),
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      paymentStatus,

                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isPaid
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Pay button
          if (!isPaid) ...[
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RenterPaymentScreen(booking: widget.booking),
                    ),
                  );
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),

                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Text(
                      "Pay Now",

                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),

                    SizedBox(width: 8),

                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
