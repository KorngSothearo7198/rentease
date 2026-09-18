import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/notification_model.dart';
import '../../../services/booking_service.dart';
import '../../../services/notification_service.dart';
import 'notification_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  NotificationsScreen({super.key});

  final NotificationService notificationService = NotificationService();
  final BookingService bookingService = BookingService();

  // ============================================================
  // TIME FORMAT
  // ============================================================

  String formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();

    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    }

    if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    }

    return "${diff.inDays}d ago";
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // Get current theme colors
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;

    // ==========================================================
    // THEME COLORS
    // ==========================================================

    final backgroundColor = colorScheme.surface;

    final appBarColor = colorScheme.surface;

    final cardColor = colorScheme.surfaceContainerHighest;

    final primaryText = colorScheme.onSurface;

    final secondaryText = colorScheme.onSurfaceVariant;

    final borderColor = colorScheme.outlineVariant;

    return Scaffold(
      backgroundColor: backgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: appBarColor,

        elevation: 0,

        scrolledUnderElevation: 0,

        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryText),
          onPressed: () => Navigator.pop(context),
        ),

        title: Text(
          'Notifications',
          style: TextStyle(
            color: primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),

        centerTitle: true,
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: StreamBuilder<List<NotificationModel>>(
        stream: notificationService.getNotifications(
          FirebaseAuth.instance.currentUser!.uid,
        ),

        builder: (context, snapshot) {
          // ======================================================
          // LOADING
          // ======================================================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }

          // ======================================================
          // ERROR
          // ======================================================

          if (snapshot.hasError) {
            debugPrint("STREAM ERROR: ${snapshot.error}");

            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: TextStyle(color: primaryText),
              ),
            );
          }

          // ======================================================
          // EMPTY
          // ======================================================

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            debugPrint("NO NOTIFICATIONS");

            return Center(
              child: Text(
                "No notifications",
                style: TextStyle(color: secondaryText, fontSize: 15),
              ),
            );
          }

          // ======================================================
          // NOTIFICATIONS
          // ======================================================

          final notifications = snapshot.data!;

          debugPrint("TOTAL NOTIFICATIONS: ${notifications.length}");

          for (var notification in notifications) {
            debugPrint("----------------------------");
            debugPrint("ID       : ${notification.id}");
            debugPrint("Title    : ${notification.title}");
            debugPrint("Body     : ${notification.body}");
            debugPrint("Type     : ${notification.type}");
            debugPrint("User ID  : ${notification.userId}");
            debugPrint("Booking  : ${notification.bookingId}");
            debugPrint("House ID : ${notification.houseId}");
            debugPrint("Read     : ${notification.isRead}");
            debugPrint("Date     : ${notification.createdAt.toDate()}");
            debugPrint("----------------------------");
          }

          // ======================================================
          // LIST
          // ======================================================

          return ListView.builder(
            padding: const EdgeInsets.all(20),

            itemCount: notifications.length,

            itemBuilder: (context, index) {
              final notification = notifications[index];

              final notificationColor = getNotificationColor(notification.type);

              return GestureDetector(
                onTap: () async {
                  // =================================================
                  // 1. MARK AS READ
                  // =================================================

                  if (!notification.isRead) {
                    await notificationService.markAsRead(notification.id);
                  }

                  // =================================================
                  // 2. GET BOOKING
                  // =================================================

                  final booking = await bookingService.getBookingById(
                    notification.bookingId,
                  );

                  if (booking == null) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Booking not found"),
                        backgroundColor: colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    return;
                  }

                  // =================================================
                  // 3. OPEN DETAIL
                  // =================================================

                  if (!context.mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationDetailScreen(
                        notification: notification,
                        booking: booking,
                      ),
                    ),
                  );
                },

                child: _notificationCard(
                  title: notification.title,

                  time: formatTime(notification.createdAt),

                  isUnread: !notification.isRead,

                  content: Text(
                    notification.body,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  icon: getNotificationIcon(notification.type),

                  iconColor: notificationColor,

                  iconBg: notificationColor.withOpacity(isDark ? 0.18 : 0.10),

                  cardColor: cardColor,

                  primaryText: primaryText,

                  secondaryText: secondaryText,

                  borderColor: borderColor,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // NOTIFICATION ICON
  // ============================================================

  IconData getNotificationIcon(String type) {
    switch (type) {
      case "booking_approved":
        return Icons.check_circle;

      case "booking_rejected":
        return Icons.cancel;

      case "payment_success":
        return Icons.credit_card;

      default:
        return Icons.notifications;
    }
  }

  // ============================================================
  // NOTIFICATION COLOR
  // ============================================================

  Color getNotificationColor(String type) {
    switch (type) {
      case "booking_approved":
        return Colors.green;

      case "booking_rejected":
        return Colors.red;

      case "payment_success":
        return Colors.purple;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // NOTIFICATION CARD
  // ============================================================

  Widget _notificationCard({
    IconData? icon,
    Color? iconColor,
    Color? iconBg,

    bool isAvatar = false,

    String? avatarUrl,

    required String title,
    required String time,
    required bool isUnread,
    required Widget content,

    required Color cardColor,
    required Color primaryText,
    required Color secondaryText,
    required Color borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: cardColor,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: borderColor.withOpacity(0.35)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ======================================================
          // ICON / AVATAR
          // ======================================================
          if (isAvatar)
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,

                  backgroundImage: NetworkImage(avatarUrl!),
                ),

                Positioned(
                  right: 0,
                  bottom: 0,

                  child: Container(
                    padding: const EdgeInsets.all(3),

                    decoration: const BoxDecoration(
                      color: Color(0xFF6B46C1),
                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.chat_bubble,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              width: 48,
              height: 48,

              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),

              child: Icon(icon, color: iconColor, size: 24),
            ),

          const SizedBox(width: 14),

          // ======================================================
          // CONTENT
          // ======================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==================================================
                // TITLE + TIME
                // ==================================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Expanded(
                      child: Text(
                        title,

                        style: TextStyle(
                          fontWeight: FontWeight.bold,

                          fontSize: 16,

                          color: primaryText,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      time,

                      style: TextStyle(color: secondaryText, fontSize: 12),
                    ),

                    // ============================================
                    // UNREAD DOT
                    // ============================================
                    if (isUnread) ...[
                      const SizedBox(width: 6),

                      Container(
                        width: 8,
                        height: 8,

                        margin: const EdgeInsets.only(top: 5),

                        decoration: const BoxDecoration(
                          color: Color(0xFF6B46C1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 6),

                // =================================================
                // BODY
                // =================================================
                content,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
