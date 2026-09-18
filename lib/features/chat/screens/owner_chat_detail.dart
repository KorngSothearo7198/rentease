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

class OwnerChatDetail extends StatefulWidget {
  final String conversationId;
  final String hostName;
  final String propertyName;

  const OwnerChatDetail({
    super.key,
    required this.conversationId,
    required this.hostName,
    required this.propertyName,
  });

  @override
  State<OwnerChatDetail> createState() => _OwnerChatDetailState();
}

class _OwnerChatDetailState extends State<OwnerChatDetail> {
  // ============================================================
  // SERVICES
  // ============================================================

  final ChatService chatService = ChatService();

  final CloudinaryService cloudinaryService = CloudinaryService();

  final TextEditingController messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final ImagePicker _picker = ImagePicker();

  // ============================================================
  // AUDIO
  // ============================================================

  final AudioRecorder _recorder = AudioRecorder();

  final AudioPlayer _audioPlayer = AudioPlayer();

  Timer? _amplitudeTimer;

  StreamSubscription<void>? _audioCompleteSubscription;

  // ============================================================
  // USER
  // ============================================================

  User? currentUser;

  String renterName = "Renter";

  String ownerName = "You";

  String? renterImage;

  // ============================================================
  // STATE
  // ============================================================

  bool isUploading = false;

  bool isRecording = false;

  String? _recordingPath;

  String? currentlyPlayingId;

  int _lastMessageCount = 0;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _primary = Color(0xFF4F46E5);

  static const Color _bg = Color(0xFFF8FAFC);

  static const Color _myBubble = Color(0xFF4F46E5);

  static const Color _otherBubble = Color(0xFFFFFFFF);

  static const Color _textPrimary = Color(0xFF0F172A);

  static const Color _textSecondary = Color(0xFF64748B);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    currentUser = FirebaseAuth.instance.currentUser;

    _loadUserNames();

    _audioCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      debugPrint('[OWNER CHAT] AUDIO - playback completed');

      if (!mounted) return;

      setState(() {
        currentlyPlayingId = null;
      });
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    messageController.dispose();

    _scrollController.dispose();

    _amplitudeTimer?.cancel();

    _audioCompleteSubscription?.cancel();

    _recorder.dispose();

    _audioPlayer.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD USER NAMES
  // ============================================================

  Future<void> _loadUserNames() async {
    try {
      final convDoc = await FirebaseFirestore.instance
          .collection("conversations")
          .doc(widget.conversationId)
          .get();

      if (!convDoc.exists) {
        return;
      }

      final data = convDoc.data()!;

      final renterId = data["renterId"] ?? "";

      final ownerId = data["ownerId"] ?? "";

      // --------------------------------------------------------
      // LOAD RENTER
      // --------------------------------------------------------

      if (renterId.isNotEmpty) {
        final renterDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(renterId)
            .get();

        if (renterDoc.exists) {
          final rData = renterDoc.data()!;

          if (!mounted) return;

          setState(() {
            renterName = rData["fullName"] ?? rData["name"] ?? "Renter";

            renterImage = rData["profileImage"];
          });
        }
      }

      // --------------------------------------------------------
      // LOAD OWNER
      // --------------------------------------------------------

      if (ownerId.isNotEmpty) {
        final ownerDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(ownerId)
            .get();

        if (ownerDoc.exists) {
          final oData = ownerDoc.data()!;

          if (!mounted) return;

          setState(() {
            ownerName = oData["fullName"] ?? oData["name"] ?? "You";
          });
        }
      }
    } catch (e) {
      debugPrint("Load names error: $e");
    }
  }

  // ============================================================
  // SEND TEXT MESSAGE
  // ============================================================

  Future<void> sendMessage() async {
    if (currentUser == null) {
      return;
    }

    if (isUploading || isRecording) {
      return;
    }

    final text = messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    messageController.clear();

    try {
      final message = MessageModel(
        id: "",
        senderId: currentUser!.uid,
        message: text,
        messageType: "text",
        isRead: false,
        createdAt: Timestamp.now(),
      );

      await chatService.sendMessage(
        conversationId: widget.conversationId,
        message: message,
      );

      _scrollToBottom();
    } catch (e) {
      debugPrint("Send message error: $e");

      if (mounted) {
        _showSnack("Failed to send message");
      }
    }
  }

  // ============================================================
  // PICK + SEND IMAGE
  // ============================================================

  Future<void> _pickAndSendImage() async {
    if (currentUser == null || isUploading || isRecording) {
      return;
    }

    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (file == null) {
        return;
      }

      if (mounted) {
        setState(() {
          isUploading = true;
        });
      }

      final imageFile = File(file.path);

      final url = await cloudinaryService.uploadImage(imageFile);

      if (url == null || url.isEmpty) {
        if (mounted) {
          _showSnack("Failed to upload image");
        }

        return;
      }

      final message = MessageModel(
        id: "",
        senderId: currentUser!.uid,
        message: url,
        messageType: "image",
        isRead: false,
        createdAt: Timestamp.now(),
      );

      await chatService.sendImageMessage(
        conversationId: widget.conversationId,
        message: message,
      );

      _scrollToBottom();
    } catch (e) {
      debugPrint("Image send error: $e");

      if (mounted) {
        _showSnack("Failed to send image");
      }
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
    debugPrint('[OWNER CHAT] VOICE 01 - START');

    if (isUploading) {
      debugPrint('[OWNER CHAT] VOICE 02 - uploading');
      return;
    }

    if (isRecording) {
      debugPrint('[OWNER CHAT] VOICE 03 - already recording');
      return;
    }

    try {
      // --------------------------------------------------------
      // REQUEST MICROPHONE PERMISSION
      // --------------------------------------------------------

      debugPrint('[OWNER CHAT] VOICE 04 - requesting permission');

      final status = await Permission.microphone.request();

      debugPrint('[OWNER CHAT] VOICE 05 - permission=$status');

      debugPrint(
        '[OWNER CHAT] VOICE 06 - '
        'granted=${status.isGranted}',
      );

      debugPrint(
        '[OWNER CHAT] VOICE 07 - '
        'denied=${status.isDenied}',
      );

      debugPrint(
        '[OWNER CHAT] VOICE 08 - '
        'permanentlyDenied='
        '${status.isPermanentlyDenied}',
      );

      debugPrint(
        '[OWNER CHAT] VOICE 09 - '
        'restricted=${status.isRestricted}',
      );

      if (status.isPermanentlyDenied || status.isRestricted) {
        if (mounted) {
          _showMicrophonePermissionDialog();
        }

        return;
      }

      if (!status.isGranted) {
        if (mounted) {
          _showSnack("Microphone permission is required");
        }

        return;
      }

      // --------------------------------------------------------
      // RECORD PACKAGE PERMISSION
      // --------------------------------------------------------

      final hasPermission = await _recorder.hasPermission();

      debugPrint(
        '[OWNER CHAT] VOICE 10 - '
        'recorder permission=$hasPermission',
      );

      if (!hasPermission) {
        if (mounted) {
          _showSnack("Microphone permission is required");
        }

        return;
      }

      // --------------------------------------------------------
      // CREATE WAV FILE
      // --------------------------------------------------------

      final directory = await getTemporaryDirectory();

      final path =
          "${directory.path}/owner_voice_"
          "${DateTime.now().millisecondsSinceEpoch}.wav";

      debugPrint('[OWNER CHAT] VOICE 11 - path=$path');

      // --------------------------------------------------------
      // START RECORDING
      // --------------------------------------------------------

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );

      debugPrint('[OWNER CHAT] VOICE 12 - recorder started');

      if (!mounted) {
        return;
      }

      setState(() {
        isRecording = true;
        _recordingPath = path;
      });

      // --------------------------------------------------------
      // START AMPLITUDE MONITOR
      // --------------------------------------------------------

      _startAmplitudeMonitor();

      debugPrint(
        '[OWNER CHAT] VOICE 13 - '
        'isRecording=true',
      );
    } catch (e, stackTrace) {
      debugPrint('[OWNER CHAT] VOICE ERROR=$e');

      debugPrint('[OWNER CHAT] VOICE STACK=$stackTrace');

      if (mounted) {
        _showSnack("Could not start recording");
      }
    }
  }

  // ============================================================
  // AMPLITUDE MONITOR
  // ============================================================

  void _startAmplitudeMonitor() {
    _amplitudeTimer?.cancel();

    debugPrint('[OWNER CHAT] VOICE AMP - monitor started');

    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 500), (
      _,
    ) async {
      if (!isRecording) {
        return;
      }

      try {
        final amplitude = await _recorder.getAmplitude();

        debugPrint(
          '[OWNER CHAT] VOICE AMPLITUDE - '
          'current=${amplitude.current} '
          'max=${amplitude.max}',
        );
      } catch (e) {
        debugPrint('[OWNER CHAT] VOICE AMPLITUDE ERROR=$e');
      }
    });
  }

  // ============================================================
  // STOP AMPLITUDE MONITOR
  // ============================================================

  void _stopAmplitudeMonitor() {
    _amplitudeTimer?.cancel();

    _amplitudeTimer = null;

    debugPrint('[OWNER CHAT] VOICE AMP - monitor stopped');
  }

  // ============================================================
  // STOP + SEND RECORDING
  // ============================================================

  Future<void> _stopAndSendRecording() async {
    if (!isRecording) {
      return;
    }

    try {
      // Stop amplitude monitor first.
      _stopAmplitudeMonitor();

      debugPrint(
        '[OWNER CHAT] VOICE STOP 01 - '
        'stopping recorder',
      );

      final path = await _recorder.stop();

      debugPrint(
        '[OWNER CHAT] VOICE STOP 02 - '
        'path=$path',
      );

      if (mounted) {
        setState(() {
          isRecording = false;
          _recordingPath = null;
        });
      }

      if (path == null || path.isEmpty) {
        debugPrint(
          '[OWNER CHAT] VOICE STOP 03 - '
          'empty path',
        );
        return;
      }

      if (currentUser == null) {
        await _deleteLocalFile(path);
        return;
      }

      if (mounted) {
        setState(() {
          isUploading = true;
        });
      }

      // --------------------------------------------------------
      // CHECK FILE
      // --------------------------------------------------------

      final file = File(path);

      if (!await file.exists()) {
        throw Exception("Recording file does not exist");
      }

      final fileSize = await file.length();

      debugPrint(
        '[OWNER CHAT] VOICE FILE - '
        'size=$fileSize bytes',
      );

      final bytes = await file.readAsBytes();

      debugPrint(
        '[OWNER CHAT] VOICE FILE - '
        'bytes=${bytes.length}',
      );

      // --------------------------------------------------------
      // UPLOAD CLOUDINARY
      // --------------------------------------------------------

      debugPrint('[OWNER CHAT] VOICE UPLOAD - START');

      final url = await cloudinaryService.uploadAudio(file);

      if (url == null || url.isEmpty) {
        if (mounted) {
          _showSnack("Failed to upload voice");
        }

        await _deleteLocalFile(path);

        return;
      }

      debugPrint(
        '[OWNER CHAT] VOICE UPLOAD - '
        'url=$url',
      );

      // --------------------------------------------------------
      // CREATE VOICE MESSAGE
      // --------------------------------------------------------

      final message = MessageModel(
        id: "",
        senderId: currentUser!.uid,
        message: url,
        messageType: "voice",
        isRead: false,
        createdAt: Timestamp.now(),
      );

      await chatService.sendMessage(
        conversationId: widget.conversationId,
        message: message,
      );

      debugPrint(
        '[OWNER CHAT] VOICE SEND - '
        'message sent',
      );

      _scrollToBottom();

      await _deleteLocalFile(path);
    } catch (e, stackTrace) {
      debugPrint('[OWNER CHAT] VOICE SEND ERROR=$e');

      debugPrint('[OWNER CHAT] VOICE STACK=$stackTrace');

      if (mounted) {
        _showSnack("Failed to send voice message");
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  // ============================================================
  // CANCEL RECORDING
  // ============================================================

  Future<void> _cancelRecording() async {
    if (!isRecording) {
      return;
    }

    try {
      _stopAmplitudeMonitor();

      final savedPath = _recordingPath;

      debugPrint(
        '[OWNER CHAT] RECORD CANCEL - '
        'savedPath=$savedPath',
      );

      final stoppedPath = await _recorder.stop();

      debugPrint(
        '[OWNER CHAT] RECORD CANCEL - '
        'stoppedPath=$stoppedPath',
      );

      if (mounted) {
        setState(() {
          isRecording = false;
          _recordingPath = null;
        });
      }

      final localPath = stoppedPath ?? savedPath;

      if (localPath != null && localPath.isNotEmpty) {
        await _deleteLocalFile(localPath);
      }

      debugPrint('[OWNER CHAT] RECORD CANCEL - completed');
    } catch (e, stackTrace) {
      debugPrint('[OWNER CHAT] RECORD CANCEL ERROR=$e');

      debugPrint('[OWNER CHAT] RECORD CANCEL STACK=$stackTrace');

      if (mounted) {
        setState(() {
          isRecording = false;
          _recordingPath = null;
        });
      }
    }
  }

  // ============================================================
  // DELETE LOCAL AUDIO
  // ============================================================

  Future<void> _deleteLocalFile(String path) async {
    try {
      final file = File(path);

      if (await file.exists()) {
        await file.delete();

        debugPrint('[OWNER CHAT] Local audio deleted');
      }
    } catch (e) {
      debugPrint('[OWNER CHAT] Delete local audio error=$e');
    }
  }

  // ============================================================
  // PLAY VOICE
  // ============================================================

  Future<void> _playVoice(String url, String messageId) async {
    try {
      debugPrint(
        '[OWNER CHAT] AUDIO - '
        'messageId=$messageId',
      );

      debugPrint('[OWNER CHAT] AUDIO - url=$url');

      // Stop current audio if tapping same message.
      if (currentlyPlayingId == messageId) {
        await _audioPlayer.stop();

        if (!mounted) return;

        setState(() {
          currentlyPlayingId = null;
        });

        return;
      }

      await _audioPlayer.stop();

      if (!mounted) return;

      setState(() {
        currentlyPlayingId = messageId;
      });

      await _audioPlayer.play(UrlSource(url));
    } catch (e, stackTrace) {
      debugPrint('[OWNER CHAT] AUDIO ERROR=$e');

      debugPrint('[OWNER CHAT] AUDIO STACK=$stackTrace');

      if (!mounted) return;

      setState(() {
        currentlyPlayingId = null;
      });

      _showSnack("Unable to play voice message");
    }
  }

  // ============================================================
  // DELETE MESSAGE
  // ============================================================

  Future<void> _deleteMessage(MessageModel msg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Delete Message?"),
          content: const Text("This message will be permanently deleted."),
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
      if (currentlyPlayingId == msg.id) {
        await _audioPlayer.stop();

        if (mounted) {
          setState(() {
            currentlyPlayingId = null;
          });
        }
      }

      await chatService.deleteMessage(
        conversationId: widget.conversationId,
        messageId: msg.id,
      );
    } catch (e) {
      debugPrint("Delete message error: $e");

      if (mounted) {
        _showSnack("Failed to delete message");
      }
    }
  }

  // ============================================================
  // EDIT MESSAGE
  // ============================================================

  void _editMessage(MessageModel msg) {
    final controller = TextEditingController(text: msg.message);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Edit Message"),
          content: TextField(
            controller: controller,
            maxLines: 4,
            autofocus: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: _bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newText = controller.text.trim();

                if (newText.isEmpty) {
                  return;
                }

                try {
                  await chatService.editMessage(
                    conversationId: widget.conversationId,
                    messageId: msg.id,
                    newText: newText,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  debugPrint("Edit message error: $e");

                  if (mounted) {
                    _showSnack("Failed to edit message");
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE OPTIONS
  // ============================================================

  void _showMessageOptions(MessageModel msg) {
    final isMe = msg.senderId == currentUser?.uid;

    if (!isMe) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),

              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 8),

              // Edit only text.
              if (msg.messageType == "text")
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: _primary),
                  title: const Text("Edit Message"),
                  onTap: () {
                    Navigator.pop(context);

                    _editMessage(msg);
                  },
                ),

              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                title: const Text(
                  "Delete Message",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);

                  _deleteMessage(msg);
                },
              ),

              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text("Cancel"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================

  void _previewImage(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: const Text("Image"),
            ),
            body: Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) {
                      return child;
                    }

                    return const CircularProgressIndicator(color: Colors.white);
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 50,
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SCROLL TO BOTTOM
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

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
  // MICROPHONE PERMISSION DIALOG
  // ============================================================

  void _showMicrophonePermissionDialog() {
    if (!mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Microphone Permission"),
          content: const Text(
            "Microphone access is disabled. "
            "Please enable microphone permission "
            "in Settings to send voice messages.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
              child: const Text("Open Settings"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _primary.withOpacity(0.1),
              backgroundImage: renterImage != null && renterImage!.isNotEmpty
                  ? NetworkImage(renterImage!)
                  : null,
              child: renterImage == null || renterImage!.isEmpty
                  ? const Icon(Icons.person, color: _primary, size: 22)
                  : null,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    renterName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.propertyName,
                    style: const TextStyle(fontSize: 12, color: _textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: Column(
        children: [
          // ----------------------------------------------------
          // MESSAGES
          // ----------------------------------------------------
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: chatService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Failed to load messages",
                      style: const TextStyle(color: _textSecondary),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                // ------------------------------------------------
                // Scroll when a new message arrives.
                // ------------------------------------------------

                if (messages.length > _lastMessageCount) {
                  _lastMessageCount = messages.length;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) {
                      return;
                    }

                    if (!_scrollController.hasClients) {
                      return;
                    }

                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  });
                }

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      "No messages yet",
                      style: TextStyle(color: _textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];

                    final isMe = msg.senderId == currentUser?.uid;

                    // ------------------------------------------------
                    // DATE SEPARATOR
                    // ------------------------------------------------

                    bool showDate = false;

                    if (index == 0) {
                      showDate = true;
                    } else {
                      final previous = messages[index - 1].createdAt.toDate();

                      final current = msg.createdAt.toDate();

                      showDate =
                          previous.day != current.day ||
                          previous.month != current.month ||
                          previous.year != current.year;
                    }

                    return Column(
                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              DateFormat(
                                'EEE, dd MMM yyyy',
                              ).format(msg.createdAt.toDate()),
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        _buildMessageBubble(msg, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ----------------------------------------------------
          // UPLOADING
          // ----------------------------------------------------
          if (isUploading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: _primary,
              backgroundColor: Colors.transparent,
            ),

          // ----------------------------------------------------
          // RECORDING UI
          // ----------------------------------------------------
          if (isRecording) _buildRecordingArea(),

          // ----------------------------------------------------
          // INPUT
          // ----------------------------------------------------
          if (!isRecording) _buildInputArea(),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT AREA
  // ============================================================

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ------------------------------------------------------
          // GALLERY
          // ------------------------------------------------------
          IconButton(
            onPressed: isUploading ? null : _pickAndSendImage,
            icon: const Icon(Icons.photo_library_rounded),
            color: _primary,
          ),

          // ------------------------------------------------------
          // MICROPHONE
          // ------------------------------------------------------
          GestureDetector(
            onLongPressStart: (_) {
              _startRecording();
            },
            onLongPressEnd: (_) {
              _stopAndSendRecording();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.mic_none_rounded,
                color: isUploading ? Colors.grey : _primary,
              ),
            ),
          ),

          // ------------------------------------------------------
          // TEXT FIELD
          // ------------------------------------------------------
          Expanded(
            child: TextField(
              controller: messageController,
              textCapitalization: TextCapitalization.sentences,
              enabled: !isUploading,
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: const TextStyle(color: _textSecondary),
                filled: true,
                fillColor: _bg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) {
                sendMessage();
              },
            ),
          ),

          const SizedBox(width: 8),

          // ------------------------------------------------------
          // SEND
          // ------------------------------------------------------
          GestureDetector(
            onTap: isUploading ? null : sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isUploading ? Colors.grey : _primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECORDING AREA
  // ============================================================

  Widget _buildRecordingArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      color: Colors.white,
      child: Row(
        children: [
          // ------------------------------------------------------
          // CANCEL
          // ------------------------------------------------------
          IconButton(
            onPressed: _cancelRecording,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),

          // ------------------------------------------------------
          // RECORDING STATUS
          // ------------------------------------------------------
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Row(
                children: [
                  Icon(Icons.mic_rounded, color: Colors.red),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Recording voice...",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    "Release to send",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ------------------------------------------------------
          // SEND
          // ------------------------------------------------------
          GestureDetector(
            onTap: _stopAndSendRecording,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: _primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    final time = DateFormat('HH:mm').format(msg.createdAt.toDate());

    final isImage = msg.messageType == "image";

    final isVoice = msg.messageType == "voice";

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          _showMessageOptions(msg);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // MESSAGE CONTENT
              // --------------------------------------------------
              Container(
                padding: isImage
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? _myBubble : _otherBubble,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildMessageContent(msg, isMe, isImage, isVoice),
              ),

              const SizedBox(height: 3),

              // --------------------------------------------------
              // TIME
              // --------------------------------------------------
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: const TextStyle(fontSize: 11, color: _textSecondary),
                  ),

                  if (msg.isEdited)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                        "edited",
                        style: TextStyle(
                          fontSize: 10,
                          color: _textSecondary,
                          fontStyle: FontStyle.italic,
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
  }

  // ============================================================
  // MESSAGE CONTENT
  // ============================================================

  Widget _buildMessageContent(
    MessageModel msg,
    bool isMe,
    bool isImage,
    bool isVoice,
  ) {

    if (isImage) {
      return GestureDetector(
        onTap: () {
          _previewImage(msg.message);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            msg.message,
            width: 220,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) {
                return child;
              }

              return const SizedBox(
                width: 220,
                height: 160,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primary,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(
                width: 220,
                height: 120,
                child: Icon(Icons.broken_image_outlined, color: Colors.grey),
              );
            },
          ),
        ),
      );
    }

    if (isVoice) {
      final isPlaying = currentlyPlayingId == msg.id;

      return GestureDetector(
        onTap: () {
          _playVoice(msg.message, msg.id);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: isMe ? Colors.white : _primary,
              size: 36,
            ),

            const SizedBox(width: 10),

            Text(
              isPlaying ? "Playing..." : "Voice message",
              style: TextStyle(
                color: isMe ? Colors.white : _textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      msg.message,
      style: TextStyle(
        color: isMe ? Colors.white : _textPrimary,
        fontSize: 15,
        height: 1.35,
      ),
    );
  }
}
