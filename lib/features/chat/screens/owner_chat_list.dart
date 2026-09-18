import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../services/chat_service.dart';
import 'Owner_chat_detail.dart';

class OwnerChatList extends StatefulWidget {
  const OwnerChatList({super.key});

  @override
  State<OwnerChatList> createState() => _OwnerChatListState();
}

class _OwnerChatListState extends State<OwnerChatList> {
  final ChatService chatService = ChatService();
  final owner = FirebaseAuth.instance.currentUser!;

  bool _hideAccount = false;

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _card = Colors.white;
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  void _toggleHideAccount() {
    setState(() => _hideAccount = !_hideAccount);
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _hideAccount ? "Account hidden from chat list" : "Account visible",
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _viewProfile(BuildContext context, Map<String, dynamic> data) {
    final renterName = data["renterName"] ?? "Renter";
    final renterImage = data["renterImage"] ?? "";
    final propertyName = data["propertyName"] ?? "Property";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 48,
                backgroundColor: _primary.withOpacity(0.1),
                backgroundImage: renterImage.toString().isNotEmpty
                    ? NetworkImage(renterImage)
                    : null,
                child: renterImage.toString().isEmpty
                    ? const Icon(Icons.person_rounded, size: 48, color: _primary)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                renterName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                propertyName,
                style: const TextStyle(fontSize: 14, color: _textSecondary),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textPrimary,
                        side: const BorderSide(color: _border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("Close"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Navigate to full renter profile if you have one
                      },
                      icon: const Icon(Icons.person_outline_rounded, size: 18),
                      label: const Text("View Profile"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteConversation(String conversationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Conversation?"),
        content: const Text(
          "This will permanently delete the conversation and all messages.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete all messages first (optional but recommended)
        final messages = await FirebaseFirestore.instance
            .collection("conversations")
            .doc(conversationId)
            .collection("messages")
            .get();

        for (var doc in messages.docs) {
          await doc.reference.delete();
        }

        // Delete conversation
        await FirebaseFirestore.instance
            .collection("conversations")
            .doc(conversationId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Conversation deleted"),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        debugPrint("Delete conversation error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          "Messages",
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _hideAccount ? "Show Account" : "Hide Account",
            onPressed: _toggleHideAccount,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                _hideAccount
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                key: ValueKey(_hideAccount),
                color: _hideAccount ? Colors.redAccent : _textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatService.getOwnerConversations(owner.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final conversations = snapshot.data!.docs;

          final filtered = _hideAccount
              ? conversations.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data["isPrivate"] != true;
          }).toList()
              : conversations;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            physics: const BouncingScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final doc = filtered[index];
              final data = doc.data() as Map<String, dynamic>;

              // Auto update renter info if missing
              if ((data["renterName"] == null || data["renterName"] == "Renter") &&
                  data["renterId"] != null) {
                chatService.updateRenterInfo(doc.id);
              }

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 16 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: _buildChatTile(doc.id, data),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 42,
              color: _primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No conversations yet",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "When renters message you,\nthey will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(String conversationId, Map<String, dynamic> data) {
    final propertyName = data["propertyName"] ?? "Property";
    final lastMessage = data["lastMessage"] ?? "";
    final renterName = data["renterName"] ?? "Renter";
    final renterImage = data["renterImage"] ?? "";
    final timestamp = data["updatedAt"];
    final unread = data["unreadCount"] ?? 0;

    String timeText = "";
    if (timestamp != null) {
      final date = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        timeText = DateFormat('HH:mm').format(date);
      } else if (diff.inDays == 1) {
        timeText = "Yesterday";
      } else if (diff.inDays < 7) {
        timeText = DateFormat('EEE').format(date);
      } else {
        timeText = DateFormat('dd MMM').format(date);
      }
    }

    // Better last message preview
    String preview = lastMessage;
    if (lastMessage == "📷 Photo" || lastMessage.contains("http")) {
      preview = "📷 Photo";
    }

    return Dismissible(
      key: Key(conversationId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        await _deleteConversation(conversationId);
        return false; // we handle delete ourselves
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                  builder: (_) => OwnerChatDetail(
                    conversationId: conversationId,
                    hostName: renterName,
                    propertyName: propertyName,
                  ),
                ),
              );
            },
            onLongPress: () => _viewProfile(context, data),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () => _viewProfile(context, data),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: _primary.withOpacity(0.1),
                          backgroundImage: renterImage.toString().isNotEmpty
                              ? NetworkImage(renterImage)
                              : null,
                          child: renterImage.toString().isEmpty
                              ? const Icon(Icons.person_rounded,
                              color: _primary, size: 28)
                              : null,
                        ),
                        if (unread > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unread > 9 ? "9+" : "$unread",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
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
                                renterName,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              timeText,
                              style: TextStyle(
                                fontSize: 12,
                                color: unread > 0 ? _primary : _textSecondary,
                                fontWeight: unread > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          propertyName,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: _primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preview,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: unread > 0 ? _textPrimary : _textSecondary,
                            fontWeight:
                            unread > 0 ? FontWeight.w600 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _textSecondary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}