import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/booking_model.dart';
import '../../../models/property_model.dart';
import '../../../services/booking_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/owner_notification_service.dart';

class RequestBookingScreen extends StatefulWidget {
  final Property property;

  const RequestBookingScreen({super.key, required this.property});

  @override
  State<RequestBookingScreen> createState() => _RequestBookingScreenState();
}

class _RequestBookingScreenState extends State<RequestBookingScreen> {
  final BookingService bookingService = BookingService();
  final ChatService chatService = ChatService();
  final OwnerNotificationService notificationService =
      OwnerNotificationService();

  final TextEditingController _noteController = TextEditingController();

  late Property property;

  DateTime? startDate;
  DateTime? endDate;

  int guests = 2;
  bool _isSubmitting = false;

  // ============================================================
  // VALIDATION
  // ============================================================

  bool _startDateError = false;
  bool _endDateError = false;

  String _startDateErrorText = '';
  String _endDateErrorText = '';

  // ============================================================
  // DESIGN
  // ============================================================

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _error = Color(0xFFEF4444);

  // Light mode
  static const Color _lightBg = Color(0xFFF8FAFC);
  static const Color _lightCard = Colors.white;
  static const Color _lightTextPrimary = Color(0xFF0F172A);
  static const Color _lightTextSecondary = Color(0xFF64748B);
  static const Color _lightBorder = Color(0xFFE2E8F0);

  // Dark mode
  static const Color _darkBg = Color(0xFF0F1115);
  static const Color _darkCard = Color(0xFF181B21);
  static const Color _darkTextPrimary = Color(0xFFF8FAFC);
  static const Color _darkTextSecondary = Color(0xFF94A3B8);
  static const Color _darkBorder = Color(0xFF2A2F38);

  // ============================================================
  // THEME COLORS
  // ============================================================

  Color get _bg =>
      Theme.of(context).brightness == Brightness.dark ? _darkBg : _lightBg;

  Color get _card =>
      Theme.of(context).brightness == Brightness.dark ? _darkCard : _lightCard;

  Color get _textPrimary => Theme.of(context).brightness == Brightness.dark
      ? _darkTextPrimary
      : _lightTextPrimary;

  Color get _textSecondary => Theme.of(context).brightness == Brightness.dark
      ? _darkTextSecondary
      : _lightTextSecondary;

  Color get _border => Theme.of(context).brightness == Brightness.dark
      ? _darkBorder
      : _lightBorder;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    property = widget.property;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ============================================================
  // PRICING
  // ============================================================

  double get monthlyPrice => property.price;

  double get dailyPrice => monthlyPrice / 30;

  int get numberOfNights {
    if (startDate == null || endDate == null) {
      return 0;
    }

    return endDate!.difference(startDate!).inDays;
  }

  double get subtotal => dailyPrice * numberOfNights;

  double get serviceFee => subtotal * 0.05;

  double get taxes => subtotal * 0.06;

  double get total => subtotal + serviceFee + taxes;

  // ============================================================
  // VALIDATION
  // ============================================================

  bool _validateBooking() {
    bool valid = true;

    setState(() {
      _startDateError = false;
      _endDateError = false;

      _startDateErrorText = '';
      _endDateErrorText = '';

      // ----------------------------------------------------------
      // CHECK-IN
      // ----------------------------------------------------------

      if (startDate == null) {
        _startDateError = true;
        _startDateErrorText = 'Please select check-in date';
        valid = false;
      }

      // ----------------------------------------------------------
      // CHECK-OUT
      // ----------------------------------------------------------

      if (endDate == null) {
        _endDateError = true;
        _endDateErrorText = 'Please select check-out date';
        valid = false;
      }

      // ----------------------------------------------------------
      // DATE RANGE
      // ----------------------------------------------------------

      if (startDate != null &&
          endDate != null &&
          !endDate!.isAfter(startDate!)) {
        _startDateError = true;
        _endDateError = true;

        _startDateErrorText = 'Invalid date';
        _endDateErrorText = 'Must be after check-in';

        valid = false;
      }
    });

    return valid;
  }

  void _clearStartDateError() {
    if (!_startDateError) return;

    setState(() {
      _startDateError = false;
      _startDateErrorText = '';
    });
  }

  void _clearEndDateError() {
    if (!_endDateError) return;

    setState(() {
      _endDateError = false;
      _endDateErrorText = '';
    });
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate({required bool isStart}) async {
    final now = DateTime.now();

    final initial = isStart
        ? (startDate ?? now)
        : (endDate ??
              startDate?.add(const Duration(days: 1)) ??
              now.add(const Duration(days: 1)));

    final firstDate = isStart
        ? DateTime(now.year, now.month, now.day)
        : (startDate?.add(const Duration(days: 1)) ??
              DateTime(now.year, now.month, now.day));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 1, now.month, now.day),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: _primary,
                    onPrimary: Colors.white,
                    surface: _darkCard,
                    onSurface: _darkTextPrimary,
                  )
                : const ColorScheme.light(
                    primary: _primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: _lightTextPrimary,
                  ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        startDate = picked;

        _startDateError = false;
        _startDateErrorText = '';

        // Automatically create a valid checkout date
        // if checkout is missing or invalid.
        if (endDate == null || !endDate!.isAfter(picked)) {
          endDate = picked.add(const Duration(days: 1));

          _endDateError = false;
          _endDateErrorText = '';
        }
      } else {
        endDate = picked;

        if (startDate != null && picked.isAfter(startDate!)) {
          _endDateError = false;
          _endDateErrorText = '';
        } else {
          _endDateError = true;
          _endDateErrorText = 'Must be after check-in';
        }
      }
    });
  }

  // ============================================================
  // IMAGE VIEWER
  // ============================================================

  void _openImageViewer() {
    final url = property.imageUrl;

    if (url.trim().isEmpty) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _ImageViewer(imageUrl: url),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // ============================================================
  // BOOKING
  // ============================================================

  Future<void> sendBookingRequest() async {
    final user = FirebaseAuth.instance.currentUser;

    // Extra validation before sending.
    if (user == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please sign in before making a booking."),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      return;
    }

    if (!_validateBooking()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // ============================================================
      // CREATE BOOKING
      // ============================================================

      final booking = BookingModel(
        renterId: user.uid,
        ownerId: property.ownerId,
        houseId: property.id,

        startDate: Timestamp.fromDate(startDate!),
        endDate: Timestamp.fromDate(endDate!),

        totalDays: numberOfNights,

        monthlyPrice: property.price,
        totalAmount: total,

        status: "Pending",
        paymentStatus: "PENDING",
        paymentId: "",

        note: _noteController.text.trim().isEmpty
            ? "I want to rent this house"
            : _noteController.text.trim(),

        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      // ============================================================
      // SAVE BOOKING TO FIRESTORE
      // ============================================================

      final bookingId = await bookingService.createBooking(booking);

      if (bookingId == null) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }

        return;
      }

      // ============================================================
      // OWNER NOTIFICATION
      // ============================================================

      await notificationService.createNotification(
        userId: property.ownerId,
        role: 'owner',
        title: 'New Booking Request',
        body: 'A renter has requested to book ${property.title}.',
        type: 'rental',
        relatedId: bookingId,
        relatedType: 'booking',
        bookingId: bookingId,
        houseId: property.id,
      );

      // ============================================================
      // CREATE CHAT CONVERSATION
      // ============================================================

      final conversationId = chatService.createConversationId(
        user.uid,
        property.ownerId,
      );

      await chatService.createConversation(
        conversationId: conversationId,
        renterId: user.uid,
        ownerId: property.ownerId,
        houseId: property.id,
        propertyName: property.title,
      );

      // ============================================================
      // SUCCESS
      // ============================================================

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Booking request sent successfully",
            style: TextStyle(
              color: _isDark
                  ? _lightTextPrimary
                  : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor:
          _isDark ? Colors.white : _lightTextPrimary,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint("Booking Error: $e");

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send booking request: $e"),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // CONFIRM BOOKING DIALOG
  // ============================================================

  Future<void> _showBookingDialog() async {
    // Validate first.
    if (!_validateBooking()) {
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final dialogCard = isDark ? _darkCard : _lightCard;

        final primaryText = isDark ? _darkTextPrimary : _lightTextPrimary;

        final secondaryText = isDark ? _darkTextSecondary : _lightTextSecondary;

        final border = isDark ? _darkBorder : _lightBorder;

        return Dialog(
          backgroundColor: dialogCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ==================================================
                // ICON
                // ==================================================
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.home_work_outlined,
                    color: _primary,
                    size: 28,
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // TITLE
                // ==================================================
                Text(
                  "Confirm Booking",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: primaryText,
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // BOOKING INFORMATION
                // ==================================================
                _confirmRow(
                  "Property",
                  property.title,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),

                _confirmRow(
                  "Dates",
                  "${DateFormat('MMM d').format(startDate!)} – "
                      "${DateFormat('MMM d, yyyy').format(endDate!)}",
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),

                _confirmRow(
                  "Duration",
                  "$numberOfNights day${numberOfNights == 1 ? '' : 's'}",
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),

                _confirmRow(
                  "Guests",
                  "$guests",
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),

                _confirmRow(
                  "Total",
                  "\$${total.toStringAsFixed(2)}",
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: border),
                ),

                Text(
                  "Send this booking request to the host?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: secondaryText),
                ),

                const SizedBox(height: 22),

                // ==================================================
                // BUTTONS
                // ==================================================
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: ButtonStyle(
                            foregroundColor: WidgetStateProperty.all(
                              primaryText,
                            ),
                            side: WidgetStateProperty.all(
                              BorderSide(color: border),
                            ),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(fontWeight: FontWeight.w700),
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
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(_primary),
                            foregroundColor: WidgetStateProperty.all(
                              Colors.white,
                            ),
                            elevation: WidgetStateProperty.all(0),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          child: const Text(
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

    if (result == true) {
      await sendBookingRequest();
    }
  }

  // ============================================================
  // CONFIRM ROW
  // ============================================================

  Widget _confirmRow(
    String label,
    String value, {
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d');
    final yearFormat = DateFormat('yyyy');

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
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Request Booking",
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
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // PROPERTY CARD
                  // ==================================================
                  Container(
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            _isDark ? 0.25 : 0.04,
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
                        onTap: _openImageViewer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // IMAGE
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      property.imageUrl,
                                      width: 92,
                                      height: 92,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 92,
                                        height: 92,
                                        color: _border,
                                        child: Icon(
                                          Icons.home_rounded,
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 6,
                                    bottom: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.fullscreen_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 14),

                              // INFORMATION
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (property.category.trim().isNotEmpty)
                                      Text(
                                        property.category.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _primary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),

                                    const SizedBox(height: 4),

                                    Text(
                                      property.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _textPrimary,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: _textSecondary,
                                        ),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            property.location,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      "\$${property.price.toInt()}/mo",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: _primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // DATES
                  // ==================================================
                  _sectionTitle("Select dates"),

                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _dateCard(
                          label: "CHECK-IN",
                          date: startDate,
                          dateFormat: dateFormat,
                          yearFormat: yearFormat,
                          icon: Icons.login_rounded,
                          hasError: _startDateError,
                          errorText: _startDateErrorText,
                          onTap: () => _selectDate(isStart: true),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(top: 24),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: _primary,
                          ),
                        ),
                      ),

                      Expanded(
                        child: _dateCard(
                          label: "CHECK-OUT",
                          date: endDate,
                          dateFormat: dateFormat,
                          yearFormat: yearFormat,
                          icon: Icons.logout_rounded,
                          hasError: _endDateError,
                          errorText: _endDateErrorText,
                          onTap: () => _selectDate(isStart: false),
                        ),
                      ),
                    ],
                  ),

                  if (numberOfNights > 0) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "$numberOfNights night${numberOfNights > 1 ? 's' : ''}",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ==================================================
                  // GUESTS
                  // ==================================================
                  _sectionTitle("Guests"),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            _isDark ? 0.25 : 0.03,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.people_outline_rounded,
                            color: _primary,
                            size: 20,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            "Number of guests",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                        ),

                        _counterButton(
                          Icons.remove_rounded,
                          onTap: () {
                            if (guests > 1) {
                              setState(() => guests--);
                            }
                          },
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            "$guests",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                        ),

                        _counterButton(
                          Icons.add_rounded,
                          onTap: () {
                            setState(() => guests++);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // PRICE DETAILS
                  // ==================================================
                  _sectionTitle("Price details"),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            _isDark ? 0.25 : 0.03,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _priceRow(
                          "\$${dailyPrice.toStringAsFixed(2)} × $numberOfNights nights",
                          subtotal,
                        ),

                        _priceRow("Service fee (5%)", serviceFee),

                        _priceRow("Tax (6%)", taxes),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, color: _border),
                        ),

                        _priceRow("Total", total, isTotal: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // MESSAGE
                  // ==================================================
                  _sectionTitle("Message to host"),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    style: TextStyle(fontSize: 14, color: _textPrimary),
                    decoration: InputDecoration(
                      hintText: "Introduce yourself and share trip details…",
                      hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
                      filled: true,
                      fillColor: _card,
                      contentPadding: const EdgeInsets.all(16),
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
                        borderSide: const BorderSide(
                          color: _primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // CANCELLATION NOTE
                  // ==================================================
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isDark
                          ? const Color(0xFF063B2B)
                          : const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Free cancellation within 48 hours of booking.",
                            style: TextStyle(
                              fontSize: 13,
                              color: _isDark
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFF065F46),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "By sending a request, you agree to the house rules and cancellation policy.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ========================================================
          // STICKY SEND BUTTON
          // ========================================================
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: BoxDecoration(
              color: _card,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isDark ? 0.35 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _showBookingDialog,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return _primary.withOpacity(0.45);
                    }

                    return _primary;
                  }),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                  elevation: WidgetStateProperty.all(0),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Send Booking Request",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: _textPrimary,
      ),
    );
  }

  // ============================================================
  // DATE CARD
  // ============================================================

  Widget _dateCard({
    required String label,
    required DateTime? date,
    required DateFormat dateFormat,
    required DateFormat yearFormat,
    required IconData icon,
    required VoidCallback onTap,
    required bool hasError,
    required String errorText,
  }) {
    final hasDate = date != null;

    final borderColor = hasError
        ? _error
        : hasDate
        ? _primary.withOpacity(0.35)
        : _border;

    final iconColor = hasError
        ? _error
        : hasDate
        ? _primary
        : _textSecondary;

    final textColor = hasError
        ? _error
        : hasDate
        ? _textPrimary
        : _textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: hasError ? 1.8 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: iconColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: iconColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    hasDate ? dateFormat.format(date) : "Select date",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),

                  if (hasDate) ...[
                    const SizedBox(height: 2),
                    Text(
                      yearFormat.format(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // ========================================================
        // ERROR MESSAGE
        // ========================================================
        if (hasError && errorText.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: _error,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // COUNTER BUTTON
  // ============================================================

  Widget _counterButton(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: _isDark ? const Color(0xFF22262E) : _lightBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 18, color: _textPrimary),
        ),
      ),
    );
  }

  // ============================================================
  // PRICE ROW
  // ============================================================

  Widget _priceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 15 : 14,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                color: isTotal ? _textPrimary : _textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "\$${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isTotal ? _primary : _textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FULL SCREEN IMAGE VIEWER
// ============================================================

class _ImageViewer extends StatelessWidget {
  final String imageUrl;

  const _ImageViewer({required this.imageUrl});

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
                imageUrl,
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
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
