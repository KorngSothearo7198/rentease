import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/owner_notification_model.dart';
import '../../../services/booking_service.dart';
import '../../../services/owner_notification_service.dart';
import 'owner_booking_detail.dart';

class OwnerNotificationsScreen extends StatefulWidget {
  const OwnerNotificationsScreen({super.key});

  @override
  State<OwnerNotificationsScreen> createState() =>
      _OwnerNotificationsScreenState();
}

class _OwnerNotificationsScreenState
    extends State<OwnerNotificationsScreen> {
  final OwnerNotificationService _notificationService =
  OwnerNotificationService();

  final BookingService _bookingService = BookingService();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _openingNotification = false;

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

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
              final hasUnread = notifications.any((n) => !n.isRead);

              if (!hasUnread) {
                return const SizedBox(width: 16);
              }

              return TextButton(
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
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                ),
                child: const Text(
                  'Read all',
                  style: TextStyle(fontWeight: FontWeight.w700),
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
              child: CircularProgressIndicator(
                color: Color(0xFF4F46E5),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
                await Future.delayed(
                  const Duration(milliseconds: 300),
                );
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
              await Future.delayed(
                const Duration(milliseconds: 300),
              );
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
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
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

  Widget _buildNotificationCard(
      OwnerNotificationModel notification,
      ) {
    final isUnread = !notification.isRead;
    final icon = _getNotificationIcon(notification.type);

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
              content: Text('Unable to delete notification: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread
                ? const Color(0xFFEEF2FF)
                : Colors.white,
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
              _buildNotificationIcon(icon, isUnread),
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
                              fontWeight: isUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
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
                        Expanded(
                          child: Text(
                            _formatNotificationTime(
                              notification.createdAt,
                            ),
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (notification.relatedId != null &&
                            notification.relatedId!.isNotEmpty) ...[
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
                            _getRelatedLabel(
                              notification.relatedType,
                            ),
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

  Future<void> _handleNotificationTap(
      OwnerNotificationModel notification,
      ) async {
    if (_openingNotification) return;

    _openingNotification = true;

    try {
      if (!notification.isRead) {
        try {
          await _notificationService.markAsRead(
            notification.notificationId,
          );
        } catch (e) {
          debugPrint('Mark notification as read error: $e');
        }
      }

      if (!mounted) return;

      final type = notification.type.toLowerCase();
      final relatedType = notification.relatedType?.toLowerCase();

      final isBookingNotification =
          relatedType == 'booking' ||
              type == 'booking_cancelled' ||
              type == 'booking' ||
              type == 'rental';

      if (isBookingNotification) {
        final String? bookingId =
        (notification.bookingId != null &&
            notification.bookingId!.trim().isNotEmpty)
            ? notification.bookingId!.trim()
            : (relatedType == 'booking' &&
            notification.relatedId != null &&
            notification.relatedId!.trim().isNotEmpty)
            ? notification.relatedId!.trim()
            : null;

        if (bookingId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Booking ID is missing in this notification.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        final booking = await _bookingService.getBookingById(bookingId);

        if (!mounted) return;

        if (booking == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking details could not be found.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OwnerBookingDetailsScreen(
              booking: booking,
            ),
          ),
        );

        return;
      }

      // Payment and other notifications keep their existing details sheet.
      _openNotification(notification);
    } catch (e, stackTrace) {
      debugPrint('Open notification error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open notification. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _openingNotification = false;
    }
  }

  Widget _buildNotificationIcon(IconData icon, bool isUnread) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isUnread
            ? const Color(0xFFE0E7FF)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        size: 22,
        color: isUnread
            ? const Color(0xFF4F46E5)
            : const Color(0xFF64748B),
      ),
    );
  }

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
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFDC2626),
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
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'payment':
      case 'rental_payment':
        return Icons.payments_rounded;
      case 'booking':
      case 'rental':
        return Icons.home_work_rounded;
      case 'booking_cancelled':
        return Icons.event_busy_rounded;
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

    if (difference.isNegative || difference.inSeconds < 60) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year}';
  }

  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Delete notification?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'This notification will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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
// NOTIFICATION DETAILS SHEET
// Payment notification details are loaded from Firestore.
// ============================================================================

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

class _NotificationDetailsSheetState
    extends State<_NotificationDetailsSheet> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _paymentData;
  bool _loadingPayment = false;
  String? _paymentError;

  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
  }

  Future<void> _loadPaymentDetails() async {
    final notification = widget.notification;
    final type = notification.type.toLowerCase();

    if (type != 'payment' && type != 'rental_payment') return;

    final paymentId = notification.paymentId ??
        notification.relatedId;

    if (paymentId == null || paymentId.trim().isEmpty) {
      setState(() {
        _paymentError = 'Payment information is unavailable.';
      });
      return;
    }

    setState(() {
      _loadingPayment = true;
      _paymentError = null;
    });

    try {
      final snapshot = await _firestore
          .collection('payments')
          .doc(paymentId)
          .get();

      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('Payment not found');
      }

      if (!mounted) return;

      setState(() {
        _paymentData = snapshot.data();
        _loadingPayment = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingPayment = false;
        _paymentError = 'Unable to load payment details.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final type = notification.type.toLowerCase();
    final isPayment = type == 'payment' || type == 'rental_payment';

    return DraggableScrollableSheet(
      initialChildSize: isPayment ? 0.82 : 0.68,
      minChildSize: 0.48,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
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
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Notification Details',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildHeader(notification),
                    const SizedBox(height: 14),
                    _buildMessage(notification),
                    if (isPayment) ...[
                      const SizedBox(height: 12),
                      _buildPaymentContent(notification),
                    ],
                    const SizedBox(height: 14),
                    _buildReceivedDate(notification),
                    const SizedBox(height: 22),
                    SizedBox(
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(OwnerNotificationModel notification) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              widget.getNotificationIcon(notification.type),
              color: const Color(0xFF4F46E5),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  notification.type
                      .replaceAll('_', ' ')
                      .toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontSize: 10,
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

  Widget _buildMessage(OwnerNotificationModel notification) {
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
          const Text(
            'Message',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
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

  Widget _buildPaymentContent(
      OwnerNotificationModel notification,
      ) {
    if (_loadingPayment) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(
            color: Color(0xFF4F46E5),
          ),
        ),
      );
    }

    if (_paymentError != null) {
      return _infoCard(
        'Payment details',
        _paymentError!,
      );
    }

    final data = _paymentData;
    if (data == null) {
      return _infoCard(
        'Payment details',
        'No payment details available.',
      );
    }

    final amountValue = data['bookingAmount'] ??
        data['amount'] ??
        notification.amount ??
        0;

    final amount = amountValue is num
        ? amountValue.toDouble()
        : double.tryParse(amountValue.toString()) ?? 0;

    final currency = (data['bookingCurrency'] ??
        data['currency'] ??
        notification.currency ??
        'USD')
        .toString();

    final method = (data['paymentMethod'] ?? 'Bakong').toString();
    final status = (data['status'] ?? 'Paid').toString();

    return Column(
      children: [
        _infoCard(
          'Payment Amount',
          '${currency.toUpperCase() == 'USD' ? '\$' : ''}'
              '${amount.toStringAsFixed(2)} $currency',
        ),
        const SizedBox(height: 10),
        _infoCard('Payment Method', method),
        const SizedBox(height: 10),
        _infoCard('Payment Status', status),
        if ((data['bookingId'] ?? notification.bookingId) != null) ...[
          const SizedBox(height: 10),
          _infoCard(
            'Booking ID',
            (data['bookingId'] ?? notification.bookingId).toString(),
          ),
        ],
      ],
    );
  }

  Widget _infoCard(String title, String value) {
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
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedDate(
      OwnerNotificationModel notification,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
                const SizedBox(height: 2),
                Text(
                  widget.formatNotificationTime(
                    notification.createdAt,
                  ),
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
}