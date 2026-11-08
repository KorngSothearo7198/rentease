import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../models/message_model.dart';
import '../../../services/chat_service.dart';
import '../../../services/cloudinary_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String hostName;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.hostName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final ChatService chatService = ChatService();

  final CloudinaryService cloudinaryService = CloudinaryService();

  final ImagePicker _imagePicker = ImagePicker();

  final AudioRecorder _audioRecorder = AudioRecorder();

  final AudioPlayer _audioPlayer = AudioPlayer();

  // ============================================================
  // USER
  // ============================================================

  User? currentUser;

  // ============================================================
  // CONVERSATION
  // ============================================================

  String _activeConversationId = "";

  String _ownerId = "";

  String _renterId = "";

  Map<String, dynamic>? _conversationData;

  bool _loadingConversation = true;

  // ============================================================
  // PROPERTY
  // ============================================================

  Map<String, dynamic>? _propertyData;

  bool _loadingProperty = true;

  // ============================================================
  // ALL OWNER PROPERTY CHATS
  // ============================================================

  List<_PropertyConversation> _propertyConversations = [];

  bool _loadingPropertyChats = false;

  // ============================================================
  // MESSAGE / UPLOAD STATE
  // ============================================================

  bool isUploading = false;

  bool isRecording = false;

  String? _recordingPath;

  DateTime? _recordingStartedAt;

  int _lastMessageCount = 0;

  // ============================================================
  // EDIT MESSAGE STATE
  // ============================================================

  String? _editingMessageId;

  String _editingOriginalText = "";

  // ============================================================
  // AUDIO STATE
  // ============================================================

  String? currentlyPlayingId;

  double _playbackSpeed = 1.0;

  final Map<String, Duration?> _audioDurations = {};

  final Map<String, Duration> _audioPositions = {};

  final Set<String> _loadingAudioDurations = {};

  StreamSubscription<void>? _audioCompleteSubscription;

  StreamSubscription<Duration>? _audioPositionSubscription;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    currentUser = FirebaseAuth.instance.currentUser;

    _activeConversationId = widget.conversationId;

    _loadConversationData();

    _setupAudioListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    messageController.dispose();

    _scrollController.dispose();

    _audioCompleteSubscription?.cancel();

    _audioPositionSubscription?.cancel();

    _audioPlayer.dispose();

    _audioRecorder.dispose();

    super.dispose();
  }

  // ============================================================
  // BACK / DISMISS
  // ============================================================

  void _handleBack() {
    // If keyboard is open, dismiss keyboard first.
    if (FocusScope.of(context).hasFocus) {
      FocusScope.of(context).unfocus();
      return;
    }

    // If edit mode is active, cancel edit first.
    if (_editingMessageId != null) {
      _cancelEditing();
      return;
    }

    Navigator.pop(context);
  }

  // ============================================================
  // AUDIO LISTENERS
  // ============================================================

  void _setupAudioListeners() {
    _audioCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;

      setState(() {
        currentlyPlayingId = null;
        _audioPositions.clear();
      });
    });

    _audioPositionSubscription = _audioPlayer.onPositionChanged.listen((
      position,
    ) {
      if (!mounted || currentlyPlayingId == null) {
        return;
      }

      setState(() {
        _audioPositions[currentlyPlayingId!] = position;
      });
    });
  }

  // ============================================================
  // LOAD CURRENT CONVERSATION
  // ============================================================

  Future<void> _loadConversationData() async {
    try {
      if (!mounted) return;

      setState(() {
        _loadingConversation = true;
        _loadingProperty = true;
      });

      final conversationSnapshot = await FirebaseFirestore.instance
          .collection("conversations")
          .doc(_activeConversationId)
          .get();

      if (!conversationSnapshot.exists) {
        if (!mounted) return;

        setState(() {
          _conversationData = null;
          _propertyData = null;
          _loadingConversation = false;
          _loadingProperty = false;
        });

        return;
      }

      final conversationData =
          conversationSnapshot.data() ?? <String, dynamic>{};

      final ownerId = conversationData["ownerId"]?.toString().trim() ?? "";

      final renterId = conversationData["renterId"]?.toString().trim() ?? "";

      if (!mounted) return;

      setState(() {
        _conversationData = conversationData;

        _ownerId = ownerId;
        _renterId = renterId;

        _loadingConversation = false;
      });

      await _loadProperty(conversationData["houseId"]?.toString() ?? "");

      await _loadOwnerPropertyChats();

      await _markCurrentConversationUnreadAsRead();

      _scrollToBottom();
    } catch (e) {
      debugPrint("Error loading conversation: $e");

      if (!mounted) return;

      setState(() {
        _conversationData = null;
        _propertyData = null;
        _loadingConversation = false;
        _loadingProperty = false;
      });
    }
  }

  // ============================================================
  // LOAD PROPERTY
  // ============================================================

  Future<void> _loadProperty(String houseId) async {
    try {
      if (!mounted) return;

      setState(() {
        _loadingProperty = true;
      });

      if (houseId.trim().isEmpty) {
        if (!mounted) return;

        setState(() {
          _propertyData = null;
          _loadingProperty = false;
        });

        return;
      }

      final propertySnapshot = await FirebaseFirestore.instance
          .collection("properties")
          .doc(houseId)
          .get();

      if (!mounted) return;

      setState(() {
        _propertyData = propertySnapshot.exists
            ? propertySnapshot.data()
            : null;

        _loadingProperty = false;
      });
    } catch (e) {
      debugPrint("Load property error: $e");

      if (!mounted) return;

      setState(() {
        _propertyData = null;
        _loadingProperty = false;
      });
    }
  }

  // ============================================================
  // LOAD ALL PROPERTY CHATS
  // ============================================================

  Future<void> _loadOwnerPropertyChats() async {
    if (_ownerId.isEmpty || _renterId.isEmpty) {
      return;
    }

    try {
      if (!mounted) return;

      setState(() {
        _loadingPropertyChats = true;
      });

      final snapshot = await FirebaseFirestore.instance
          .collection("conversations")
          .where("ownerId", isEqualTo: _ownerId)
          .where("renterId", isEqualTo: _renterId)
          .get();

      final List<_PropertyConversation> result = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final houseId = data["houseId"]?.toString().trim() ?? "";

        if (houseId.isEmpty) {
          continue;
        }

        String propertyName = data["propertyName"]?.toString().trim() ?? "";

        String propertyImage = "";

        try {
          final propertySnapshot = await FirebaseFirestore.instance
              .collection("properties")
              .doc(houseId)
              .get();

          if (propertySnapshot.exists) {
            final propertyData = propertySnapshot.data();

            if (propertyData != null) {
              propertyName = _propertyNameFromData(propertyData);

              propertyImage = _propertyImageFromData(propertyData);
            }
          }
        } catch (e) {
          debugPrint("Property preview error: $e");
        }

        if (propertyName.isEmpty) {
          propertyName = "Property";
        }

        result.add(
          _PropertyConversation(
            conversationId: doc.id,
            houseId: houseId,
            propertyName: propertyName,
            propertyImage: propertyImage,
            lastMessage: data["lastMessage"]?.toString() ?? "",
            updatedAt: _timestampFromValue(data["updatedAt"]),
          ),
        );
      }

      result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (!mounted) return;

      setState(() {
        _propertyConversations = result;
        _loadingPropertyChats = false;
      });
    } catch (e) {
      debugPrint("Load property conversations error: $e");

      if (!mounted) return;

      setState(() {
        _propertyConversations = [];
        _loadingPropertyChats = false;
      });
    }
  }

  // ============================================================
  // PROPERTY NAME
  // ============================================================

  String _propertyNameFromData(Map<String, dynamic> data) {
    final fields = ["propertyName", "name", "title"];

    for (final field in fields) {
      final value = data[field]?.toString().trim();

      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return "Property";
  }

  // ============================================================
  // PROPERTY IMAGE
  // ============================================================

  String _propertyImageFromData(Map<String, dynamic> data) {
    final singleFields = [
      "imageUrl",
      "propertyImage",
      "image",
      "coverImage",
      "thumbnail",
    ];

    for (final field in singleFields) {
      final value = data[field]?.toString().trim();

      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    final multipleFields = ["images", "imageUrls", "photos", "propertyImages"];

    for (final field in multipleFields) {
      final value = data[field];

      if (value is List) {
        for (final item in value) {
          final image = item?.toString().trim();

          if (image != null && image.isNotEmpty) {
            return image;
          }
        }
      }
    }

    return "";
  }

  // ============================================================
  // TIMESTAMP
  // ============================================================

  Timestamp _timestampFromValue(dynamic value) {
    if (value is Timestamp) {
      return value;
    }

    return Timestamp.fromDate(DateTime.fromMillisecondsSinceEpoch(0));
  }

  // ============================================================
  // SWITCH PROPERTY
  // ============================================================

  Future<void> _selectPropertyConversation(
    _PropertyConversation propertyChat,
  ) async {
    if (propertyChat.conversationId == _activeConversationId) {
      Navigator.pop(context);
      return;
    }

    await _audioPlayer.stop();

    _cancelEditing();

    if (!mounted) return;

    setState(() {
      _activeConversationId = propertyChat.conversationId;

      currentlyPlayingId = null;

      _audioPositions.clear();

      _audioDurations.clear();

      _lastMessageCount = 0;

      _loadingConversation = true;

      _loadingProperty = true;
    });

    Navigator.pop(context);

    try {
      final conversationSnapshot = await FirebaseFirestore.instance
          .collection("conversations")
          .doc(propertyChat.conversationId)
          .get();

      if (!conversationSnapshot.exists) {
        return;
      }

      final conversationData =
          conversationSnapshot.data() ?? <String, dynamic>{};

      final houseId = conversationData["houseId"]?.toString() ?? "";

      if (!mounted) return;

      setState(() {
        _conversationData = conversationData;

        _ownerId = conversationData["ownerId"]?.toString() ?? "";

        _renterId = conversationData["renterId"]?.toString() ?? "";

        _loadingConversation = false;
      });

      await _loadProperty(houseId);

      await _markCurrentConversationUnreadAsRead();

      _scrollToBottom();
    } catch (e) {
      debugPrint("Switch property error: $e");

      if (!mounted) return;

      setState(() {
        _loadingConversation = false;
        _loadingProperty = false;
      });
    }
  }

  // ============================================================
  // PROPERTY SELECTOR
  // ============================================================

  void _showPropertySelector() {
    if (_propertyConversations.isEmpty) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 620),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),

                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 18),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE8F7),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.home_work_outlined,
                          color: Color(0xFF6B46C1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Choose Property",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "Select a separate chat for each property",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                const Divider(height: 1),

                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _propertyConversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _propertyConversations[index];

                      final isSelected =
                          item.conversationId == _activeConversationId;

                      return _buildPropertySelectorItem(item, isSelected);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PROPERTY SELECTOR ITEM
  // ============================================================

  Widget _buildPropertySelectorItem(
    _PropertyConversation item,
    bool isSelected,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        _selectPropertyConversation(item);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1ECFA) : const Color(0xFFF9F9FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B46C1) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 62,
                height: 62,
                child: item.propertyImage.isNotEmpty
                    ? Image.network(
                        item.propertyImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return _smallPropertyPlaceholder();
                        },
                      )
                    : _smallPropertyPlaceholder(),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.propertyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF6B46C1)
                          : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    item.lastMessage.isEmpty
                        ? "No messages yet"
                        : item.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    DateFormat("MMM d, h:mm a").format(item.updatedAt.toDate()),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            if (isSelected)
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF6B46C1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PLACEHOLDER
  // ============================================================

  Widget _smallPropertyPlaceholder() {
    return Container(
      color: const Color(0xFFEDE8F7),
      child: const Center(
        child: Icon(Icons.home_outlined, color: Color(0xFF6B46C1), size: 27),
      ),
    );
  }

  // ============================================================
  // PROPERTY IMAGE
  // ============================================================

  String? _getPropertyImage() {
    final data = _propertyData;

    if (data == null) {
      return null;
    }

    final image = _propertyImageFromData(data);

    return image.trim().isNotEmpty ? image : null;
  }

  // ============================================================
  // PROPERTY NAME
  // ============================================================

  String _getPropertyName() {
    final data = _propertyData;

    if (data == null) {
      final value = _conversationData?["propertyName"]?.toString().trim();

      return value != null && value.isNotEmpty ? value : "Property";
    }

    return _propertyNameFromData(data);
  }

  // ============================================================
  // PROPERTY TYPE
  // ============================================================

  String _getPropertyType() {
    final data = _propertyData;

    if (data == null) {
      return "Rental Property";
    }

    final type =
        data["type"]?.toString() ??
        data["category"]?.toString() ??
        data["propertyType"]?.toString() ??
        "";

    return type.trim().isEmpty ? "Rental Property" : type;
  }

  // ============================================================
  // PROPERTY STATUS
  // ============================================================

  String _getPropertyStatus() {
    final data = _propertyData;

    if (data == null) {
      return "";
    }

    return data["status"]?.toString() ?? "";
  }

  // ============================================================
  // PROPERTY VERIFIED
  // ============================================================

  bool _isPropertyVerified() {
    final data = _propertyData;

    if (data == null) {
      return false;
    }

    return data["isVerified"] == true || data["leaseVerified"] == true;
  }

  // ============================================================
  // OWNER IMAGE
  // ============================================================

  String? _getOwnerImage() {
    final data = _conversationData;

    if (data == null) {
      return null;
    }

    final image =
        data["ownerImage"]?.toString() ?? data["hostImage"]?.toString() ?? "";

    return image.trim().isEmpty ? null : image;
  }

  // ============================================================
  // OWNER NAME
  // ============================================================

  String _getOwnerName() {
    final data = _conversationData;

    if (data == null) {
      return widget.hostName;
    }

    final name =
        data["ownerName"]?.toString() ?? data["hostName"]?.toString() ?? "";

    return name.trim().isEmpty ? widget.hostName : name;
  }

  // ============================================================
  // OWNER ONLINE
  // ============================================================

  bool _isOwnerOnline() {
    final data = _conversationData;

    if (data == null) {
      return false;
    }

    return data["isOnline"] == true;
  }

  // ============================================================
  // SEND TEXT / SAVE EDIT
  // ============================================================

  Future<void> _sendTextMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    if (currentUser == null) {
      return;
    }

    // ----------------------------------------------------------
    // EDIT MODE
    // ----------------------------------------------------------

    if (_editingMessageId != null) {
      await _saveEditedMessage(text);
      return;
    }

    messageController.clear();

    FocusScope.of(context).unfocus();

    try {
      final message = MessageModel(
        id: "",
        senderId: currentUser!.uid,
        message: text,
        imageUrl: null,
        audioUrl: null,
        messageType: "text",
        isRead: false,
        createdAt: Timestamp.now(),
        isEdited: false,
        durationSeconds: null,
      );

      await chatService.sendMessage(
        conversationId: _activeConversationId,
        message: message,
      );

      _scrollToBottom();

      await _loadOwnerPropertyChats();
    } catch (e) {
      debugPrint("Send text error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to send message: $e")));
    }
  }

  // ============================================================
  // START EDITING
  // ============================================================

  void _startEditing(MessageModel message) {
    if (currentUser == null) return;

    if (message.senderId != currentUser!.uid) {
      return;
    }

    if (!message.isText) {
      return;
    }

    setState(() {
      _editingMessageId = message.id;
      _editingOriginalText = message.message;

      messageController.text = message.message;

      messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: messageController.text.length),
      );
    });

    FocusScope.of(context).requestFocus(FocusNode());
  }

  // ============================================================
  // SAVE EDIT
  // ============================================================

  Future<void> _saveEditedMessage(String newText) async {
    final messageId = _editingMessageId;

    if (messageId == null) {
      return;
    }

    if (newText.trim().isEmpty) {
      return;
    }

    if (newText.trim() == _editingOriginalText.trim()) {
      _cancelEditing();
      return;
    }

    try {
      await chatService.editMessage(
        conversationId: _activeConversationId,
        messageId: messageId,
        newText: newText.trim(),
      );

      if (!mounted) return;

      messageController.clear();

      setState(() {
        _editingMessageId = null;
        _editingOriginalText = "";
      });

      FocusScope.of(context).unfocus();

      await _loadOwnerPropertyChats();
    } catch (e) {
      debugPrint("Edit message error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to edit message: $e")));
    }
  }

  // ============================================================
  // CANCEL EDITING
  // ============================================================

  void _cancelEditing() {
    messageController.clear();

    if (!mounted) return;

    setState(() {
      _editingMessageId = null;
      _editingOriginalText = "";
    });

    FocusScope.of(context).unfocus();
  }

  // ============================================================
  // SHOW MESSAGE MENU
  // ============================================================

  void _showMessageMenu(MessageModel message) {
    if (currentUser == null) {
      return;
    }

    // Only your own messages can be edited/deleted.
    if (message.senderId != currentUser!.uid) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // EDIT
                // ------------------------------------------------
                if (message.isText)
                  ListTile(
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE8F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFF6B46C1),
                      ),
                    ),
                    title: const Text(
                      "Edit message",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text("Change this message"),
                    onTap: () {
                      Navigator.pop(context);

                      _startEditing(message);
                    },
                  ),

                // ------------------------------------------------
                // DELETE
                // ------------------------------------------------
                ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text(
                    "Delete message",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  subtitle: const Text("Remove this message"),
                  onTap: () {
                    Navigator.pop(context);

                    _confirmDeleteMessage(message);
                  },
                ),

                const SizedBox(height: 6),

                // ------------------------------------------------
                // CANCEL
                // ------------------------------------------------
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.grey),
                  title: const Text("Cancel"),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CONFIRM DELETE
  // ============================================================

  Future<void> _confirmDeleteMessage(MessageModel message) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete message?"),
          content: const Text(
            "This message will be permanently removed from the conversation.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await _deleteMessage(message);
  }

  // ============================================================
  // DELETE MESSAGE
  // ============================================================

  Future<void> _deleteMessage(MessageModel message) async {
    try {
      await chatService.deleteMessage(
        conversationId: _activeConversationId,
        messageId: message.id,
      );

      if (_editingMessageId == message.id) {
        _cancelEditing();
      }

      await _loadOwnerPropertyChats();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Message deleted")));
    } catch (e) {
      debugPrint("Delete message error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete message: $e")));
    }
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) {
        return;
      }

      await _uploadImage(File(image.path));
    } catch (e) {
      debugPrint("Pick image error: $e");
    }
  }

  // ============================================================
  // UPLOAD IMAGE
  // ============================================================

  Future<void> _uploadImage(File file) async {
    if (currentUser == null) {
      return;
    }

    try {
      setState(() {
        isUploading = true;
      });

      final imageUrl = await cloudinaryService.uploadImage(file);

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception("Image upload failed");
      }

      final message = MessageModel(
        id: "",
        senderId: currentUser!.uid,
        message: "",
        imageUrl: imageUrl,
        audioUrl: null,
        messageType: "image",
        isRead: false,
        createdAt: Timestamp.now(),
        isEdited: false,
        durationSeconds: null,
      );

      await chatService.sendImageMessage(
        conversationId: _activeConversationId,
        message: message,
      );

      _scrollToBottom();

      await _loadOwnerPropertyChats();
    } catch (e) {
      debugPrint("Upload image error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to send image: $e")));
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  // ============================================================
  // START RECORDING
  // ============================================================

  Future<void> _startRecording() async {
    try {
      final permission = await Permission.microphone.request();

      if (!permission.isGranted) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone permission is required.")),
        );

        return;
      }

      final hasPermission = await _audioRecorder.hasPermission();

      if (!hasPermission) {
        return;
      }

      final directory = await getTemporaryDirectory();

      final filePath =
          "${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a";

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      if (!mounted) return;

      setState(() {
        isRecording = true;
        _recordingPath = filePath;
        _recordingStartedAt = DateTime.now();
      });
    } catch (e) {
      debugPrint("Start recording error: $e");
    }
  }

  // ============================================================
  // STOP RECORDING
  // ============================================================

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();

      final startedAt = _recordingStartedAt;

      if (!mounted) return;

      setState(() {
        isRecording = false;
        _recordingStartedAt = null;
      });

      if (path == null || path.isEmpty) {
        return;
      }

      _recordingPath = path;

      int? durationSeconds;

      if (startedAt != null) {
        durationSeconds = DateTime.now().difference(startedAt).inSeconds;
      }

      await _uploadVoice(File(path), durationSeconds: durationSeconds);
    } catch (e) {
      debugPrint("Stop recording error: $e");

      if (!mounted) return;

      setState(() {
        isRecording = false;
        _recordingStartedAt = null;
      });
    }
  }

  // ============================================================
  // UPLOAD VOICE
  // ============================================================

  Future<void> _uploadVoice(File file, {int? durationSeconds}) async {
    if (currentUser == null) {
      return;
    }

    try {
      setState(() {
        isUploading = true;
      });

      final audioUrl = await cloudinaryService.uploadAudio(file);

      if (audioUrl == null || audioUrl.isEmpty) {
        throw Exception("Audio upload failed");
      }

      final message = MessageModel(
        id: "",
        senderId: currentUser!.uid,
        message: "",
        imageUrl: null,
        audioUrl: audioUrl,
        messageType: "audio",
        isRead: false,
        createdAt: Timestamp.now(),
        isEdited: false,
        durationSeconds: durationSeconds,
      );

      await chatService.sendVoiceMessage(
        conversationId: _activeConversationId,
        message: message,
      );

      _scrollToBottom();

      await _loadOwnerPropertyChats();
    } catch (e) {
      debugPrint("Upload voice error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send voice message: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }

      try {
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {}
    }
  }

  // ============================================================
  // AUDIO DURATION
  // ============================================================

  Future<void> _loadAudioDuration(
    String url,
    String messageId,
    MessageModel message,
  ) async {
    if (message.durationSeconds != null && message.durationSeconds! > 0) {
      if (!_audioDurations.containsKey(messageId)) {
        if (mounted) {
          setState(() {
            _audioDurations[messageId] = Duration(
              seconds: message.durationSeconds!,
            );
          });
        }
      }

      return;
    }

    if (_audioDurations.containsKey(messageId)) {
      return;
    }

    if (_loadingAudioDurations.contains(messageId)) {
      return;
    }

    _loadingAudioDurations.add(messageId);

    try {
      final player = AudioPlayer();

      await player.setSource(UrlSource(url));

      final duration = await player.getDuration();

      await player.dispose();

      if (!mounted) return;

      setState(() {
        _audioDurations[messageId] = duration;
      });
    } catch (e) {
      debugPrint("Load audio duration error: $e");

      if (!mounted) return;

      setState(() {
        _audioDurations[messageId] = null;
      });
    } finally {
      _loadingAudioDurations.remove(messageId);
    }
  }

  // ============================================================
  // FORMAT DURATION
  // ============================================================

  String _formatDuration(Duration? duration) {
    if (duration == null) {
      return "0:00";
    }

    final minutes = duration.inMinutes.remainder(60);

    final seconds = duration.inSeconds.remainder(60);

    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  // ============================================================
  // PLAY VOICE
  // ============================================================

  Future<void> _playVoice(String url, String messageId) async {
    try {
      if (currentlyPlayingId == messageId) {
        await _audioPlayer.pause();

        if (!mounted) return;

        setState(() {
          currentlyPlayingId = null;
        });

        return;
      }

      await _audioPlayer.stop();

      _audioPositions.clear();

      await _audioPlayer.setPlaybackRate(_playbackSpeed);

      await _audioPlayer.play(UrlSource(url));

      if (!mounted) return;

      setState(() {
        currentlyPlayingId = messageId;
      });
    } catch (e) {
      debugPrint("Play voice error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to play voice message.")),
      );
    }
  }

  // ============================================================
  // CHANGE PLAYBACK SPEED
  // ============================================================

  Future<void> _changePlaybackSpeed() async {
    double newSpeed;

    if (_playbackSpeed == 1.0) {
      newSpeed = 1.5;
    } else if (_playbackSpeed == 1.5) {
      newSpeed = 2.0;
    } else {
      newSpeed = 1.0;
    }

    _playbackSpeed = newSpeed;

    await _audioPlayer.setPlaybackRate(_playbackSpeed);

    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ============================================================
  // MARK CURRENT CONVERSATION AS READ
  // ============================================================

  Future<void> _markCurrentConversationUnreadAsRead() async {
    if (currentUser == null) {
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("conversations")
          .doc(_activeConversationId)
          .collection("messages")
          .where("senderId", isNotEqualTo: currentUser!.uid)
          .where("isRead", isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({"isRead": true});
      }

      await FirebaseFirestore.instance
          .collection("conversations")
          .doc(_activeConversationId)
          .set({"unreadCount": 0}, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Mark conversation read error: $e");
    }
  }

  // ============================================================
  // MARK MESSAGES AS READ
  // ============================================================

  Future<void> _markMessagesAsRead(List<MessageModel> messages) async {
    if (currentUser == null) {
      return;
    }

    for (final message in messages) {
      if (message.senderId != currentUser!.uid && !message.isRead) {
        try {
          await chatService.markMessageAsRead(
            _activeConversationId,
            message.id,
          );
        } catch (e) {
          debugPrint("Mark message read error: $e");
        }
      }
    }
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatMessageTime(Timestamp timestamp) {
    return DateFormat("h:mm a").format(timestamp.toDate());
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FD),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildPropertyCard(),

          Expanded(child: _buildMessages()),

          _buildInputArea(),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    final ownerImage = _getOwnerImage();

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,

      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.black87,
          size: 20,
        ),
        onPressed: _handleBack,
      ),

      titleSpacing: 0,

      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: const Color(0xFFE8E0F8),
                backgroundImage: ownerImage != null
                    ? NetworkImage(ownerImage)
                    : null,
                child: ownerImage == null
                    ? const Icon(Icons.person, color: Color(0xFF6B46C1))
                    : null,
              ),

              if (_isOwnerOnline())
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getOwnerName(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _isOwnerOnline() ? "Online" : "Host",
                  style: TextStyle(
                    color: _isOwnerOnline()
                        ? Colors.green
                        : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      actions: [
        IconButton(
          onPressed: _showPropertySelector,
          tooltip: "Properties",
          icon: const Icon(Icons.home_work_outlined, color: Color(0xFF6B46C1)),
        ),
      ],
    );
  }

  // ============================================================
  // PROPERTY CARD
  // ============================================================

  Widget _buildPropertyCard() {
    if (_loadingProperty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Loading property...",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    final propertyImage = _getPropertyImage();

    final propertyName = _getPropertyName();

    final propertyType = _getPropertyType();

    final propertyStatus = _getPropertyStatus();

    final verified = _isPropertyVerified();

    return GestureDetector(
      onTap: _showPropertySelector,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7E0F3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: SizedBox(
                width: 76,
                height: 76,
                child: propertyImage != null
                    ? Image.network(
                        propertyImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return _propertyPlaceholder();
                        },
                      )
                    : _propertyPlaceholder(),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE8F7),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Text(
                          "CURRENT CHAT",
                          style: TextStyle(
                            color: Color(0xFF6B46C1),
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          propertyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      if (verified)
                        const Icon(
                          Icons.verified,
                          size: 17,
                          color: Color(0xFF6B46C1),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    propertyType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  if (propertyStatus.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(
                              propertyStatus,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            propertyStatus,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _statusColor(propertyStatus),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF1EDF9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.swap_vert,
                color: Color(0xFF6B46C1),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROPERTY PLACEHOLDER
  // ============================================================

  Widget _propertyPlaceholder({bool loading = false}) {
    return Container(
      color: const Color(0xFFEDE8F7),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.home_outlined,
                color: Color(0xFF6B46C1),
                size: 30,
              ),
      ),
    );
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    final value = status.toLowerCase();

    if (value.contains("available")) {
      return Colors.green;
    }

    if (value.contains("rent")) {
      return Colors.orange;
    }

    if (value.contains("pending")) {
      return Colors.orange;
    }

    if (value.contains("approved")) {
      return Colors.green;
    }

    if (value.contains("reject")) {
      return Colors.red;
    }

    if (value.contains("cancel")) {
      return Colors.red;
    }

    return const Color(0xFF6B46C1);
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  Widget _buildMessages() {
    if (_loadingConversation) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeConversationId.trim().isEmpty) {
      return const Center(child: Text("Conversation not found."));
    }

    return StreamBuilder<List<MessageModel>>(
      stream: chatService.getMessages(_activeConversationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Unable to load messages.\n\n${snapshot.error}",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          );
        }

        final messages = snapshot.data ?? [];

        if (messages.length != _lastMessageCount) {
          _lastMessageCount = messages.length;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }

        _markMessagesAsRead(messages);

        if (messages.isEmpty) {
          return _buildEmptyMessages();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];

            final isMe = message.senderId == currentUser?.uid;

            return _buildMessageBubble(message, isMe);
          },
        );
      },
    );
  }

  // ============================================================
  // EMPTY MESSAGES
  // ============================================================

  Widget _buildEmptyMessages() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE8F7),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF6B46C1),
                size: 32,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Start a conversation",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 6),

            Text(
              "Send a message to ${_getOwnerName()} about ${_getPropertyName()}",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return GestureDetector(
      onLongPress: isMe
          ? () {
              _showMessageMenu(message);
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 15,
                backgroundColor: const Color(0xFFE8E0F8),
                backgroundImage: _getOwnerImage() != null
                    ? NetworkImage(_getOwnerImage()!)
                    : null,
                child: _getOwnerImage() == null
                    ? const Icon(
                        Icons.person,
                        size: 17,
                        color: Color(0xFF6B46C1),
                      )
                    : null,
              ),

              const SizedBox(width: 7),
            ],

            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(message, isMe),

                  const SizedBox(height: 3),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatMessageTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade500,
                          ),
                        ),

                        if (message.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            "edited",
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE CONTENT
  // ============================================================

  Widget _buildMessageContent(MessageModel message, bool isMe) {
    if (message.isImage &&
        message.imageUrl != null &&
        message.imageUrl!.isNotEmpty) {
      return _buildImageMessage(message, isMe);
    }

    if (message.isAudio || message.messageType == "voice") {
      if (message.audioUrl != null && message.audioUrl!.isNotEmpty) {
        _loadAudioDuration(message.audioUrl!, message.id, message);

        return _buildVoiceMessage(message, isMe);
      }
    }

    return _buildTextMessage(message, isMe);
  }

  // ============================================================
  // TEXT MESSAGE
  // ============================================================

  Widget _buildTextMessage(MessageModel message, bool isMe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF6B46C1) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(17),
          topRight: const Radius.circular(17),
          bottomLeft: Radius.circular(isMe ? 17 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 17),
        ),
        boxShadow: !isMe
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        message.message,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 14,
          height: 1.35,
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE MESSAGE
  // ============================================================

  Widget _buildImageMessage(MessageModel message, bool isMe) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: GestureDetector(
        onTap: () {
          _showFullImage(message.imageUrl!);
        },
        child: Image.network(
          message.imageUrl!,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }

            return Container(
              width: 220,
              height: 220,
              color: const Color(0xFFEDE8F7),
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 220,
              height: 150,
              color: const Color(0xFFEDE8F7),
              child: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFF6B46C1),
                  size: 35,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // FULL IMAGE
  // ============================================================

  void _showFullImage(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),

              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // VOICE MESSAGE
  // ============================================================

  Widget _buildVoiceMessage(MessageModel message, bool isMe) {
    final isPlaying = currentlyPlayingId == message.id;

    final duration = _audioDurations[message.id];

    final position = _audioPositions[message.id] ?? Duration.zero;

    final maxSeconds = duration?.inMilliseconds.toDouble() ?? 1.0;

    final positionSeconds = position.inMilliseconds.toDouble().clamp(
      0.0,
      maxSeconds,
    );

    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF6B46C1) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: !isMe
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _playVoice(message.audioUrl!, message.id);
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withOpacity(0.18)
                    : const Color(0xFFEDE8F7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: isMe ? Colors.white : const Color(0xFF6B46C1),
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildVoiceWaveform(
                        isMe: isMe,
                        isPlaying: isPlaying,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      duration == null
                          ? "..."
                          : _formatDuration(isPlaying ? position : duration),
                      style: TextStyle(
                        fontSize: 11,
                        color: isMe ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                if (isPlaying && duration != null)
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 4,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 8,
                      ),
                    ),
                    child: Slider(
                      min: 0,
                      max: maxSeconds,
                      value: positionSeconds,
                      activeColor: isMe
                          ? Colors.white
                          : const Color(0xFF6B46C1),
                      inactiveColor: isMe
                          ? Colors.white.withOpacity(0.25)
                          : Colors.grey.shade300,
                      onChanged: (value) async {
                        await _audioPlayer.seek(
                          Duration(milliseconds: value.round()),
                        );
                      },
                    ),
                  ),

                if (!isPlaying)
                  Text(
                    "Voice message",
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withOpacity(0.8)
                          : Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          GestureDetector(
            onTap: _changePlaybackSpeed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withOpacity(0.15)
                    : const Color(0xFFF1EDF9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${_playbackSpeed}x",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isMe ? Colors.white : const Color(0xFF6B46C1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VOICE WAVEFORM
  // ============================================================

  Widget _buildVoiceWaveform({required bool isMe, required bool isPlaying}) {
    final heights = [
      8.0,
      15.0,
      10.0,
      20.0,
      13.0,
      24.0,
      17.0,
      12.0,
      22.0,
      15.0,
      25.0,
      10.0,
      18.0,
      13.0,
      21.0,
      9.0,
      16.0,
      12.0,
    ];

    return SizedBox(
      height: 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: heights.map((height) {
          return Expanded(
            child: Container(
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withOpacity(isPlaying ? 0.95 : 0.65)
                    : const Color(
                        0xFF6B46C1,
                      ).withOpacity(isPlaying ? 0.9 : 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // INPUT AREA
  // ============================================================

  Widget _buildInputArea() {
    final isEditing = _editingMessageId != null;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ----------------------------------------------------
            // EDITING BAR
            // ----------------------------------------------------
            if (isEditing)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EDF9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Color(0xFF6B46C1),
                    ),

                    const SizedBox(width: 8),

                    const Expanded(
                      child: Text(
                        "Editing message",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B46C1),
                        ),
                      ),
                    ),

                    IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: _cancelEditing,
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // ------------------------------------------------
                // IMAGE
                // ------------------------------------------------
                if (!isEditing)
                  IconButton(
                    onPressed: isUploading ? null : _pickImage,
                    icon: const Icon(
                      Icons.image_outlined,
                      color: Color(0xFF6B46C1),
                    ),
                  ),

                // ------------------------------------------------
                // TEXT
                // ------------------------------------------------
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 110),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: isEditing
                            ? "Edit message..."
                            : "Write a message...",
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // ------------------------------------------------
                // SEND / VOICE
                // ------------------------------------------------
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: messageController,
                  builder: (context, value, child) {
                    final hasText = value.text.trim().isNotEmpty;

                    if (hasText) {
                      return IconButton(
                        onPressed: isUploading ? null : _sendTextMessage,
                        icon: Icon(
                          isEditing ? Icons.check : Icons.send,
                          color: const Color(0xFF6B46C1),
                        ),
                      );
                    }

                    if (isEditing) {
                      return IconButton(
                        onPressed: _cancelEditing,
                        icon: const Icon(Icons.close, color: Colors.grey),
                      );
                    }

                    return GestureDetector(
                      onLongPress: _startRecording,
                      onLongPressUp: _stopRecording,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isRecording
                              ? Colors.red
                              : const Color(0xFF6B46C1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isRecording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// PROPERTY CONVERSATION MODEL
// ================================================================

class _PropertyConversation {
  final String conversationId;

  final String houseId;

  final String propertyName;

  final String propertyImage;

  final String lastMessage;

  final Timestamp updatedAt;

  const _PropertyConversation({
    required this.conversationId,
    required this.houseId,
    required this.propertyName,
    required this.propertyImage,
    required this.lastMessage,
    required this.updatedAt,
  });
}
