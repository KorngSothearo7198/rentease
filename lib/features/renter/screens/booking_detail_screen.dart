import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rentease/features/renter/screens/chat_list_screen.dart';

import '../../../models/booking_model.dart';
import '../../../models/property_model.dart';
import '../../../models/user_model.dart';
import '../../../services/booking_service.dart';
import '../../../services/chat_service.dart';
import '../../owner/screens/owner_public_profile_screen.dart';
import 'chat_detail_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final BookingService _bookingService = BookingService();
  final ChatService _chatService = ChatService();

  final TextEditingController _cancelReasonController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  String currentStatus = "";
  String? currentCancelReason;
  String currentPaymentStatus = "";

  Property? property;
  UserModel? owner;

  bool isLoading = true;
  bool isCancelling = false;

  double _scrollOffset = 0.0;

  static const double _expandedHeight = 320.0;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _primary = Color(0xFF4F46E5);

  static const Color _success = Color(0xFF059669);
  static const Color _warning = Color(0xFFD97706);
  static const Color _danger = Color(0xFFDC2626);

  // ============================================================
  // THEME COLORS
  // ============================================================

  Color get _background => Theme.of(context).colorScheme.surface;

  Color get _card => Theme.of(context).colorScheme.surfaceContainerHighest;

  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;

  Color get _textSecondary => Theme.of(context).colorScheme.onSurfaceVariant;

  Color get _border => Theme.of(context).dividerColor;

  Color get _inputBackground =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

  bool get _isPaymentCompleted {
    return currentPaymentStatus.trim().toLowerCase() == "paid";
  }

  String get _displayStatus {
    final status = currentStatus.trim().toLowerCase();

    if (status == "cancelled" || status == "rejected") {
      return "Cancelled";
    }

    if (_isPaymentCompleted) {
      return "Completed";
    }

    if (status == "approved") {
      return "Approved";
    }

    if (status == "pending") {
      return "Pending";
    }

    return currentStatus;
  }

  bool get _canCancelBooking {
    final status = currentStatus.trim().toLowerCase();

    if (_isPaymentCompleted) {
      return false;
    }

    if (status == "pending" || status == "approved") {
      return true;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();

    currentStatus = widget.booking.status;
    currentCancelReason = widget.booking.cancelReason;
    currentPaymentStatus = widget.booking.paymentStatus ?? "";

    loadBookingDetail();

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;

    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _cancelReasonController.dispose();

    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // COLLAPSE PROGRESS
  // ============================================================

  double get _collapseProgress {
    return (_scrollOffset / (_expandedHeight - kToolbarHeight)).clamp(0.0, 1.0);
  }

  Future<void> _contactHost() async {
    try {
      final renterId = widget.booking.renterId;
      final ownerId = widget.booking.ownerId;

      if (renterId.isEmpty || ownerId.isEmpty) {
        throw Exception("Renter or owner information is missing.");
      }

      // Create the same conversation ID for renter and owner.
      final conversationId = _chatService.createConversationId(
        renterId,
        ownerId,
      );

      // Create conversation if it does not already exist.
      await _chatService.createConversation(
        conversationId: conversationId,
        renterId: renterId,
        ownerId: ownerId,
        houseId: widget.booking.houseId,
        propertyName: property?.title ?? "Property",
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            conversationId: conversationId,
            hostName: owner?.fullName ?? "Host",
            propertyName: property?.title ?? "Property",
          ),
        ),
      );
    } catch (e) {
      debugPrint("Contact Host Error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Unable to open chat: $e")));
    }
  }

  // ============================================================
  // LOAD BOOKING DETAIL
  // ============================================================

  Future<void> loadBookingDetail() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // ========================================================
      // 1. GET PROPERTY
      // ========================================================

      final propertySnapshot = await firestore
          .collection('properties')
          .doc(widget.booking.houseId)
          .get();

      if (propertySnapshot.exists && propertySnapshot.data() != null) {
        property = Property.fromMap(
          propertySnapshot.data()!,
          propertySnapshot.id,
        );

        debugPrint('======================================');
        debugPrint('PROPERTY LOADED');
        debugPrint('House ID : ${widget.booking.houseId}');
        debugPrint('Title    : ${property?.title}');
        debugPrint('Location : ${property?.location}');
        debugPrint('======================================');
      }

      // ========================================================
      // 2. GET OWNER
      // ========================================================

      final ownerId = widget.booking.ownerId.trim();

      if (ownerId.isEmpty) {
        debugPrint('BOOKING HAS NO OWNER ID');
      } else {
        final ownerSnapshot = await firestore
            .collection('users')
            .doc(ownerId)
            .get();

        if (ownerSnapshot.exists && ownerSnapshot.data() != null) {
          final ownerData = ownerSnapshot.data()!;

          ownerData['uid'] = ownerSnapshot.id;

          debugPrint('======================================');
          debugPrint('OWNER FOUND');
          debugPrint('Document ID : ${ownerSnapshot.id}');
          debugPrint('Name        : ${ownerData['fullName']}');
          debugPrint('Email       : ${ownerData['email']}');
          debugPrint('Phone       : ${ownerData['phone']}');
          debugPrint('Profile     : ${ownerData['profileImage']}');
          debugPrint('======================================');

          owner = UserModel.fromMap(ownerData);
        } else {
          debugPrint('OWNER NOT FOUND: $ownerId');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('LOAD BOOKING DETAIL ERROR: $e');

      debugPrint('$stackTrace');
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: _background,
        body: const Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    final progress = _collapseProgress;

    final titleOpacity = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _background,

      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),

        slivers: [
          // ======================================================
          // COLLAPSING HEADER
          // ======================================================
          SliverAppBar(
            expandedHeight: _expandedHeight,

            pinned: true,
            stretch: true,

            backgroundColor: _background,

            elevation: 0,
            scrolledUnderElevation: 0,

            leading: Padding(
              padding: const EdgeInsets.all(8),

              child: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surface.withOpacity(0.90),

                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: _textPrimary,
                  ),

                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),

            title: Opacity(
              opacity: titleOpacity,

              child: Text(
                property?.title ?? 'Booking Details',

                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
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

              background: Stack(
                fit: StackFit.expand,

                children: [
                  // =================================================
                  // PROPERTY IMAGE
                  // =================================================
                  Image.network(
                    property?.imageUrl ?? "",

                    fit: BoxFit.cover,

                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: _background,

                        child: Icon(
                          Icons.home_rounded,
                          size: 64,
                          color: _textSecondary,
                        ),
                      );
                    },
                  ),

                  // =================================================
                  // IMAGE GRADIENT
                  // =================================================
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 140,

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

                  // =================================================
                  // PROPERTY TITLE
                  // =================================================
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,

                    child: Opacity(
                      opacity: (1.0 - progress * 1.4).clamp(0.0, 1.0),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          // STATUS
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),

                            decoration: BoxDecoration(
                              color: _statusColor(
                                _displayStatus,
                              ).withOpacity(0.90),

                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: Text(
                              _displayStatus.toUpperCase(),

                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            property?.title ?? "Rental Property",

                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,

                              shadows: [
                                Shadow(color: Colors.black45, blurRadius: 8),
                              ],
                            ),
                          ),

                          const SizedBox(height: 4),

                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.white70,
                              ),

                              const SizedBox(width: 4),

                              Expanded(
                                child: Text(
                                  property?.location ?? "No location",

                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),

                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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

          // ======================================================
          // CONTENT
          // ======================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // =================================================
                  // OWNER
                  // =================================================
                  GestureDetector(
                    onTap: owner == null ? null : _openOwnerProfile,

                    child: Container(
                      padding: const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: _card,

                        borderRadius: BorderRadius.circular(16),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),

                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,

                            backgroundColor: _primary.withOpacity(0.10),

                            child: ClipOval(child: _ownerSmallImage()),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(
                                  'Hosted by',

                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                const SizedBox(height: 2),

                                Text(
                                  owner?.fullName.trim().isNotEmpty == true
                                      ? owner!.fullName
                                      : 'Unknown Owner',

                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            Icons.chevron_right_rounded,
                            color: _textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =================================================
                  // QUICK INFO
                  // =================================================
                  Row(
                    children: [
                      _infoChip(
                        Icons.calendar_today_rounded,
                        "${widget.booking.totalDays} days",
                      ),

                      const SizedBox(width: 12),

                      _infoChip(
                        Icons.payments_outlined,
                        "\$${widget.booking.totalAmount.toStringAsFixed(2)}",
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // BOOKING INFORMATION
                  // =================================================
                  _sectionLabel("BOOKING INFORMATION"),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),

                    decoration: BoxDecoration(
                      color: _card,

                      borderRadius: BorderRadius.circular(18),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),

                    child: Column(
                      children: [
                        // STATUS
                        _detailRow(
                          "Status",
                          _displayStatus,
                          valueColor: _statusColor(_displayStatus),
                        ),

                        Divider(height: 1, color: _border),

                        // PAYMENT STATUS
                        _detailRow(
                          "Payment Status",
                          _isPaymentCompleted ? "Paid" : "Unpaid",
                          valueColor: _isPaymentCompleted ? _success : _warning,
                        ),

                        // PAYMENT METHOD
                        if (_isPaymentCompleted &&
                            widget.booking.paymentMethod != null &&
                            widget.booking.paymentMethod!
                                .trim()
                                .isNotEmpty) ...[
                          Divider(height: 1, color: _border),

                          _detailRow(
                            "Payment Method",
                            widget.booking.paymentMethod!,
                          ),
                        ],

                        Divider(height: 1, color: _border),

                        // START DATE
                        _detailRow(
                          "Start Date",
                          _formatDate(widget.booking.startDate),
                        ),

                        Divider(height: 1, color: _border),

                        // END DATE
                        _detailRow(
                          "End Date",
                          _formatDate(widget.booking.endDate),
                        ),

                        Divider(height: 1, color: _border),

                        // MONTHLY PRICE
                        _detailRow(
                          "Monthly Price",
                          "\$${widget.booking.monthlyPrice.toStringAsFixed(2)}",
                        ),

                        Divider(height: 1, color: _border),
                        _detailRow(
                          "Total Day",
                          "${widget.booking.totalDays} ${widget.booking.totalDays == 1 ? 'Day' : 'Days'}",
                          bold: true,
                        ),
                        // TOTAL
                        _detailRow(
                          "Total Amount",
                          "\$${widget.booking.totalAmount.toStringAsFixed(2)}",
                          bold: true,
                        ),

                        // PAID AMOUNT
                        if (_isPaymentCompleted) ...[
                          Divider(height: 1, color: _border),

                          _detailRow(
                            "Paid Amount",
                            "\$${widget.booking.totalAmount.toStringAsFixed(2)}",
                            // "${widget.booking.paidAmount?.toStringAsFixed(2)} ${widget.booking.paidCurrency ?? ''}",
                            valueColor: _success,
                          ),
                        ],

                        // CANCEL REASON
                        if (currentStatus.toLowerCase() == "cancelled") ...[
                          Divider(height: 1, color: _border),

                          _detailRow(
                            "Cancel Reason",
                            currentCancelReason ?? "No reason",
                            valueColor: _danger,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // =================================================
                  // PAYMENT COMPLETED MESSAGE
                  // =================================================
                  if (_isPaymentCompleted) ...[
                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,

                      padding: const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: _success.withOpacity(0.08),

                        borderRadius: BorderRadius.circular(14),

                        border: Border.all(color: _success.withOpacity(0.20)),
                      ),

                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Container(
                            width: 36,
                            height: 36,

                            decoration: BoxDecoration(
                              color: _success.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),

                            child: const Icon(
                              Icons.check_rounded,
                              color: _success,
                              size: 22,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(
                                  "Payment Completed",
                                  style: TextStyle(
                                    color: _textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  "This booking has already been paid. Cancellation is no longer available.",
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // =================================================
                  // CANCEL BUTTON
                  // =================================================
                  if (_canCancelBooking) ...[
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,

                      child: OutlinedButton.icon(
                        onPressed: isCancelling ? null : _showCancelDialog,

                        icon: const Icon(Icons.cancel_outlined, size: 20),

                        label: const Text(
                          "Cancel Booking",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        style: OutlinedButton.styleFrom(
                          foregroundColor: _danger,

                          side: BorderSide(
                            color: _danger.withOpacity(0.35),
                            width: 1.5,
                          ),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // =================================================
                  // CONTACT HOST
                  // =================================================
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _contactHost,
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 20,
                      ),
                      label: const Text(
                        "Contact Host",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OWNER PROFILE
  // ============================================================

  void _openOwnerProfile() {
    if (owner == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,

      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.80,
          minChildSize: 0.50,
          maxChildSize: 0.95,
          expand: false,

          builder: (context, scrollController) {
            return OwnerPublicProfileScreen(owner: owner!);
          },
        );
      },
    );
  }

  // ============================================================
  // SECTION LABEL
  // ============================================================

  Widget _sectionLabel(String title) {
    return Text(
      title,

      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: _textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  // ============================================================
  // INFO CHIP
  // ============================================================

  Widget _infoChip(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),

        decoration: BoxDecoration(
          color: _card,

          borderRadius: BorderRadius.circular(14),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),

              blurRadius: 10,

              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(icon, color: _primary, size: 18),

            const SizedBox(width: 8),

            Text(
              text,

              style: TextStyle(
                fontWeight: FontWeight.w600,

                fontSize: 14,

                color: _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OWNER IMAGE
  // ============================================================

  Widget _ownerSmallImage() {
    final image = owner?.profileImage?.trim();

    if (image == null || image.isEmpty) {
      return Center(
        child: Text(
          owner?.fullName.trim().isNotEmpty == true
              ? owner!.fullName.trim()[0].toUpperCase()
              : "O",

          style: const TextStyle(
            color: _primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Image.network(
      image,

      width: 48,
      height: 48,

      fit: BoxFit.cover,

      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Text(
            owner?.fullName.trim().isNotEmpty == true
                ? owner!.fullName.trim()[0].toUpperCase()
                : "O",

            style: const TextStyle(
              color: _primary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Text(
            label,

            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          Flexible(
            child: Text(
              value,

              textAlign: TextAlign.right,

              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,

                fontSize: bold ? 16 : 14,

                color: valueColor ?? _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CANCEL DIALOG
  // ============================================================

  void _showCancelDialog() {
    // ----------------------------------------------------------
    // Extra UI protection
    // ----------------------------------------------------------

    if (!_canCancelBooking) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This booking cannot be cancelled."),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    _cancelReasonController.clear();

    showDialog(
      context: context,

      barrierDismissible: false,

      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return Dialog(
          backgroundColor: theme.colorScheme.surface,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),

          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                // =================================================
                // ICON
                // =================================================
                Container(
                  width: 56,
                  height: 56,

                  decoration: BoxDecoration(
                    color: _danger.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.cancel_outlined,
                    size: 28,
                    color: _danger,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  "Cancel Booking?",

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Please provide a reason for cancellation.",

                  textAlign: TextAlign.center,

                  style: TextStyle(fontSize: 14, color: _textSecondary),
                ),

                const SizedBox(height: 18),

                // =================================================
                // REASON
                // =================================================
                TextField(
                  controller: _cancelReasonController,

                  maxLines: 3,

                  textInputAction: TextInputAction.newline,

                  style: TextStyle(color: _textPrimary),

                  decoration: InputDecoration(
                    hintText: "Example: Change of plan",

                    hintStyle: TextStyle(color: _textSecondary),

                    filled: true,

                    fillColor: _inputBackground,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),

                      borderSide: BorderSide(color: _border),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),

                      borderSide: BorderSide(color: _border),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),

                      borderSide: const BorderSide(color: _primary, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // =================================================
                // BUTTONS
                // =================================================
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,

                        child: OutlinedButton(
                          onPressed: isCancelling
                              ? null
                              : () {
                                  Navigator.pop(dialogContext);
                                },

                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textPrimary,

                            side: BorderSide(color: _border, width: 1.5),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),

                          child: const Text(
                            "Keep",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: SizedBox(
                        height: 48,

                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _danger,

                            foregroundColor: Colors.white,

                            elevation: 0,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),

                          onPressed: isCancelling ? null : _confirmCancel,

                          child: isCancelling
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Confirm",
                                  style: TextStyle(fontWeight: FontWeight.w700),
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
  }

  // ============================================================
  // CONFIRM CANCEL
  // ============================================================

  Future<void> _confirmCancel() async {
    final reason = _cancelReasonController.text.trim();

    // ==========================================================
    // VALIDATE REASON
    // ==========================================================

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter cancellation reason"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // ==========================================================
    // UI PROTECTION
    // ==========================================================

    if (!_canCancelBooking) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "This booking cannot be cancelled because payment has already been completed.",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    if (!mounted) return;

    setState(() {
      isCancelling = true;
    });

    try {
      // ========================================================
      // SERVICE
      //
      // The service MUST re-check Firebase paymentStatus.
      // ========================================================

      await _bookingService.cancelBooking(widget.booking.bookingId!, reason);

      if (!mounted) return;

      // ========================================================
      // UPDATE LOCAL UI
      // ========================================================

      setState(() {
        currentStatus = "Cancelled";
        currentCancelReason = reason;
        isCancelling = false;
      });

      _cancelReasonController.clear();

      // ========================================================
      // CLOSE DIALOG
      // ========================================================

      Navigator.pop(context);

      // ========================================================
      // SUCCESS MESSAGE
      // ========================================================

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Booking cancelled successfully"),

          behavior: SnackBarBehavior.floating,

          backgroundColor: _success,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      debugPrint("Cancel Booking Error: $e");

      if (!mounted) return;

      setState(() {
        isCancelling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),

          behavior: SnackBarBehavior.floating,

          backgroundColor: _danger,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(Timestamp date) {
    final d = date.toDate();

    return "${d.day}/${d.month}/${d.year}";
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return _success;

      case "pending":
        return _warning;

      case "completed":
        return _success;

      case "rejected":
      case "cancelled":
        return _danger;

      default:
        return _primary;
    }
  }
}
