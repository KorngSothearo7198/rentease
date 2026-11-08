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

///
/// One renter can have multiple conversations because the renter
/// can contact the owner about different properties.
///
/// Example:
///
/// John Smith
///   ├── Apartment A
///   ├── Apartment B
///   └── Studio C
///
/// The chat list displays John Smith only once.
/// When the owner taps John Smith, the owner can select the property.
///
class _RenterChatGroup {
  final String renterId;
  final String renterName;
  final String renterImage;

  final List<QueryDocumentSnapshot> conversations;

  _RenterChatGroup({
    required this.renterId,
    required this.renterName,
    required this.renterImage,
    required this.conversations,
  });

  /// Latest conversation for preview.
  QueryDocumentSnapshot get latestConversation {
    final sorted = [...conversations];

    sorted.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      final aTime = _getTimestamp(aData["updatedAt"]);
      final bTime = _getTimestamp(bData["updatedAt"]);

      return bTime.compareTo(aTime);
    });

    return sorted.first;
  }

  Map<String, dynamic> get latestData {
    return latestConversation.data() as Map<String, dynamic>;
  }

  /// Total unread messages from all conversations with this renter.
  int get unreadCount {
    int total = 0;

    for (final doc in conversations) {
      final data = doc.data() as Map<String, dynamic>;

      final unreadValue = data["unreadCount"];

      if (unreadValue is int) {
        total += unreadValue;
      } else if (unreadValue is num) {
        total += unreadValue.toInt();
      } else if (unreadValue is String) {
        total += int.tryParse(unreadValue) ?? 0;
      }
    }

    return total;
  }

  /// Number of different properties this renter has conversations with.
  int get propertyCount {
    final propertyIds = <String>{};

    for (final doc in conversations) {
      final data = doc.data() as Map<String, dynamic>;

      final houseId = data["houseId"]?.toString().trim() ?? "";

      if (houseId.isNotEmpty) {
        propertyIds.add(houseId);
      } else {
        final propertyName = data["propertyName"]?.toString().trim() ?? "";

        if (propertyName.isNotEmpty) {
          propertyIds.add(propertyName);
        }
      }
    }

    return propertyIds.length;
  }
}

Timestamp _getTimestamp(dynamic value) {
  if (value is Timestamp) {
    return value;
  }

  return Timestamp.fromDate(DateTime.fromMillisecondsSinceEpoch(0));
}

class _OwnerChatListState extends State<OwnerChatList> {
  final ChatService chatService = ChatService();

  final User owner = FirebaseAuth.instance.currentUser!;

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";

  bool _showSearch = false;

  bool _hideAccount = false;

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _card = Colors.white;
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // HIDE ACCOUNT
  // ============================================================

  void _toggleHideAccount() {
    setState(() {
      _hideAccount = !_hideAccount;
    });

    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _hideAccount
              ? "Private conversations hidden"
              : "Private conversations visible",
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // GROUP CONVERSATIONS BY RENTER
  // ============================================================

  List<_RenterChatGroup> _groupConversations(
    List<QueryDocumentSnapshot> conversations,
  ) {
    final Map<String, List<QueryDocumentSnapshot>> grouped = {};

    for (final doc in conversations) {
      final data = doc.data() as Map<String, dynamic>;

      final renterId = data["renterId"]?.toString().trim() ?? "";

      final renterName = data["renterName"]?.toString().trim() ?? "";

      //
      // Normally renterId is always available.
      //
      // If old data does not contain renterId,
      // use renterName as fallback so the UI still groups.
      //
      final groupKey = renterId.isNotEmpty
          ? renterId
          : renterName.isNotEmpty
          ? renterName.toLowerCase()
          : doc.id;

      grouped.putIfAbsent(groupKey, () => []);
      grouped[groupKey]!.add(doc);
    }

    final result = <_RenterChatGroup>[];

    for (final entry in grouped.entries) {
      final docs = entry.value;

      final latestDoc = _getLatestConversation(docs);
      final latestData = latestDoc.data() as Map<String, dynamic>;

      final renterId = latestData["renterId"]?.toString() ?? entry.key;

      final renterName =
          latestData["renterName"]?.toString().trim().isNotEmpty == true
          ? latestData["renterName"].toString()
          : "Renter";

      final renterImage = latestData["renterImage"]?.toString() ?? "";

      result.add(
        _RenterChatGroup(
          renterId: renterId,
          renterName: renterName,
          renterImage: renterImage,
          conversations: docs,
        ),
      );
    }

    //
    // Sort renters by latest conversation.
    //
    result.sort((a, b) {
      final aTime = _getTimestamp(a.latestData["updatedAt"]);

      final bTime = _getTimestamp(b.latestData["updatedAt"]);

      return bTime.compareTo(aTime);
    });

    return result;
  }

  QueryDocumentSnapshot _getLatestConversation(
    List<QueryDocumentSnapshot> conversations,
  ) {
    QueryDocumentSnapshot latest = conversations.first;

    for (final doc in conversations.skip(1)) {
      final currentData = doc.data() as Map<String, dynamic>;

      final latestData = latest.data() as Map<String, dynamic>;

      final currentTime = _getTimestamp(currentData["updatedAt"]);

      final latestTime = _getTimestamp(latestData["updatedAt"]);

      if (currentTime.compareTo(latestTime) > 0) {
        latest = doc;
      }
    }

    return latest;
  }

  // ============================================================
  // SEARCH
  // ============================================================

  bool _groupMatchesSearch(_RenterChatGroup group) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    //
    // Search renter name.
    //
    if (group.renterName.toLowerCase().contains(_searchQuery)) {
      return true;
    }

    //
    // Search every property / conversation belonging
    // to this renter.
    //
    for (final doc in group.conversations) {
      final data = doc.data() as Map<String, dynamic>;

      final propertyName = data["propertyName"]?.toString().toLowerCase() ?? "";

      final email = data["renterEmail"]?.toString().toLowerCase() ?? "";

      final phone = data["renterPhone"]?.toString().toLowerCase() ?? "";

      final lastMessage = data["lastMessage"]?.toString().toLowerCase() ?? "";

      if (propertyName.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          phone.contains(_searchQuery) ||
          lastMessage.contains(_searchQuery)) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // VIEW RENTER PROFILE
  // ============================================================

  Future<void> _viewProfile(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final renterId = data["renterId"]?.toString();

    if (renterId == null || renterId.isEmpty) {
      _showProfilePreview(context, data, null);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(renterId)
          .get();

      if (!mounted) return;

      final userData = userDoc.exists ? userDoc.data() : null;

      _showProfilePreview(context, data, userData);
    } catch (e) {
      debugPrint("Load renter profile error: $e");

      if (!mounted) return;

      _showProfilePreview(context, data, null);
    }
  }

  // ============================================================
  // PROFILE PREVIEW
  // ============================================================

  void _showProfilePreview(
    BuildContext context,
    Map<String, dynamic> conversationData,
    Map<String, dynamic>? userData,
  ) {
    final renterName =
        userData?["fullName"] ?? conversationData["renterName"] ?? "Renter";

    final renterImage =
        userData?["profileImage"] ?? conversationData["renterImage"] ?? "";

    final email = userData?["email"] ?? conversationData["renterEmail"] ?? "";

    final phone = userData?["phone"] ?? conversationData["renterPhone"] ?? "";

    final gender = userData?["gender"] ?? "";

    final age = userData?["age"]?.toString() ?? "";

    final occupation = userData?["occupation"] ?? "";

    final address = userData?["address"] ?? "";

    final bio = userData?["bio"] ?? "";

    final propertyName = conversationData["propertyName"] ?? "Property";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 24),

                CircleAvatar(
                  radius: 52,
                  backgroundColor: _primary.withOpacity(0.1),
                  backgroundImage: renterImage.toString().isNotEmpty
                      ? NetworkImage(renterImage.toString())
                      : null,
                  child: renterImage.toString().isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          size: 52,
                          color: _primary,
                        )
                      : null,
                ),

                const SizedBox(height: 14),

                Text(
                  renterName.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.home_outlined, size: 16, color: _primary),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        propertyName.toString(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (email.toString().isNotEmpty)
                  _profileInfoRow(
                    Icons.email_outlined,
                    "Email",
                    email.toString(),
                  ),

                if (phone.toString().isNotEmpty)
                  _profileInfoRow(
                    Icons.phone_outlined,
                    "Phone",
                    phone.toString(),
                  ),

                if (gender.toString().isNotEmpty)
                  _profileInfoRow(
                    Icons.person_outline_rounded,
                    "Gender",
                    gender.toString(),
                  ),

                if (age.toString().isNotEmpty)
                  _profileInfoRow(Icons.cake_outlined, "Age", age.toString()),

                if (occupation.toString().isNotEmpty)
                  _profileInfoRow(
                    Icons.work_outline_rounded,
                    "Occupation",
                    occupation.toString(),
                  ),

                if (address.toString().isNotEmpty)
                  _profileInfoRow(
                    Icons.location_on_outlined,
                    "Address",
                    address.toString(),
                  ),

                if (bio.toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "About",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bio.toString(),
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: _textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },
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
                          Navigator.pop(sheetContext);

                          _openSelectedConversation(conversationData);
                        },
                        icon: const Icon(Icons.chat_outlined, size: 18),
                        label: const Text("Message"),
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
          ),
        );
      },
    );
  }

  Widget _profileInfoRow(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primary, size: 20),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: _textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSelectedConversation(Map<String, dynamic> data) {
    final conversationId = data["conversationId"]?.toString() ?? "";

    final renterName = data["renterName"]?.toString() ?? "Renter";

    final propertyName = data["propertyName"]?.toString() ?? "Property";

    if (conversationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Conversation ID is missing.")),
      );

      return;
    }

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
  }

  void _showPropertySelector(_RenterChatGroup group) {
    //
    // Sort properties by latest activity.
    //
    final conversations = [...group.conversations];

    conversations.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;

      final bData = b.data() as Map<String, dynamic>;

      final aTime = _getTimestamp(aData["updatedAt"]);

      final bTime = _getTimestamp(bData["updatedAt"]);

      return bTime.compareTo(aTime);
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: _primary.withOpacity(0.1),
                    backgroundImage: group.renterImage.isNotEmpty
                        ? NetworkImage(group.renterImage)
                        : null,
                    child: group.renterImage.isEmpty
                        ? const Icon(Icons.person_rounded, color: _primary)
                        : null,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.renterName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "${conversations.length} ${conversations.length == 1 ? "property" : "properties"}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                "Select property",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = conversations[index];

                    final data = doc.data() as Map<String, dynamic>;

                    final propertyName =
                        data["propertyName"]?.toString().trim().isNotEmpty ==
                            true
                        ? data["propertyName"].toString()
                        : "Property";

                    final houseId = data["houseId"]?.toString() ?? "";

                    final lastMessage = data["lastMessage"]?.toString() ?? "";

                    final unread = _getUnreadCount(data);

                    final updatedAt = _getTimestamp(data["updatedAt"]);

                    final timeText = _formatTime(updatedAt);

                    return Material(
                      color: _bg,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pop(sheetContext);

                          //
                          // Use the selected conversation.
                          //
                          _openSelectedConversation({
                            ...data,
                            "conversationId": doc.id,
                            "houseId": houseId,
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.home_work_outlined,
                                  color: _primary,
                                  size: 24,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            propertyName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: _textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          timeText,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: unread > 0
                                                ? _primary
                                                : _textSecondary,
                                            fontWeight: unread > 0
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 5),

                                    Text(
                                      _messagePreview(lastMessage),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: unread > 0
                                            ? _textPrimary
                                            : _textSecondary,
                                        fontWeight: unread > 0
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              if (unread > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _primary,
                                    borderRadius: BorderRadius.circular(10),
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

                              const SizedBox(width: 3),

                              const Icon(
                                Icons.chevron_right_rounded,
                                color: _textSecondary,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _getUnreadCount(Map<String, dynamic> data) {
    final value = data["unreadCount"];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  Future<void> _markRenterConversationsAsRead(_RenterChatGroup group) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final doc in group.conversations) {
        batch.update(doc.reference, {"unreadCount": 0});
      }

      await batch.commit();
    } catch (e) {
      debugPrint("Mark renter conversations read error: $e");
    }
  }

  Future<void> _deleteConversation(String conversationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Conversation?"),
        content: const Text(
          "This will permanently delete this property conversation and all messages.",
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

    if (confirm != true) {
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      final messages = await firestore
          .collection("conversations")
          .doc(conversationId)
          .collection("messages")
          .get();

      final batch = firestore.batch();

      for (final message in messages.docs) {
        batch.delete(message.reference);
      }

      batch.delete(firestore.collection("conversations").doc(conversationId));

      await batch.commit();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Conversation deleted"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("Delete conversation error: $e");

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Delete failed: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();

    final now = DateTime.now();

    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    }

    if (diff.inDays == 1) {
      return "Yesterday";
    }

    if (diff.inDays < 7) {
      return DateFormat('EEE').format(date);
    }

    return DateFormat('dd MMM').format(date);
  }

  // ============================================================
  // MESSAGE PREVIEW
  // ============================================================

  String _messagePreview(String lastMessage) {
    if (lastMessage.isEmpty) {
      return "No messages yet";
    }

    if (lastMessage == "📷 Photo" || lastMessage.contains("http")) {
      return "📷 Photo";
    }

    if (lastMessage == "🎤 Voice message") {
      return "🎤 Voice message";
    }

    return lastMessage;
  }

  Widget _buildNoSearchResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 38,
                color: _primary,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              "No renter found",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'No conversations match "$_searchQuery".',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _textSecondary),
            ),
          ],
        ),
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

  Widget _buildChatTile(_RenterChatGroup group, int index) {
    final latestData = group.latestData;

    final latestConversation = group.latestConversation;

    final conversationId = latestConversation.id;

    final propertyName =
        latestData["propertyName"]?.toString().trim().isNotEmpty == true
        ? latestData["propertyName"].toString()
        : "Property";

    final lastMessage = latestData["lastMessage"]?.toString() ?? "";

    final unread = group.unreadCount;

    final timestamp = _getTimestamp(latestData["updatedAt"]);

    final timeText = _formatTime(timestamp);

    final propertyCount = group.propertyCount;

    return Dismissible(
      key: ValueKey("renter_${group.renterId}"),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        //
        // Delete only the latest
        // representative conversation.
        //
        // Other property conversations
        // remain available.
        //
        await _deleteConversation(conversationId);

        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
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
            onTap: () async {
              //
              // If renter has multiple properties,
              // let owner choose which property.
              //
              if (group.conversations.length > 1) {
                await _markRenterConversationsAsRead(group);

                if (!mounted) {
                  return;
                }

                _showPropertySelector(group);

                return;
              }

              await _markRenterConversationsAsRead(group);

              if (!mounted) {
                return;
              }

              _openSelectedConversation({
                ...latestData,
                "conversationId": conversationId,
              });
            },
            onLongPress: () {
              _viewProfile(context, {
                ...latestData,
                "conversationId": conversationId,
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  // ==================================================
                  // AVATAR
                  // ==================================================
                  GestureDetector(
                    onTap: () {
                      _viewProfile(context, {
                        ...latestData,
                        "conversationId": conversationId,
                      });
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: _primary.withOpacity(0.1),
                          backgroundImage: group.renterImage.isNotEmpty
                              ? NetworkImage(group.renterImage)
                              : null,
                          child: group.renterImage.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  color: _primary,
                                  size: 28,
                                )
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

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.renterName,
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

                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                propertyName,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: _primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            if (propertyCount > 1) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "+${propertyCount - 1} more",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: _primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 4),

                        Text(
                          _messagePreview(lastMessage),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _showSearch
              ? TextField(
                  key: const ValueKey("search"),
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Search renter...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: _textSecondary),
                  ),
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                )
              : const Text(
                  "Messages",
                  key: ValueKey("title"),
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
        ),
        actions: [
          IconButton(
            tooltip: _showSearch ? "Close Search" : "Search",
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;

                if (!_showSearch) {
                  _searchController.clear();

                  _searchQuery = "";
                }
              });
            },
            icon: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
              color: _textPrimary,
            ),
          ),

          IconButton(
            tooltip: _hideAccount ? "Show Account" : "Hide Account",
            onPressed: _toggleHideAccount,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
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

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final conversations = snapshot.data!.docs;

          //
          // First filter private conversations.
          //
          final visibleConversations = conversations.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            if (_hideAccount && data["isPrivate"] == true) {
              return false;
            }

            return true;
          }).toList();

          //
          // IMPORTANT:
          //
          // Group conversations by renter.
          //
          // This removes:
          //
          // John Smith / Apartment A
          // John Smith / Apartment B
          //
          // and changes it to:
          //
          // John Smith
          //
          final groups = _groupConversations(visibleConversations);

          //
          // Search after grouping.
          //
          final filteredGroups = groups.where(_groupMatchesSearch).toList();

          if (filteredGroups.isEmpty) {
            return _buildNoSearchResult();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            physics: const BouncingScrollPhysics(),
            itemCount: filteredGroups.length,
            itemBuilder: (context, index) {
              final group = filteredGroups[index];

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
                child: _buildChatTile(group, index),
              );
            },
          );
        },
      ),
    );
  }
}
