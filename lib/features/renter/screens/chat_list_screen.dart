import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService chatService = ChatService();

  final user = FirebaseAuth.instance.currentUser;

  // ==============================================================
  // PRIMARY COLOR
  // ==============================================================

  static const Color _primary = Color(0xFF4F46E5);

  // ==============================================================
  // THEME COLORS
  // ==============================================================

  Color get _backgroundColor {
    return Theme.of(context).colorScheme.surface;
  }

  Color get _cardColor {
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  Color get _textPrimary {
    return Theme.of(context).colorScheme.onSurface;
  }

  Color get _textSecondary {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  Color get _borderColor {
    return Theme.of(context).dividerColor;
  }

  // ==============================================================
  // PROFILE BOTTOM SHEET
  // ==============================================================

  void _viewProfile(BuildContext context, Map<String, dynamic> data) {
    final ownerName = data["ownerName"] ?? "Owner";
    final ownerImage = data["ownerImage"] ?? "";
    final propertyName = data["propertyName"] ?? "Property";

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --------------------------------------------------
              // HANDLE
              // --------------------------------------------------
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 24),

              // --------------------------------------------------
              // AVATAR
              // --------------------------------------------------
              CircleAvatar(
                radius: 48,
                backgroundColor: _primary.withOpacity(0.1),
                backgroundImage: ownerImage.toString().isNotEmpty
                    ? NetworkImage(ownerImage)
                    : null,
                child: ownerImage.toString().isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: _primary,
                      )
                    : null,
              ),

              const SizedBox(height: 16),

              // --------------------------------------------------
              // OWNER NAME
              // --------------------------------------------------
              Text(
                ownerName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 6),

              // --------------------------------------------------
              // PROPERTY
              // --------------------------------------------------
              Text(
                propertyName,
                style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
              ),

              const SizedBox(height: 28),

              // --------------------------------------------------
              // BUTTONS
              // --------------------------------------------------
              Row(
                children: [
                  // CLOSE
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.onSurface,
                        side: BorderSide(color: colors.outline),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("Close"),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // VIEW PROFILE
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);

                        // TODO:
                        // Navigate to owner profile
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

  // ==============================================================
  // DELETE CONVERSATION
  // ==============================================================

  Future<void> _deleteConversation(String conversationId) async {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Delete Conversation?",
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            "This will permanently delete the conversation and all messages.",
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      // ----------------------------------------------------------
      // DELETE MESSAGES
      // ----------------------------------------------------------

      final messages = await FirebaseFirestore.instance
          .collection("conversations")
          .doc(conversationId)
          .collection("messages")
          .get();

      for (final doc in messages.docs) {
        await doc.reference.delete();
      }

      // ----------------------------------------------------------
      // DELETE CONVERSATION
      // ----------------------------------------------------------

      await FirebaseFirestore.instance
          .collection("conversations")
          .doc(conversationId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Conversation deleted"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("Delete conversation error: $e");
    }
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (user == null) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: Center(
          child: Text(
            "Please login",
            style: TextStyle(color: colors.onSurface),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,

      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: _textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,

        title: Text(
          "Messages",
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("conversations")
            .where("participants", arrayContains: user!.uid)
            .orderBy("updatedAt", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          // ------------------------------------------------------
          // ERROR
          // ------------------------------------------------------

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: colors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // ------------------------------------------------------
          // LOADING
          // ------------------------------------------------------

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }

          // ------------------------------------------------------
          // EMPTY
          // ------------------------------------------------------

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final chats = snapshot.data!.docs;

          // ------------------------------------------------------
          // CHAT LIST
          // ------------------------------------------------------

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            physics: const BouncingScrollPhysics(),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final doc = chats[index];

              final data = doc.data() as Map<String, dynamic>;

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

  // ==============================================================
  // EMPTY STATE
  // ==============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ------------------------------------------------------
          // ICON
          // ------------------------------------------------------
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

          // ------------------------------------------------------
          // TITLE
          // ------------------------------------------------------
          Text(
            "No messages yet",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          // ------------------------------------------------------
          // DESCRIPTION
          // ------------------------------------------------------
          Text(
            "When you chat with property owners,\n"
            "they will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // CHAT TILE
  // ==============================================================

  Widget _buildChatTile(String conversationId, Map<String, dynamic> data) {
    final propertyName = data["propertyName"] ?? "Property";

    final lastMessage = data["lastMessage"] ?? "";

    final ownerName = data["ownerName"] ?? "Owner";

    final ownerImage = data["ownerImage"] ?? "";

    final timestamp = data["updatedAt"];

    final unread = data["unreadCount"] ?? 0;

    // ============================================================
    // TIME
    // ============================================================

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

    // ============================================================
    // MESSAGE PREVIEW
    // ============================================================

    String preview = lastMessage;

    if (lastMessage == "📷 Photo" || lastMessage.toString().contains("http")) {
      preview = "📷 Photo";
    }

    if (lastMessage == "🎤 Voice message") {
      preview = "🎤 Voice message";
    }

    // ============================================================
    // DISMISSIBLE
    // ============================================================

    return Dismissible(
      key: Key(conversationId),

      direction: DismissDirection.endToStart,

      confirmDismiss: (_) async {
        await _deleteConversation(conversationId);

        return false;
      },

      // ----------------------------------------------------------
      // DELETE BACKGROUND
      // ----------------------------------------------------------
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.red,
          size: 28,
        ),
      ),

      // ----------------------------------------------------------
      // CARD
      // ----------------------------------------------------------
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),

        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(18),

          border: Border.all(color: _borderColor.withOpacity(0.5)),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.03,
              ),
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

            // ----------------------------------------------------
            // OPEN CHAT
            // ----------------------------------------------------
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(
                    conversationId: conversationId,
                    hostName: ownerName,
                    propertyName: propertyName,
                  ),
                ),
              );
            },

            // ----------------------------------------------------
            // LONG PRESS
            // ----------------------------------------------------
            onLongPress: () => _viewProfile(context, data),

            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

              child: Row(
                children: [
                  // =================================================
                  // AVATAR
                  // =================================================
                  GestureDetector(
                    onTap: () => _viewProfile(context, data),

                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,

                          backgroundColor: _primary.withOpacity(0.1),

                          backgroundImage: ownerImage.toString().isNotEmpty
                              ? NetworkImage(ownerImage)
                              : null,

                          child: ownerImage.toString().isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  color: _primary,
                                  size: 28,
                                )
                              : null,
                        ),

                        // ------------------------------------------------
                        // UNREAD BADGE
                        // ------------------------------------------------
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

                  // =================================================
                  // CONTENT
                  // =================================================
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        // ---------------------------------------------
                        // OWNER + TIME
                        // ---------------------------------------------
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ownerName,

                                style: TextStyle(
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

                        // ---------------------------------------------
                        // PROPERTY
                        // ---------------------------------------------
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

                        // ---------------------------------------------
                        // LAST MESSAGE
                        // ---------------------------------------------
                        Text(
                          preview.isEmpty ? "Start chat" : preview,

                          style: TextStyle(
                            fontSize: 13.5,

                            color: unread > 0 ? _textPrimary : _textSecondary,

                            fontWeight: unread > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // =================================================
                  // ARROW
                  // =================================================
                  Icon(
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
