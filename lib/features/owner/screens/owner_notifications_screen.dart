import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/owner_notification_model.dart';
import '../../../services/owner_notification_service.dart';

class OwnerNotificationsScreen extends StatefulWidget {
  const OwnerNotificationsScreen({super.key});

  @override
  State<OwnerNotificationsScreen> createState() =>
      _OwnerNotificationsScreenState();
}

class _OwnerNotificationsScreenState extends State<OwnerNotificationsScreen>
    with SingleTickerProviderStateMixin {
  final OwnerNotificationService _notificationService =
  OwnerNotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final userId = user?.uid;

    if (userId == null || userId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Please login again.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 20,
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          StreamBuilder<List<OwnerNotificationModel>>(
            stream: _notificationService.userNotifications(userId),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final hasUnread =
              notifications.any((n) => !n.isRead);

              if (!hasUnread) return const SizedBox(width: 16);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: () async {
                    try {
                      await _notificationService.markAllAsRead(userId);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All notifications marked as read.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Unable to mark as read: $e'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text(
                    'Read all',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<OwnerNotificationModel>>(
        stream: _notificationService.userNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return RefreshIndicator(
              color: const Color(0xFF4F46E5),
              onRefresh: () async {
                setState(() {});
                await Future.delayed(const Duration(milliseconds: 300));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.72,
                    child: _buildEmptyState(),
                  ),
                ],
              ),
            );
          }

          final unread = notifications.where((n) => !n.isRead).toList();
          final read = notifications.where((n) => n.isRead).toList();

          return RefreshIndicator(
            color: const Color(0xFF4F46E5),
            onRefresh: () async {
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (unread.isNotEmpty) ...[
                  _buildSectionTitle('Unread', unread.length),
                  const SizedBox(height: 10),
                  ...unread.map(_buildNotificationCard),
                ],
                if (read.isNotEmpty) ...[
                  if (unread.isNotEmpty) const SizedBox(height: 8),
                  _buildSectionTitle('Earlier', read.length),
                  const SizedBox(height: 10),
                  ...read.map(_buildNotificationCard),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Section Title ───────────────────────────────────────────────
  Widget _buildSectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 2),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Color(0xFF4F46E5),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Notification Card ───────────────────────────────────────────
  Widget _buildNotificationCard(OwnerNotificationModel notification) {
    final iconData = _getNotificationIcon(notification.type);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: ValueKey(notification.notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFDC2626),
          size: 24,
        ),
      ),
      confirmDismiss: (_) => _showDeleteConfirmation(),
      onDismissed: (_) async {
        try {
          await _notificationService.deleteNotification(
            notification.notificationId,
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to delete: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () async {
          if (isUnread) {
            try {
              await _notificationService.markAsRead(notification.notificationId);
            } catch (_) {}
          }
          if (!mounted) return;
          _openNotification(notification);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFEEF2FF) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isUnread
                  ? const Color(0xFFC7D2FE)
                  : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(iconData, isUnread),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF0F172A),
                              fontSize: 14.5,
                              fontWeight:
                              isUnread ? FontWeight.w800 : FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4F46E5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatNotificationTime(notification.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (notification.relatedId != null &&
                            notification.relatedId!.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: Color(0xFFCBD5E1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getRelatedLabel(notification.relatedType),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(IconData icon, bool isUnread) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFFE0E7FF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        size: 22,
        color: isUnread ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
      ),
    );
  }

  // ─── Empty / Error ───────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 44,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No notifications',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You’re all caught up. New rental, payment, and subscription updates will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load notifications',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────
  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'payment':
      case 'rental_payment':
        return Icons.payments_rounded;
      case 'booking':
      case 'rental':
        return Icons.home_work_rounded;
      case 'subscription':
      case 'subscription_approved':
        return Icons.workspace_premium_rounded;
      case 'subscription_rejected':
        return Icons.cancel_outlined;
      case 'property':
        return Icons.home_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'success':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _getRelatedLabel(String? relatedType) {
    switch (relatedType?.toLowerCase()) {
      case 'payment':
        return 'Payment';
      case 'subscription':
        return 'Subscription';
      case 'booking':
        return 'Booking';
      case 'property':
        return 'Property';
      default:
        return 'Details';
    }
  }

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative || difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year}';
  }

  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Delete notification?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('This notification will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _openNotification(OwnerNotificationModel notification) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _NotificationDetailsSheet(
        notification: notification,
        getNotificationIcon: _getNotificationIcon,
        getRelatedLabel: _getRelatedLabel,
        formatNotificationTime: _formatNotificationTime,
      ),
    );
  }
}

// ============================================================================
// DETAILS BOTTOM SHEET
// ============================================================================

class PaymentNotificationDetails {
  final double bookingAmount;
  final String bookingCurrency;
  final String paymentMethod;
  final String status;
  final String paymentId;
  final String bookingId;
  final String houseId;
  final String renterId;
  final String ownerId;
  final String? renterName;
  final String? propertyName;
  final String? propertyAddress;
  final DateTime? paidAt;

  const PaymentNotificationDetails({
    required this.bookingAmount,
    required this.bookingCurrency,
    required this.paymentMethod,
    required this.status,
    required this.paymentId,
    required this.bookingId,
    required this.houseId,
    required this.renterId,
    required this.ownerId,
    this.renterName,
    this.propertyName,
    this.propertyAddress,
    this.paidAt,
  });

  factory PaymentNotificationDetails.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};
    return PaymentNotificationDetails(
      bookingAmount: _toDouble(data['bookingAmount']),
      bookingCurrency: data['bookingCurrency']?.toString() ?? 'USD',
      paymentMethod: data['paymentMethod']?.toString() ?? 'Bakong',
      status: data['status']?.toString() ?? 'Paid',
      paymentId: data['paymentId']?.toString() ?? doc.id,
      bookingId: data['bookingId']?.toString() ?? '',
      houseId: data['houseId']?.toString() ?? '',
      renterId: data['renterId']?.toString() ?? '',
      ownerId: data['ownerId']?.toString() ?? '',
      paidAt: _parseDate(data['paidAt']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  PaymentNotificationDetails copyWith({
    String? renterName,
    String? propertyName,
    String? propertyAddress,
  }) {
    return PaymentNotificationDetails(
      bookingAmount: bookingAmount,
      bookingCurrency: bookingCurrency,
      paymentMethod: paymentMethod,
      status: status,
      paymentId: paymentId,
      bookingId: bookingId,
      houseId: houseId,
      renterId: renterId,
      ownerId: ownerId,
      renterName: renterName ?? this.renterName,
      propertyName: propertyName ?? this.propertyName,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      paidAt: paidAt,
    );
  }
}

class _NotificationDetailsSheet extends StatefulWidget {
  final OwnerNotificationModel notification;
  final IconData Function(String type) getNotificationIcon;
  final String Function(String?) getRelatedLabel;
  final String Function(DateTime) formatNotificationTime;

  const _NotificationDetailsSheet({
    required this.notification,
    required this.getNotificationIcon,
    required this.getRelatedLabel,
    required this.formatNotificationTime,
  });

  @override
  State<_NotificationDetailsSheet> createState() =>
      _NotificationDetailsSheetState();
}

class _NotificationDetailsSheetState extends State<_NotificationDetailsSheet>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  PaymentNotificationDetails? _paymentDetails;
  bool _isLoadingPayment = false;
  String? _paymentError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _animationController.forward();
      _loadPaymentDetails();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentDetails() async {
    final notification = widget.notification;
    final type = notification.type.toLowerCase();
    final isPayment = type == 'payment' || type == 'rental_payment';

    if (!isPayment) return;

    final paymentId = notification.relatedId;
    if (paymentId == null || paymentId.trim().isEmpty) {
      setState(() => _paymentError = 'Payment information is unavailable.');
      return;
    }

    setState(() {
      _isLoadingPayment = true;
      _paymentError = null;
    });

    try {
      final paymentSnapshot =
      await _firestore.collection('payments').doc(paymentId).get();

      if (!paymentSnapshot.exists) {
        throw Exception('Payment information could not be found.');
      }

      var details = PaymentNotificationDetails.fromFirestore(paymentSnapshot);

      String? renterName;
      if (details.renterId.isNotEmpty) {
        final renterSnapshot =
        await _firestore.collection('users').doc(details.renterId).get();
        renterName = renterSnapshot.data()?['fullName']?.toString();
      }

      String? propertyName;
      String? propertyAddress;
      if (details.houseId.isNotEmpty) {
        final propertySnapshot =
        await _firestore.collection('properties').doc(details.houseId).get();
        final propertyData = propertySnapshot.data();
        if (propertyData != null) {
          propertyName = propertyData['propertyName']?.toString() ??
              propertyData['name']?.toString() ??
              propertyData['title']?.toString() ??
              'Rental Property';
          propertyAddress = propertyData['address']?.toString() ??
              propertyData['location']?.toString();
        }
      }

      details = details.copyWith(
        renterName: renterName,
        propertyName: propertyName,
        propertyAddress: propertyAddress,
      );

      if (!mounted) return;
      setState(() {
        _paymentDetails = details;
        _isLoadingPayment = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPayment = false;
        _paymentError = 'Unable to load payment details.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final type = notification.type.toLowerCase();
    final isPayment = type == 'payment' || type == 'rental_payment';
    final isSuccess = type == 'success' ||
        type == 'payment' ||
        type == 'rental_payment' ||
        type == 'subscription_approved';
    final icon = widget.getNotificationIcon(notification.type);

    return DraggableScrollableSheet(
      initialChildSize: isPayment ? 0.82 : 0.68,
      minChildSize: 0.48,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top bar
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Notification Details',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Header
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: _buildNotificationHeader(
                              notification,
                              icon,
                              isSuccess,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (isPayment)
                        _buildPaymentContent(notification)
                      else ...[
                        _buildMessageCard(notification),
                        _buildRelatedInformation(notification),
                      ],

                      const SizedBox(height: 14),
                      _buildDateInformation(notification),
                      const SizedBox(height: 22),

                      // Done button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
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
      },
    );
  }

  // ─── Payment Content ─────────────────────────────────────────────
  Widget _buildPaymentContent(OwnerNotificationModel notification) {
    if (_isLoadingPayment) return _buildLoadingPayment();
    if (_paymentError != null) return _buildPaymentError();
    final payment = _paymentDetails;
    if (payment == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildPaymentSuccessCard(payment),
        const SizedBox(height: 12),
        _buildAmountCard(payment),
        const SizedBox(height: 12),
        _buildPersonCard(payment),
        const SizedBox(height: 12),
        _buildPropertyCard(payment),
        const SizedBox(height: 12),
        _buildPaymentInformationCard(payment),
      ],
    );
  }

  Widget _buildLoadingPayment() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.8,
              color: Color(0xFF4F46E5),
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Loading payment details...',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Unable to load payment details.',
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSuccessCard(PaymentNotificationDetails payment) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFECFDF5), Color(0xFFF0FDFA)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF059669),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Received',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'The rental payment has been successfully received.',
                  style: TextStyle(
                    color: Color(0xFF047857),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(PaymentNotificationDetails payment) {
    final amount = payment.bookingAmount;
    final currency = payment.bookingCurrency;
    final symbol = currency.toUpperCase() == 'USD' ? '\$' : currency;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Payment Amount',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$symbol${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            currency,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              payment.status,
              style: const TextStyle(
                color: Color(0xFF047857),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonCard(PaymentNotificationDetails payment) {
    return _buildInfoCard(
      icon: Icons.person_outline_rounded,
      title: 'Renter',
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF4F46E5),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.renterName ?? 'Renter',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Rental customer',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(PaymentNotificationDetails payment) {
    return _buildInfoCard(
      icon: Icons.home_work_outlined,
      title: 'Property',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: Color(0xFF475569),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.propertyName ?? 'Rental Property',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (payment.propertyAddress != null &&
                    payment.propertyAddress!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    payment.propertyAddress!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      height: 1.35,
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

  Widget _buildPaymentInformationCard(PaymentNotificationDetails payment) {
    return _buildInfoCard(
      icon: Icons.receipt_long_outlined,
      title: 'Payment Information',
      child: Column(
        children: [
          _buildInfoRow(
            'Payment Method',
            payment.paymentMethod.isNotEmpty ? payment.paymentMethod : 'Bakong',
            Icons.account_balance_rounded,
          ),
          _buildInfoRow(
            'Currency',
            payment.bookingCurrency,
            Icons.currency_exchange_rounded,
          ),
          if (payment.paidAt != null)
            _buildInfoRow(
              'Paid On',
              _formatFullDate(payment.paidAt!),
              Icons.schedule_rounded,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF475569)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Non-payment ─────────────────────────────────────────────────
  Widget _buildMessageCard(OwnerNotificationModel notification) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 17,
                color: Color(0xFF475569),
              ),
              SizedBox(width: 8),
              Text(
                'Message',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            notification.body,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedInformation(OwnerNotificationModel notification) {
    return const SizedBox.shrink();
  }

  Widget _buildDateInformation(OwnerNotificationModel notification) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 17,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Received',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  widget.formatNotificationTime(notification.createdAt),
                  style: const TextStyle(
                    color: Color(0xFF475569),
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

  Widget _buildNotificationHeader(
      OwnerNotificationModel notification,
      IconData icon,
      bool isSuccess,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSuccess
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 28,
              color: isSuccess
                  ? const Color(0xFF059669)
                  : const Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatType(notification.type),
                    style: TextStyle(
                      color: isSuccess
                          ? const Color(0xFF047857)
                          : const Color(0xFF4338CA),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  notification.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
        ? 12
        : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthName(date.month)} '
        '${date.year}, '
        '$hour:$minute $period';
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  String _formatType(String type) {
    switch (type.toLowerCase()) {
      case 'payment':
      case 'rental_payment':
        return 'PAYMENT';
      case 'booking':
      case 'rental':
        return 'BOOKING';
      case 'subscription':
      case 'subscription_approved':
        return 'SUBSCRIPTION';
      case 'subscription_rejected':
        return 'REJECTED';
      case 'property':
        return 'PROPERTY';
      case 'warning':
        return 'WARNING';
      case 'success':
        return 'SUCCESS';
      default:
        return 'NOTIFICATION';
    }
  }
}