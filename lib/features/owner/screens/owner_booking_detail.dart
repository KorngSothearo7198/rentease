import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/booking_model.dart';
import '../../../models/property_model.dart';
import '../../../models/user_model.dart';
import '../../../services/booking_service.dart';
import '../../../services/notification_service.dart';

class OwnerBookingDetailsScreen extends StatefulWidget {
  final BookingModel booking;

  const OwnerBookingDetailsScreen({super.key, required this.booking});

  @override
  State<OwnerBookingDetailsScreen> createState() =>
      _OwnerBookingDetailsScreenState();
}

class _OwnerBookingDetailsScreenState extends State<OwnerBookingDetailsScreen> {
  final BookingService _bookingService = BookingService();
  final ScrollController _scrollController = ScrollController();

  late String status;
  UserModel? renter;
  Property? property;
  bool isLoading = true;
  bool isProcessing = false;
  double _scrollOffset = 0.0;

  static const double _expandedHeight = 300.0;

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _card = Colors.white;
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  DateTime get startDate => widget.booking.startDate.toDate();
  DateTime get endDate => widget.booking.endDate.toDate();
  int get totalDays => widget.booking.totalDays;
  double get monthlyPrice => widget.booking.monthlyPrice;
  double get totalAmount => widget.booking.totalAmount;
  bool get isMonthlyRent => totalDays >= 30;
  int get totalMonths => (totalDays / 30).ceil();
  double get dailyPrice => monthlyPrice / 30;
  double get subtotal =>
      isMonthlyRent ? monthlyPrice * totalMonths : dailyPrice * totalDays;
  double get securityDeposit => isMonthlyRent ? monthlyPrice : dailyPrice;
  double get serviceFee {
    final fee = totalAmount - subtotal - securityDeposit;
    return fee < 0 ? 0 : fee;
  }

  @override
  void initState() {
    super.initState();
    status = widget.booking.status.toUpperCase();
    loadBookingData();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double get _collapseProgress {
    return (_scrollOffset / (_expandedHeight - kToolbarHeight)).clamp(0.0, 1.0);
  }

  Future<void> loadBookingData() async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.booking.renterId)
          .get();

      if (userSnapshot.exists) {
        renter = UserModel.fromMap(userSnapshot.data() as Map<String, dynamic>);
      }

      final propertySnapshot = await FirebaseFirestore.instance
          .collection("properties")
          .doc(widget.booking.houseId)
          .get();

      if (propertySnapshot.exists) {
        property = Property.fromMap(
          propertySnapshot.data() as Map<String, dynamic>,
          propertySnapshot.id,
        );
      }
    } catch (e) {
      debugPrint("LOAD BOOKING DETAIL ERROR : $e");
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _openImageViewer() {
    final url = property?.imageUrl ?? "";
    if (url.trim().isEmpty) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _FullScreenImage(url: url),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _onApprove() async {
    if (isProcessing) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF059669),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                const Text(
                  "Approve Booking?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),

                // Message
                Text(
                  "You are about to approve the booking request from "
                      "${renter?.fullName ?? "the renter"} for "
                      "\"${property?.title ?? "this property"}\".",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "The property will be marked as rented.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF64748B).withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 26),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Approve",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true || isProcessing) return;
    setState(() => isProcessing = true);

    try {
      await _bookingService.approveBooking(widget.booking);

      await NotificationService().createNotification(
        userId: widget.booking.renterId,
        ownerId: widget.booking.ownerId,
        bookingId: widget.booking.bookingId!,
        houseId: widget.booking.houseId,
        title: "Booking Approved",
        body:
        "Your booking for ${property?.title ?? "property"} has been approved.",
        type: "booking_approved",
      );

      if (mounted) {
        setState(() => status = "APPROVED");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Booking approved successfully"),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: const Color(0xFF0F172A),
          ),
        );
      }
    } catch (e) {
      debugPrint("APPROVE ERROR : $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to approve booking")),
        );
      }
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> _onReject() async {
    if (isProcessing) return;

    final TextEditingController reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: Color(0xFFDC2626),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                const Text(
                  "Reject Booking?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),

                // Message
                Text(
                  "Are you sure you want to reject the request from "
                      "${renter?.fullName ?? "this renter"}?",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 18),

                // Optional reason
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: "Reason (optional)",
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Reject",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true || isProcessing) return;
    setState(() => isProcessing = true);

    try {
      // Fixed: use rejectBooking instead of approveBooking
      await _bookingService.rejectBooking(widget.booking.bookingId!);

      await NotificationService().createNotification(
        userId: widget.booking.renterId,
        ownerId: widget.booking.ownerId,
        bookingId: widget.booking.bookingId!,
        houseId: widget.booking.houseId,
        title: "Booking Rejected",
        body:
        "Your booking request for ${property?.title ?? "property"} has been rejected."
            "${reasonController.text.trim().isNotEmpty ? " Reason: ${reasonController.text.trim()}" : ""}",
        type: "booking_rejected",
      );

      if (mounted) {
        setState(() => status = "REJECTED");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Booking rejected"),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: const Color(0xFF0F172A),
          ),
        );
      }
    } catch (e) {
      debugPrint("REJECT ERROR : $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to reject booking")),
        );
      }
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    final progress = _collapseProgress;
    final titleOpacity = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Collapsing property image ────────────────────
                SliverAppBar(
                  expandedHeight: _expandedHeight,
                  pinned: true,
                  stretch: true,
                  backgroundColor: _bg,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.92),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: _textPrimary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  title: Opacity(
                    opacity: titleOpacity,
                    child: Text(
                      property?.title ?? "Booking Details",
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  centerTitle: true,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [
                      StretchMode.zoomBackground,
                      StretchMode.blurBackground,
                    ],
                    background: GestureDetector(
                      onTap: _openImageViewer,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            property?.imageUrl ?? "",
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: _border,
                              child: const Icon(
                                Icons.home_rounded,
                                size: 64,
                                color: _textSecondary,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 120,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.65),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 20,
                            child: Opacity(
                              opacity: (1 - progress * 1.4).clamp(0.0, 1.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _statusBadge(status),
                                  const SizedBox(height: 8),
                                  Text(
                                    property?.title ?? "Property",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          property?.location ?? "",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.fullscreen_rounded,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              "View",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Content ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      children: [
                        // Status + dates (no Booking ID)
                        _buildCard(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Status",
                                    style: TextStyle(
                                      color: _textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  _statusBadge(status),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1, color: _border),
                              ),
                              _row(
                                "Period",
                                "${DateFormat('dd MMM yyyy').format(startDate)} – ${DateFormat('dd MMM yyyy').format(endDate)}",
                              ),
                              const SizedBox(height: 10),
                              _row(
                                "Duration",
                                "$totalDays day${totalDays > 1 ? 's' : ''}",
                              ),
                              const SizedBox(height: 10),
                              _row(
                                "Requested",
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(widget.booking.createdAt.toDate()),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Tenant
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Tenant",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: _primary.withOpacity(0.1),
                                    backgroundImage:
                                        renter?.profileImage != null &&
                                            renter!.profileImage!.isNotEmpty
                                        ? NetworkImage(renter!.profileImage!)
                                        : null,
                                    child:
                                        renter?.profileImage == null ||
                                            renter!.profileImage!.isEmpty
                                        ? const Icon(
                                            Icons.person_rounded,
                                            color: _primary,
                                            size: 28,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          renter?.fullName ?? "Unknown",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: _textPrimary,
                                          ),
                                        ),
                                        if (renter?.phone.trim().isNotEmpty ==
                                            true)
                                          Text(
                                            renter!.phone,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: _textSecondary,
                                            ),
                                          ),
                                        if (renter?.email.trim().isNotEmpty ==
                                            true)
                                          Text(
                                            renter!.email,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: _textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if ((renter?.occupation ?? "").isNotEmpty ||
                                  (renter?.gender ?? "").isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if ((renter?.gender ?? "").isNotEmpty)
                                      _chip(
                                        Icons.person_outline,
                                        renter!.gender,
                                      ),
                                    if ((renter?.age ?? 0) > 0)
                                      _chip(
                                        Icons.cake_outlined,
                                        "${renter!.age} yrs",
                                      ),
                                    if ((renter?.occupation ?? "").isNotEmpty)
                                      _chip(
                                        Icons.work_outline,
                                        renter!.occupation,
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Property summary
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Property",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _openImageViewer,
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        property?.imageUrl ?? "",
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 72,
                                          height: 72,
                                          color: _border,
                                          child: const Icon(
                                            Icons.home_rounded,
                                            color: _textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            property?.title ?? "",
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: _textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            property?.location ?? "",
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: _textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "\$${(property?.price ?? 0).toInt()}/mo",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: _primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.fullscreen_rounded,
                                      color: _textSecondary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                              if (property?.amenities.isNotEmpty == true) ...[
                                const SizedBox(height: 14),
                                const Text(
                                  "Facilities",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: property!.amenities
                                      .map(
                                        (a) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _bg,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(color: _border),
                                          ),
                                          child: Text(
                                            a,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: _textPrimary,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Rental details
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Rental Details",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _detailBox(
                                      "Check-in",
                                      DateFormat(
                                        "dd MMM yyyy",
                                      ).format(startDate),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _detailBox(
                                      "Check-out",
                                      DateFormat("dd MMM yyyy").format(endDate),
                                    ),
                                  ),
                                ],
                              ),
                              if ((widget.booking.note ?? "")
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _primary.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Note from renter",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.booking.note!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: _textPrimary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Payment (NO method — decided later)
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Payment Summary",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _paymentRow(
                                isMonthlyRent
                                    ? "Rent ($totalMonths mo)"
                                    : "Rent ($totalDays days)",
                                subtotal,
                              ),
                              _paymentRow("Security deposit", securityDeposit),
                              if (serviceFee > 0)
                                _paymentRow("Service fee", serviceFee),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(height: 1, color: _border),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Total",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _textPrimary,
                                    ),
                                  ),
                                  Text(
                                    "\$${totalAmount.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: _primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Payment method will be chosen by the renter after approval.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _textSecondary.withOpacity(0.9),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sticky actions for pending
          if (status == "PENDING")
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: _card,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: isProcessing ? null : _onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(
                            color: Color(0xFFFECACA),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Reject",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isProcessing ? null : _onApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Approve Request",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
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

  // ── Helpers ──────────────────────────────────────────────────

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card, // this is the Color constant — OK
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _statusBadge(String s) {
    Color bg;
    Color fg;
    switch (s) {
      case "APPROVED":
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF059669);
        break;
      case "REJECTED":
      case "CANCELLED":
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        s,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: _textSecondary),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailBox(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(String title, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: _textSecondary),
          ),
          Text(
            "\$${amount.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String url;

  const _FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  size: 64,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
          SafeArea(
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
