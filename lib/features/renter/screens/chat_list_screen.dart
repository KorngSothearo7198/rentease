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
  final User? user = FirebaseAuth.instance.currentUser;

  // ==============================================================
  // COLORS
  // ==============================================================

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _bg = Color(0xFFF8F9FC);
  static const Color _card = Colors.white;
  static const Color _textPrimary = Color(0xFF1E1B4B);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _pillBg = Color(0xFFEEF2FF);
  static const Color _online = Color(0xFF22C55E);

  // ==============================================================
  // STATE
  // ==============================================================

  String _selectedFilter = "All";

  final TextEditingController _searchController = TextEditingController();

  String _searchText = "";

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==============================================================
  // UNREAD COUNT
  // ==============================================================

  int _getUnreadCount(Map<String, dynamic> data) {
    final value = data["unreadCount"];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  // ==============================================================
  // ARCHIVED
  // ==============================================================

  bool _isArchived(Map<String, dynamic> data) {
    return data["archived"] == true;
  }

  // ==============================================================
  // UPDATED TIME
  // ==============================================================

  DateTime _getUpdatedTime(Map<String, dynamic> data) {
    final timestamp = data["updatedAt"];

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // ==============================================================
  // SEARCH
  // ==============================================================

  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchText.isEmpty) {
      return true;
    }

    final ownerName = data["ownerName"]?.toString().toLowerCase() ?? "";

    final propertyName = data["propertyName"]?.toString().toLowerCase() ?? "";

    final lastMessage = data["lastMessage"]?.toString().toLowerCase() ?? "";

    return ownerName.contains(_searchText) ||
        propertyName.contains(_searchText) ||
        lastMessage.contains(_searchText);
  }

  // ==============================================================
  // GROUP CONVERSATIONS BY OWNER
  // ==============================================================
  //
  // Firestore can contain:
  //
  // John + Apartment A
  // John + Apartment B
  // John + Apartment C
  //
  // But the chat list should show:
  //
  // John
  // Latest property
  //
  // This method groups all conversations belonging to
  // the same owner.
  //
  // =============================================================

  Map<String, List<QueryDocumentSnapshot>> _groupConversationsByOwner(
    List<QueryDocumentSnapshot> conversations,
  ) {
    final Map<String, List<QueryDocumentSnapshot>> grouped = {};

    for (final doc in conversations) {
      final data = doc.data() as Map<String, dynamic>;

      final ownerId = data["ownerId"]?.toString().trim() ?? "";

      // ----------------------------------------------------------
      // Owner ID must exist.
      // ----------------------------------------------------------

      if (ownerId.isEmpty) {
        continue;
      }

      grouped.putIfAbsent(ownerId, () => []);

      grouped[ownerId]!.add(doc);
    }

    // ------------------------------------------------------------
    // Sort each owner's conversations by latest update.
    // ------------------------------------------------------------

    for (final entry in grouped.entries) {
      entry.value.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;

        final bData = b.data() as Map<String, dynamic>;

        return _getUpdatedTime(bData).compareTo(_getUpdatedTime(aData));
      });
    }

    return grouped;
  }

  // ==============================================================
  // GET REPRESENTATIVE CONVERSATION
  // ==============================================================
  //
  // One owner = one row.
  //
  // We choose the latest suitable conversation.
  //
  // All:
  //   latest active conversation
  //
  // Unread:
  //   latest active conversation with unread message
  //
  // Archived:
  //   latest archived conversation
  //
  // =============================================================

  QueryDocumentSnapshot? _getRepresentativeConversation(
    List<QueryDocumentSnapshot> conversations,
  ) {
    if (conversations.isEmpty) {
      return null;
    }

    // ============================================================
    // ALL
    // ============================================================

    if (_selectedFilter == "All") {
      for (final doc in conversations) {
        final data = doc.data() as Map<String, dynamic>;

        if (!_isArchived(data)) {
          return doc;
        }
      }

      return null;
    }

    // ============================================================
    // UNREAD
    // ============================================================

    if (_selectedFilter == "Unread") {
      for (final doc in conversations) {
        final data = doc.data() as Map<String, dynamic>;

        if (_isArchived(data)) {
          continue;
        }

        if (_getUnreadCount(data) > 0) {
          return doc;
        }
      }

      return null;
    }

    // ============================================================
    // ARCHIVED
    // ============================================================

    if (_selectedFilter == "Archived") {
      for (final doc in conversations) {
        final data = doc.data() as Map<String, dynamic>;

        if (_isArchived(data)) {
          return doc;
        }
      }

      return null;
    }

    return null;
  }

  // ==============================================================
  // GET GROUPED DATA
  // ==============================================================
  //
  // This returns one row for each owner.
  //
  // Example:
  //
  // Owner A
  //   Apartment A
  //   Apartment B
  //
  // becomes:
  //
  // Owner A
  //   Apartment B
  //
  // =============================================================

  List<Map<String, dynamic>> _buildOwnerGroups(
    List<QueryDocumentSnapshot> conversations,
  ) {
    final grouped = _groupConversationsByOwner(conversations);

    final result = <Map<String, dynamic>>[];

    for (final entry in grouped.entries) {
      final ownerId = entry.key;

      final ownerConversations = entry.value;

      final representative = _getRepresentativeConversation(ownerConversations);

      if (representative == null) {
        continue;
      }

      final representativeData = representative.data() as Map<String, dynamic>;

      // ----------------------------------------------------------
      // Search all conversations belonging to this owner.
      //
      // This allows:
      //
      // Search "Apartment A"
      //
      // to still find John even if the latest property is
      // Apartment B.
      // ----------------------------------------------------------

      if (_searchText.isNotEmpty) {
        bool found = false;

        for (final doc in ownerConversations) {
          final data = doc.data() as Map<String, dynamic>;

          if (_matchesSearch(data)) {
            found = true;
            break;
          }
        }

        if (!found) {
          continue;
        }
      }

      // ----------------------------------------------------------
      // Count all properties/conversations for this owner.
      // ----------------------------------------------------------

      final propertyCount = ownerConversations.length;

      // ----------------------------------------------------------
      // Total unread messages for this owner.
      //
      // Example:
      //
      // Apartment A = 2 unread
      // Apartment B = 3 unread
      //
      // UI:
      //
      // 5
      //
      // ----------------------------------------------------------

      int totalUnread = 0;

      for (final doc in ownerConversations) {
        final data = doc.data() as Map<String, dynamic>;

        if (_isArchived(data)) {
          continue;
        }

        totalUnread += _getUnreadCount(data);
      }

      // ----------------------------------------------------------
      // Copy representative data.
      // ----------------------------------------------------------

      final row = <String, dynamic>{
        ...representativeData,

        "conversationId": representative.id,

        "ownerId": ownerId,

        "propertyCount": propertyCount,

        "totalUnread": totalUnread,
      };

      result.add(row);
    }

    // ============================================================
    // SORT OWNERS BY LATEST CONVERSATION
    // ============================================================

    result.sort((a, b) {
      final aTime = _getUpdatedTime(a);

      final bTime = _getUpdatedTime(b);

      return bTime.compareTo(aTime);
    });

    return result;
  }

  // ==============================================================
  // ALL COUNT
  // ==============================================================
  //
  // Count unique owners, not conversations.
  //
  // John + Apartment A
  // John + Apartment B
  //
  // = 1
  //
  // =============================================================

  int _getAllCount(List<QueryDocumentSnapshot> conversations) {
    final ownerIds = <String>{};

    for (final doc in conversations) {
      final data = doc.data() as Map<String, dynamic>;

      if (_isArchived(data)) {
        continue;
      }

      final ownerId = data["ownerId"]?.toString().trim() ?? "";

      if (ownerId.isNotEmpty) {
        ownerIds.add(ownerId);
      }
    }

    return ownerIds.length;
  }

  // ==============================================================
  // UNREAD OWNER COUNT
  // ==============================================================

  int _getUnreadConversationsCount(List<QueryDocumentSnapshot> conversations) {
    final ownerIds = <String>{};

    for (final doc in conversations) {
      final data = doc.data() as Map<String, dynamic>;

      if (_isArchived(data)) {
        continue;
      }

      if (_getUnreadCount(data) <= 0) {
        continue;
      }

      final ownerId = data["ownerId"]?.toString().trim() ?? "";

      if (ownerId.isNotEmpty) {
        ownerIds.add(ownerId);
      }
    }

    return ownerIds.length;
  }

  // ==============================================================
  // ARCHIVED OWNER COUNT
  // ==============================================================

  int _getArchivedCount(List<QueryDocumentSnapshot> conversations) {
    final ownerIds = <String>{};

    for (final doc in conversations) {
      final data = doc.data() as Map<String, dynamic>;

      if (!_isArchived(data)) {
        continue;
      }

      final ownerId = data["ownerId"]?.toString().trim() ?? "";

      if (ownerId.isNotEmpty) {
        ownerIds.add(ownerId);
      }
    }

    return ownerIds.length;
  }

  // ==============================================================
  // ARCHIVE / UNARCHIVE
  // ==============================================================

  Future<void> _setArchived(String conversationId, bool archived) async {
    try {
      await FirebaseFirestore.instance
          .collection("conversations")
          .doc(conversationId)
          .update({"archived": archived});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            archived ? "Conversation archived" : "Conversation restored",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("Archive conversation error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to update conversation: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==============================================================
  // MARK AS READ
  // ==============================================================

  Future<void> _markConversationAsRead(String conversationId) async {
    try {
      await FirebaseFirestore.instance
          .collection("conversations")
          .doc(conversationId)
          .update({"unreadCount": 0});
    } catch (e) {
      debugPrint("Mark conversation as read error: $e");
    }
  }

  // ==============================================================
  // MARK ALL OWNER CONVERSATIONS AS READ
  // ==============================================================

  Future<void> _markOwnerAsRead(
    String ownerId,
    List<QueryDocumentSnapshot> conversations,
  ) async {
    try {
      for (final doc in conversations) {
        final data = doc.data() as Map<String, dynamic>;

        final currentOwnerId = data["ownerId"]?.toString() ?? "";

        if (currentOwnerId != ownerId) {
          continue;
        }

        if (_isArchived(data)) {
          continue;
        }

        if (_getUnreadCount(data) <= 0) {
          continue;
        }

        await doc.reference.update({"unreadCount": 0});
      }
    } catch (e) {
      debugPrint("Mark owner conversations read error: $e");
    }
  }

  // ==============================================================
  // DELETE CONVERSATION
  // ==============================================================

  Future<void> _deleteConversation(String conversationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Delete Conversation?",
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            "This will permanently delete the conversation and all messages.",
            style: TextStyle(color: _textSecondary),
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
      final messages = await FirebaseFirestore.instance
          .collection("conversations")
          .doc(conversationId)
          .collection("messages")
          .get();

      for (final doc in messages.docs) {
        await doc.reference.delete();
      }

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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to delete conversation: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: Text("Please login")),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ======================================================
            // APP BAR
            // ======================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Messages",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined, color: _textPrimary),
                  ),

                  const SizedBox(width: 4),

                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _primary,
                    backgroundImage: user!.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user!.photoURL == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                ],
              ),
            ),

            // ======================================================
            // SEARCH BAR
            // ======================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: "Search owner, property, or message...",
                    hintStyle: const TextStyle(
                      color: _textSecondary,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search, color: _textSecondary),
                    suffixIcon: _searchText.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: _textSecondary,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // ======================================================
            // LIVE LIST
            // ======================================================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: chatService.getRenterConversations(user!.uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          snapshot.error.toString(),
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _primary),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // =================================================
                  // COUNTS
                  // =================================================

                  final allCount = _getAllCount(docs);

                  final unreadCount = _getUnreadConversationsCount(docs);

                  final archivedCount = _getArchivedCount(docs);

                  // =================================================
                  // GROUP BY OWNER
                  // =================================================

                  final ownerGroups = _buildOwnerGroups(docs);

                  return Column(
                    children: [
                      // ---------------------------------------------
                      // HEADER
                      // ---------------------------------------------
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            const Text(
                              "Direct with property owners",
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                              ),
                            ),

                            const SizedBox(width: 8),

                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _pillBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "$unreadCount unread",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _primary,
                                  ),
                                ),
                              ),

                            const Spacer(),

                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: _online,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  "Live sync",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ---------------------------------------------
                      // FILTERS
                      // ---------------------------------------------
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip("All", allCount),
                              const SizedBox(width: 8),
                              _buildFilterChip("Unread", unreadCount),
                              const SizedBox(width: 8),
                              _buildFilterChip("Archived", archivedCount),
                            ],
                          ),
                        ),
                      ),

                      // ---------------------------------------------
                      // LIST
                      // ---------------------------------------------
                      Expanded(
                        child: ownerGroups.isEmpty
                            ? _buildFilteredEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  24,
                                ),
                                physics: const BouncingScrollPhysics(),
                                itemCount: ownerGroups.length,
                                itemBuilder: (context, index) {
                                  final data = ownerGroups[index];

                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: Duration(
                                      milliseconds: 280 + (index * 40),
                                    ),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return Transform.translate(
                                        offset: Offset(0, 12 * (1 - value)),
                                        child: Opacity(
                                          opacity: value,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _buildChatTile(data, docs),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // FILTER CHIP
  // ==============================================================

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primary : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : _textSecondary,
              ),
            ),

            const SizedBox(width: 6),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.18) : _pillBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$count",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : _primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // EMPTY STATE
  // ==============================================================

  Widget _buildFilteredEmptyState() {
    String title;
    String message;
    IconData icon;

    if (_searchText.isNotEmpty) {
      title = "No results found";
      message = 'No conversations match "$_searchText".';
      icon = Icons.search_off_rounded;
    } else if (_selectedFilter == "Unread") {
      title = "No unread messages";
      message = "All your conversations are up to date.";
      icon = Icons.mark_email_read_outlined;
    } else if (_selectedFilter == "Archived") {
      title = "No archived conversations";
      message = "Archived conversations will appear here.";
      icon = Icons.archive_outlined;
    } else {
      title = "No messages yet";
      message = "When you chat with property owners,\nthey will appear here.";
      icon = Icons.chat_bubble_outline_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
              child: Icon(icon, size: 42, color: _primary),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // CHAT TILE
  // ==============================================================
  //
  // IMPORTANT:
  //
  // This is now ONE tile per OWNER.
  //
  // The property displayed is taken from the latest
  // conversation belonging to that owner.
  //
  // =============================================================

  Widget _buildChatTile(
    Map<String, dynamic> data,
    List<QueryDocumentSnapshot> allDocs,
  ) {
    final conversationId = data["conversationId"]?.toString() ?? "";

    final ownerId = data["ownerId"]?.toString() ?? "";

    final ownerName = data["ownerName"]?.toString().trim().isNotEmpty == true
        ? data["ownerName"].toString()
        : "Owner";

    final ownerImage = data["ownerImage"]?.toString() ?? "";

    final propertyName =
        data["propertyName"]?.toString().trim().isNotEmpty == true
        ? data["propertyName"].toString()
        : "Property";

    final lastMessage = data["lastMessage"]?.toString() ?? "";

    final isVerified = data["isVerified"] == true;

    final isOnline = data["isOnline"] == true;

    final archived = data["archived"] == true;

    final propertyCount = data["propertyCount"] is num
        ? (data["propertyCount"] as num).toInt()
        : 1;

    final unread = data["totalUnread"] is num
        ? (data["totalUnread"] as num).toInt()
        : 0;

    // ============================================================
    // TIME
    // ============================================================

    final date = _getUpdatedTime(data);

    String timeText = "";

    if (date.millisecondsSinceEpoch > 0) {
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        timeText = DateFormat('h:mm a').format(date);
      } else if (diff.inDays == 1) {
        timeText = "Yesterday";
      } else if (diff.inDays < 7) {
        timeText = DateFormat('EEE').format(date);
      } else {
        timeText = DateFormat('MMM d').format(date);
      }
    }

    // ============================================================
    // MESSAGE PREVIEW
    // ============================================================

    String preview = lastMessage;

    if (lastMessage == "📷 Photo" || lastMessage.contains("http")) {
      preview = "📷 Photo";
    } else if (lastMessage == "🎤 Voice message") {
      preview = "🎤 Voice message";
    }

    // ============================================================
    // DELETE ONLY REPRESENTATIVE CHAT
    // ============================================================

    return Dismissible(
      key: Key("owner-$ownerId"),
      direction: DismissDirection.endToStart,

      confirmDismiss: (_) async {
        await _deleteConversation(conversationId);

        return false;
      },

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

      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),

            // ====================================================
            // OPEN CHAT
            // ====================================================
            onTap: () async {
              // --------------------------------------------------
              // Mark all conversations for this owner as read.
              // --------------------------------------------------

              if (unread > 0) {
                await _markOwnerAsRead(ownerId, allDocs);
              }

              if (!mounted) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(
                    conversationId: conversationId,
                    hostName: ownerName,
                  ),
                ),
              );
            },

            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // OWNER AVATAR
                  // =================================================
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: _primary.withOpacity(0.1),
                        backgroundImage: ownerImage.isNotEmpty
                            ? NetworkImage(ownerImage)
                            : null,
                        child: ownerImage.isEmpty
                            ? const Icon(
                                Icons.person_rounded,
                                color: _primary,
                                size: 28,
                              )
                            : null,
                      ),

                      if (isOnline)
                        Positioned(
                          left: 2,
                          bottom: 2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _online,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: 14),

                  // =================================================
                  // CONTENT
                  // =================================================
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // -------------------------------------------
                        // OWNER NAME
                        // -------------------------------------------
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      ownerName,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: unread > 0
                                            ? FontWeight.w800
                                            : FontWeight.w700,
                                        color: _textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  if (isVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: _primary,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

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

                            // ---------------------------------------
                            // MENU
                            // ---------------------------------------
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                size: 18,
                                color: _textSecondary,
                              ),
                              padding: EdgeInsets.zero,
                              onSelected: (value) async {
                                if (value == "archive") {
                                  await _setArchived(conversationId, true);
                                }

                                if (value == "unarchive") {
                                  await _setArchived(conversationId, false);
                                }

                                if (value == "read") {
                                  await _markOwnerAsRead(ownerId, allDocs);
                                }

                                if (value == "delete") {
                                  await _deleteConversation(conversationId);
                                }
                              },
                              itemBuilder: (context) {
                                return [
                                  if (archived)
                                    const PopupMenuItem(
                                      value: "unarchive",
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.unarchive_outlined,
                                            size: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Text("Unarchive"),
                                        ],
                                      ),
                                    )
                                  else
                                    const PopupMenuItem(
                                      value: "archive",
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.archive_outlined,
                                            size: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Text("Archive"),
                                        ],
                                      ),
                                    ),

                                  if (unread > 0)
                                    const PopupMenuItem(
                                      value: "read",
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.mark_email_read_outlined,
                                            size: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Text("Mark as read"),
                                        ],
                                      ),
                                    ),

                                  const PopupMenuItem(
                                    value: "delete",
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          "Delete conversation",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ];
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        // =================================================
                        // PROPERTY
                        // =================================================
                        //
                        // IMPORTANT:
                        //
                        // This property is NOT static.
                        //
                        // It comes from the latest conversation
                        // for this owner.
                        //
                        // If the latest conversation changes from
                        // Apartment A -> Apartment B,
                        // this automatically becomes Apartment B.
                        //
                        // =================================================
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _pillBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.apartment_rounded,
                                    size: 13,
                                    color: _primary,
                                  ),

                                  const SizedBox(width: 4),

                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 180,
                                    ),
                                    child: Text(
                                      propertyName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: _primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ------------------------------------------------
                            // PROPERTY COUNT
                            // ------------------------------------------------
                            if (propertyCount > 1) ...[
                              const SizedBox(width: 6),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "$propertyCount properties",
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: _textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 6),

                        // =================================================
                        // MESSAGE
                        // =================================================
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                preview.isEmpty ? "Start chat" : preview,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: unread > 0
                                      ? _textPrimary
                                      : _textSecondary,
                                  fontWeight: unread > 0
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            const SizedBox(width: 8),

                            // ---------------------------------------------
                            // UNREAD
                            // ---------------------------------------------
                            if (unread > 0)
                              Container(
                                constraints: const BoxConstraints(
                                  minWidth: 22,
                                  minHeight: 22,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: const BoxDecoration(
                                  color: _primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    unread > 9 ? "9+" : "$unread",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const Icon(
                                Icons.done_all,
                                size: 16,
                                color: Color(0xFF22C55E),
                              ),
                          ],
                        ),

                        // ---------------------------------------------
                        // ARCHIVED
                        // ---------------------------------------------
                        if (archived) ...[
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Icon(
                                Icons.archive_outlined,
                                size: 13,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Archived",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
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
