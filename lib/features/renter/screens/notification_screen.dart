import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // RECENT Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  letterSpacing: 1,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Mark all as read',
                  style: TextStyle(
                    color: Color(0xFF6B46C1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Booking Approved
          _notificationCard(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            iconBg: Colors.green.withOpacity(0.1),
            title: 'Booking Approved',
            time: '2m ago',
            isUnread: true,
            content: RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                children: [
                  TextSpan(text: 'Your booking for '),
                  TextSpan(
                    text: 'Skyline View Penthouse',
                    style: TextStyle(
                      color: Color(0xFF6B46C1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' has been approved by Sarah Jenkins.'),
                ],
              ),
            ),
          ),

          // New Message
          _notificationCard(
            isAvatar: true,
            avatarUrl: 'https://source.unsplash.com/random/100x100/?woman',
            title: 'New Message',
            time: '15m ago',
            isUnread: true,
            content: RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                children: [
                  TextSpan(
                    text: 'Sarah Jenkins: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text:
                    '"Hey! I\'ve sent over the check-in instructions for your stay next week..."',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // YESTERDAY Header
          Text(
            'YESTERDAY',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 12),

          // Payment Successful
          _notificationCard(
            icon: Icons.credit_card,
            iconColor: const Color(0xFF6B46C1),
            iconBg: const Color(0xFF6B46C1).withOpacity(0.1),
            title: 'Payment Successful',
            time: '1d ago',
            isUnread: false,
            content: RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                children: [
                  TextSpan(text: 'Payment of '),
                  TextSpan(
                    text: '\$3,293.67',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' for Skyline View Penthouse was successful.'),
                ],
              ),
            ),
          ),

          // Booking Declined
          _notificationCard(
            icon: Icons.cancel,
            iconColor: Colors.red,
            iconBg: Colors.red.withOpacity(0.1),
            title: 'Booking Declined',
            time: '1d ago',
            isUnread: false,
            content: RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                children: [
                  TextSpan(
                    text:
                    'Unfortunately, your booking request for ',
                  ),
                  TextSpan(
                    text: 'Urban Brick Studio',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' was declined.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon or Avatar
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
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),

          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    if (isUnread) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6B46C1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                content,
              ],
            ),
          ),
        ],
      ),
    );
  }
}