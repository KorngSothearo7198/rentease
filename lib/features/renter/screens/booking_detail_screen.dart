import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  String currentStatus = '';
  String? currentCancelReason;
  String currentPaymentStatus = '';

  Property? property;
  UserModel? owner;

  bool isLoading = true;
  bool isCancelling = false;
  bool isOpeningChat = false;

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _success = Color(0xFF059669);
  static const Color _warning = Color(0xFFD97706);
  static const Color _danger = Color(0xFFDC2626);

  Color get _background => Theme.of(context).colorScheme.surface;

  Color get _card => Theme.of(context).colorScheme.surfaceContainerHighest;

  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;

  Color get _textSecondary => Theme.of(context).colorScheme.onSurfaceVariant;

  Color get _border => Theme.of(context).dividerColor;

  bool get _isPaymentCompleted =>
      currentPaymentStatus.trim().toLowerCase() == 'paid';

  bool get _canCancelBooking {
    final status = currentStatus.trim().toLowerCase();

    return !_isPaymentCompleted &&
        (status == 'pending' || status == 'approved');
  }

  String get _displayStatus {
    final status = currentStatus.trim().toLowerCase();

    if (status == 'cancelled' || status == 'rejected') {
      return 'Cancelled';
    }

    if (_isPaymentCompleted) return 'Completed';
    if (status == 'approved') return 'Approved';
    if (status == 'pending') return 'Pending';

    return currentStatus;
  }

  @override
  void initState() {
    super.initState();

    currentStatus = widget.booking.status;
    currentCancelReason = widget.booking.cancelReason;
    currentPaymentStatus = widget.booking.paymentStatus ?? '';

    loadBookingDetail();
  }

  @override
  void dispose() {
    _cancelReasonController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD PROPERTY AND OWNER
  // ============================================================

  Future<void> loadBookingDetail() async {
    try {
      final firestore = FirebaseFirestore.instance;

      final houseId = widget.booking.houseId.trim();

      if (houseId.isNotEmpty) {
        final snapshot = await firestore
            .collection('properties')
            .doc(houseId)
            .get();

        if (snapshot.exists && snapshot.data() != null) {
          property = Property.fromMap(snapshot.data()!, snapshot.id);
        }
      }

      final ownerId = widget.booking.ownerId.trim();

      if (ownerId.isNotEmpty) {
        final snapshot = await firestore.collection('users').doc(ownerId).get();

        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          data['uid'] = snapshot.id;
          owner = UserModel.fromMap(data);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Load Booking Detail Error: $e');
      debugPrint('$stackTrace');
    }

    if (!mounted) return;

    setState(() => isLoading = false);
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: _background,
        body: const Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildPropertyHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOwnerCard(),
                  const SizedBox(height: 20),
                  _buildBookingSummary(),
                  const SizedBox(height: 28),
                  _sectionTitle(
                    'Booking details',
                    'Review your reservation information',
                  ),
                  const SizedBox(height: 14),
                  _buildBookingInformation(),
                  if (_isPaymentCompleted) ...[
                    const SizedBox(height: 20),
                    _buildPaymentNotice(),
                  ],
                  const SizedBox(height: 28),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROPERTY HEADER
  // ============================================================

  Widget _buildPropertyHeader() {
    final imageUrl = property?.imageUrl.trim() ?? '';

    return SliverAppBar(
      expandedHeight: 310,
      pinned: true,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _background,
      foregroundColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: Colors.black.withOpacity(0.32),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Go back',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _propertyImagePlaceholder(),
              )
            else
              _propertyImagePlaceholder(),

            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.18),
                    Colors.transparent,
                    Colors.black.withOpacity(0.82),
                  ],
                  stops: const [0, 0.35, 1],
                ),
              ),
            ),

            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statusBadge(_displayStatus),
                  const SizedBox(height: 12),
                  Text(
                    property?.title.trim().isNotEmpty == true
                        ? property!.title
                        : 'Rental Property',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                        size: 17,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          property?.location.trim().isNotEmpty == true
                              ? property!.location
                              : 'Location unavailable',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _propertyImagePlaceholder() {
    return Container(
      color: _card,
      alignment: Alignment.center,
      child: Icon(Icons.home_work_outlined, size: 68, color: _textSecondary),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.toLowerCase() == 'completed'
                ? Icons.check_circle_outline_rounded
                : status.toLowerCase() == 'cancelled'
                ? Icons.cancel_outlined
                : status.toLowerCase() == 'approved'
                ? Icons.verified_outlined
                : Icons.schedule_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OWNER CARD
  // ============================================================

  Widget _buildOwnerCard() {
    final name = owner?.fullName.trim().isNotEmpty == true
        ? owner!.fullName.trim()
        : 'Unknown Owner';

    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: owner == null ? null : _openOwnerProfile,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              _ownerAvatar(radius: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROPERTY OWNER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View owner profile',
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: _primary,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ownerAvatar({double radius = 24}) {
    final image = owner?.profileImage?.trim() ?? '';

    return CircleAvatar(
      radius: radius,
      backgroundColor: _primary.withOpacity(0.12),
      backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
      child: image.isEmpty
          ? Text(
              _ownerInitial(),
              style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.w800,
                fontSize: radius * 0.65,
              ),
            )
          : null,
    );
  }

  String _ownerInitial() {
    final name = owner?.fullName.trim() ?? '';
    return name.isNotEmpty ? name[0].toUpperCase() : 'O';
  }

  // ============================================================
  // BOOKING SUMMARY
  // ============================================================

  Widget _buildBookingSummary() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.calendar_month_rounded,
            label: 'RENTAL PERIOD',
            value:
                '${widget.booking.totalDays} ${widget.booking.totalDays == 1 ? 'day' : 'days'}',
            color: _primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            icon: Icons.payments_outlined,
            label: 'TOTAL AMOUNT',
            value: '\$${widget.booking.totalAmount.toStringAsFixed(2)}',
            color: _success,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w800,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: TextStyle(color: _textSecondary, fontSize: 12)),
      ],
    );
  }

  // ============================================================
  // BOOKING INFORMATION
  // ============================================================

  Widget _buildBookingInformation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border.withOpacity(0.45)),
      ),
      child: Column(
        children: [
          _detailRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Booking status',
            value: _displayStatus,
            valueColor: _statusColor(_displayStatus),
          ),
          _rowDivider(),
          _detailRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Payment status',
            value: _isPaymentCompleted ? 'Paid' : 'Unpaid',
            valueColor: _isPaymentCompleted ? _success : _warning,
          ),
          if (_isPaymentCompleted &&
              widget.booking.paymentMethod?.trim().isNotEmpty == true) ...[
            _rowDivider(),
            _detailRow(
              icon: Icons.credit_card_rounded,
              label: 'Payment method',
              value: widget.booking.paymentMethod!,
            ),
          ],
          _rowDivider(),
          _detailRow(
            icon: Icons.event_available_outlined,
            label: 'Start date',
            value: _formatDate(widget.booking.startDate),
          ),
          _rowDivider(),
          _detailRow(
            icon: Icons.event_busy_outlined,
            label: 'End date',
            value: _formatDate(widget.booking.endDate),
          ),
          _rowDivider(),
          _detailRow(
            icon: Icons.price_change_outlined,
            label: 'Monthly price',
            value: '\$${widget.booking.monthlyPrice.toStringAsFixed(2)}',
          ),
          _rowDivider(),
          _detailRow(
            icon: Icons.timelapse_rounded,
            label: 'Total duration',
            value:
                '${widget.booking.totalDays} ${widget.booking.totalDays == 1 ? 'day' : 'days'}',
          ),
          _rowDivider(),
          _detailRow(
            icon: Icons.receipt_long_outlined,
            label: 'Total amount',
            value: '\$${widget.booking.totalAmount.toStringAsFixed(2)}',
            bold: true,
          ),
          if (_isPaymentCompleted) ...[
            _rowDivider(),
            _detailRow(
              icon: Icons.verified_outlined,
              label: 'Paid amount',
              value: '\$${widget.booking.totalAmount.toStringAsFixed(2)}',
              valueColor: _success,
              bold: true,
            ),
          ],
          if (currentStatus.trim().toLowerCase() == 'cancelled' ||
              currentStatus.trim().toLowerCase() == 'rejected') ...[
            _rowDivider(),
            _detailRow(
              icon: Icons.info_outline_rounded,
              label: 'Cancellation reason',
              value: currentCancelReason?.trim().isNotEmpty == true
                  ? currentCancelReason!
                  : 'No reason provided',
              valueColor: _danger,
            ),
          ],
        ],
      ),
    );
  }

  Widget _rowDivider() {
    return Divider(height: 1, thickness: 0.7, color: _border.withOpacity(0.65));
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: _textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                color: valueColor ?? _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT NOTICE
  // ============================================================

  Widget _buildPaymentNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _success.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _success.withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: _success,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment completed',
                  style: TextStyle(
                    color: _success,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Your payment has been recorded. Booking cancellation is unavailable after payment.',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    height: 1.5,
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
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_canCancelBooking) ...[
          OutlinedButton.icon(
            onPressed: isCancelling ? null : _showCancelDialog,
            icon: const Icon(Icons.event_busy_outlined, size: 19),
            label: const Text('Cancel booking'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _danger,
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: _danger.withOpacity(0.45)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        ElevatedButton.icon(
          onPressed: isOpeningChat ? null : _contactHost,
          icon: isOpeningChat
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.chat_bubble_outline_rounded, size: 19),
          label: Text(isOpeningChat ? 'Opening chat...' : 'Contact host'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // OWNER PROFILE
  // ============================================================

  void _openOwnerProfile() {
    if (owner == null) return;

    final houseId = widget.booking.houseId.trim();

    if (houseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property information is missing.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final propertyName = property?.title.trim().isNotEmpty == true
        ? property!.title.trim()
        : 'Property';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.80,
          minChildSize: 0.50,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, __) {
            return OwnerPublicProfileScreen(
              owner: owner!,
              houseId: houseId,
              propertyName: propertyName,
            );
          },
        );
      },
    );
  }

  // ============================================================
  // CONTACT HOST
  // ============================================================

  Future<void> _contactHost() async {
    if (isOpeningChat) return;

    final renterId = widget.booking.renterId.trim();
    final ownerId = widget.booking.ownerId.trim();
    final houseId = widget.booking.houseId.trim();

    if (renterId.isEmpty || ownerId.isEmpty || houseId.isEmpty) {
      _showMessage('Booking or contact information is missing.');
      return;
    }

    setState(() => isOpeningChat = true);

    try {
      final propertyName = property?.title.trim().isNotEmpty == true
          ? property!.title.trim()
          : 'Property';

      final conversationId = _chatService.createConversationId(
        renterId,
        ownerId,
        houseId,
      );

      await _chatService.createConversation(
        conversationId: conversationId,
        renterId: renterId,
        ownerId: ownerId,
        houseId: houseId,
        propertyName: propertyName,
      );

      if (!mounted) return;

      setState(() => isOpeningChat = false);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            conversationId: conversationId,
            hostName: owner?.fullName.trim().isNotEmpty == true
                ? owner!.fullName.trim()
                : 'Host',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Contact Host Error: $e');

      if (!mounted) return;

      setState(() => isOpeningChat = false);

      _showMessage('Unable to open chat. Please try again.');
    }
  }

  // ============================================================
  // CANCEL DIALOG
  // ============================================================

  void _showCancelDialog() {
    if (!_canCancelBooking) {
      _showMessage('This booking cannot be cancelled.');
      return;
    }

    _cancelReasonController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: _danger.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.event_busy_rounded,
                          color: _danger,
                          size: 27,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Cancel this booking?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please tell us why you want to cancel this reservation.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _cancelReasonController,
                        maxLines: 3,
                        enabled: !isCancelling,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Enter your cancellation reason...',
                          filled: true,
                          fillColor: _card,
                          alignLabelWithHint: true,
                          contentPadding: const EdgeInsets.all(15),
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
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isCancelling
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                foregroundColor: _textPrimary,
                                side: BorderSide(color: _border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              child: const Text('Keep booking'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isCancelling
                                  ? null
                                  : () => _confirmCancel(
                                      dialogContext,
                                      setDialogState,
                                    ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                backgroundColor: _danger,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              child: isCancelling
                                  ? const SizedBox(
                                      width: 19,
                                      height: 19,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Confirm',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // CONFIRM CANCELLATION
  // ============================================================

  Future<void> _confirmCancel(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) async {
    final reason = _cancelReasonController.text.trim();

    if (reason.isEmpty) {
      _showMessage('Please enter a cancellation reason.');
      return;
    }

    if (!_canCancelBooking) {
      Navigator.pop(dialogContext);
      _showMessage(
        'This booking cannot be cancelled because payment is completed.',
      );
      return;
    }

    final bookingId = widget.booking.bookingId;

    if (bookingId == null || bookingId.trim().isEmpty) {
      _showMessage('Booking ID is missing.');
      return;
    }

    setState(() => isCancelling = true);
    setDialogState(() {});

    try {
      await _bookingService.cancelBooking(bookingId, reason);

      await _bookingService.createOwnerCancellationNotification(
        ownerId: widget.booking.ownerId,
        bookingId: bookingId,
        houseId: widget.booking.houseId,
        propertyName: property?.title ?? 'Rental Property',
        cancelReason: reason,
        bookingAmount: widget.booking.totalAmount,
      );

      if (!mounted) return;

      setState(() {
        currentStatus = 'Cancelled';
        currentCancelReason = reason;
        isCancelling = false;
      });

      _cancelReasonController.clear();

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }

      _showMessage('Booking cancelled successfully.', color: _success);
    } catch (e) {
      debugPrint('Cancel Booking Error: $e');

      if (!mounted) return;

      setState(() => isCancelling = false);

      if (dialogContext.mounted) {
        setDialogState(() {});
      }

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        color: _danger,
      );
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _showMessage(String message, {Color? color}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
      case 'completed':
        return _success;
      case 'pending':
        return _warning;
      case 'rejected':
      case 'cancelled':
        return _danger;
      default:
        return _primary;
    }
  }
}
