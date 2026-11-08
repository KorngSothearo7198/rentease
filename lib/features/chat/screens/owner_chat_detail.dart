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

  // Listen for unread renter messages.
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _incomingMessagesReadSubscription;

// Avoid processing the same message repeatedly.
  final Set<String> _messagesBeingMarkedRead = {};

  // ============================================================
  // AUDIO RECORDING
  // ============================================================

  final AudioRecorder _recorder = AudioRecorder();

  // ============================================================
  // AUDIO PLAYBACK
  // ============================================================

  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription<PlayerState>? _audioStateSubscription;

  StreamSubscription<void>? _audioCompleteSubscription;

  Timer? _amplitudeTimer;

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

  bool _isStoppingRecording = false;

  String? _recordingPath;

  String? currentlyPlayingId;

  int _lastMessageCount = 0;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _primary = Color(0xFF4F46E5);

  static const Color _bg = Color(0xFFF8FAFC);

  static const Color _myBubble = Color(0xFF4F46E5);

  static const Color _otherBubble = Colors.white;

  static const Color _textPrimary = Color(0xFF0F172A);

  static const Color _textSecondary = Color(0xFF64748B);

  static const Color _border = Color(0xFFE2E8F0);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    currentUser = FirebaseAuth.instance.currentUser;

    _setupAudioPlayer();

    _loadUserNames();
    _listenAndMarkIncomingMessagesRead();
  }

  // ============================================================
  // AUDIO PLAYER SETUP
  // ============================================================

  Future<void> _setupAudioPlayer() async {
    try {
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            audioMode: AndroidAudioMode.normal,
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );

      await _audioPlayer.setReleaseMode(ReleaseMode.stop);

      debugPrint('[OWNER CHAT] AUDIO PLAYER - initialized');
    } catch (e, stackTrace) {
      debugPrint('[OWNER CHAT] AUDIO PLAYER SETUP ERROR=$e');

      debugPrint('[OWNER CHAT] AUDIO PLAYER SETUP STACK=$stackTrace');
    }

    // ----------------------------------------------------------
    // PLAYER STATE
    // ----------------------------------------------------------

    _audioStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) {
        return;
      }

      if (state == PlayerState.completed || state == PlayerState.stopped) {
        setState(() {
          currentlyPlayingId = null;
        });
      }
    });

    // ----------------------------------------------------------
    // PLAYER COMPLETE
    // ----------------------------------------------------------

    _audioCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        currentlyPlayingId = null;
      });
    });
  }

  @override
  void dispose() {
    // Stop listening to incoming messages.
    _incomingMessagesReadSubscription?.cancel();

    messageController.dispose();
    _scrollController.dispose();

    _amplitudeTimer?.cancel();

    _audioCompleteSubscription?.cancel();
    _audioStateSubscription?.cancel();

    _recorder.dispose();
    _audioPlayer.dispose();

    super.dispose();
  }

  Future<void> _loadUserNames() async {
    try {
      final convDoc = await FirebaseFirestore.instance
          .collection("conversations")
          .doc(widget.conversationId)
          .get();

      if (!convDoc.exists) {
        return;
      }

      final data = convDoc.data();

      if (data == null) {
        return;
      }

      final renterId = data["renterId"]?.toString() ?? "";

      final ownerId = data["ownerId"]?.toString() ?? "";

      // --------------------------------------------------------
      // RENTER
      // --------------------------------------------------------

      if (renterId.isNotEmpty) {
        final renterDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(renterId)
            .get();

        if (renterDoc.exists && renterDoc.data() != null) {
          final rData = renterDoc.data()!;

          if (!mounted) {
            return;
          }

          setState(() {
            renterName = rData["fullName"] ?? rData["name"] ?? "Renter";

            renterImage = rData["profileImage"];
          });
        }
      }

      // --------------------------------------------------------
      // OWNER
      // --------------------------------------------------------

      if (ownerId.isNotEmpty) {
        final ownerDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(ownerId)
            .get();

        if (ownerDoc.exists && ownerDoc.data() != null) {
          final oData = ownerDoc.data()!;

          if (!mounted) {
            return;
          }

          setState(() {
            ownerName = oData["fullName"] ?? oData["name"] ?? "You";
          });
        }
      }
    } catch (e) {
      debugPrint("[OWNER CHAT] Load names error=$e");
    }
  }

  // ============================================================
// AUTO MARK INCOMING MESSAGES AS READ
// ============================================================

  Future<void> _listenAndMarkIncomingMessagesRead() async {
    try {
      final user = currentUser;

      if (user == null) return;

      // Verify that the current user is the owner of this conversation.
      final conversationDoc = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .get();

      if (!mounted || !conversationDoc.exists) return;

      final conversationData = conversationDoc.data();

      if (conversationData == null) return;

      final ownerId = conversationData['ownerId']?.toString() ?? '';
      final renterId = conversationData['renterId']?.toString() ?? '';

      // Do not mark messages read if this user is not the owner.
      if (ownerId != user.uid || renterId.isEmpty) return;

      _incomingMessagesReadSubscription = FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .snapshots()
          .listen(
            (snapshot) {
          for (final messageDoc in snapshot.docs) {
            final data = messageDoc.data();

            // Only mark messages sent by the renter as read.
            if (data['senderId']?.toString() != renterId) continue;

            // Avoid duplicate updates while an update is in progress.
            if (!_messagesBeingMarkedRead.add(messageDoc.id)) continue;

            messageDoc.reference.update({
              'isRead': true,
            }).then((_) {
              debugPrint(
                '[OWNER CHAT] Message marked as read: ${messageDoc.id}',
              );
            }).catchError((Object error) {
              debugPrint(
                '[OWNER CHAT] Mark message as read failed: $error',
              );
            }).whenComplete(() {
              _messagesBeingMarkedRead.remove(messageDoc.id);
            });
          }
        },
        onError: (Object error) {
          debugPrint('[OWNER CHAT] Read listener error: $error');
        },
      );
    } catch (e, stackTrace) {
      debugPrint('[OWNER CHAT] Auto mark as read error: $e');
      debugPrint('[OWNER CHAT] Auto mark as read stack: $stackTrace');
    }
  }

  // ============================================================
  // SEND TEXT
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
        imageUrl: null,
        audioUrl: null,
        messageType: "text",
        isRead: false,
        createdAt: Timestamp.now(),
      );

      await chatService.sendMessage(
        conversationId: widget.conversationId,
        message: message,
      );

      _scrollToBottom();
    } catch (e, stackTrace) {
      debugPrint("[OWNER CHAT] Send text error=$e");

      debugPrint("[OWNER CHAT] Send text stack=$stackTrace");

      _showSnack("Failed to send message");
    }
  }

  // ============================================================
  // PICK IMAGE
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
        _showSnack("Failed to upload image");

        return;
      }

      final message = MessageModel(
        id: "",
        senderId: currentUser!.uid,
        message: "",
        imageUrl: url,
        audioUrl: null,
        messageType: "image",
        isRead: false,
        createdAt: Timestamp.now(),
      );

      await chatService.sendMessage(
        conversationId: widget.conversationId,
        message: message,
      );

      _scrollToBottom();
    } catch (e, stackTrace) {
      debugPrint("[OWNER CHAT] Image send error=$e");

      debugPrint("[OWNER CHAT] Image send stack=$stackTrace");

      _showSnack("Failed to send image");
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
    if (currentUser == null) {
      return;
    }

    if (isUploading || isRecording || _isStoppingRecording) {
      return;
    }

    try {
      final permission = await Permission.microphone.request();

      if (!permission.isGranted) {
        if (permission.isPermanentlyDenied) {
          _showMicrophonePermissionDialog();
        } else {
          _showSnack("Microphone permission is required");
        }

        return;
      }

      final hasPermission = await _recorder.hasPermission();

      if (!hasPermission) {
        _showMicrophonePermissionDialog();

        return;
      }

      final isAlreadyRecording = await _recorder.isRecording();

      if (isAlreadyRecording) {
        return;
      }

      final directory = await getTemporaryDirectory();

      final path =
          '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: path,
      );

      final recordingStarted = await _recorder.isRecording();

      if (!recordingStarted) {
        _showSnack("Could not start voice recording");

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        isRecording = true;
        _recordingPath = path;
      });

      _startAmplitudeMonitor();
    } catch (e, stackTrace) {
      debugPrint('[OWNER CHAT] START RECORDING ERROR=$e');

      debugPrint('[OWNER CHAT] START RECORDING STACK=$stackTrace');

      if (mounted) {
        setState(() {
          isRecording = false;
          _recordingPath = null;
        });
      }

      _stopAmplitudeMonitor();

      _showSnack("Failed to start voice recording");
    }
  }

  // ============================================================
  // AMPLITUDE
  // ============================================================

  void _startAmplitudeMonitor() {
    _amplitudeTimer?.cancel();

    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 500), (
      _,
    ) async {
      if (!isRecording) {
        return;
      }

      try {
        await _recorder.getAmplitude();
      } catch (_) {}
    });
  }

  // ============================================================
  // STOP AMPLITUDE
  // ============================================================

  void _stopAmplitudeMonitor() {
    _amplitudeTimer?.cancel();

    _amplitudeTimer = null;
  }

  // ============================================================
  // STOP + SEND RECORDING
  // ============================================================

  Future<void> _stopAndSendRecording() async {
    if (!isRecording) {
      return;
    }

    if (_isStoppingRecording) {
      return;
    }

    _isStoppingRecording = true;

    try {
      _stopAmplitudeMonitor();

      final path = await _recorder.stop();

      if (mounted) {
        setState(() {
          isRecording = false;
          _recordingPath = null;
        });
      }

      if (path == null || path.isEmpty) {
        _showSnack("No voice recording found");

        return;
      }

      if (currentUser == null) {
        await _deleteLocalFile(path);

        return;
      }

      final file = File(path);

      if (!await file.exists()) {
        throw Exception("Recording file does not exist");
      }

      final fileSize = await file.length();

      if (fileSize <= 0) {
        throw Exception("Recording file is empty");
      }

      if (mounted) {
        setState(() {
          isUploading = true;
        });
      }

      final url = await cloudinaryService.uploadAudio(file);

      if (url == null || url.isEmpty) {
        _showSnack("Failed to upload voice");

        return;
      }

      final message = MessageModel(
        id: "",
        senderId: currentUser!.uid,
        message: "",
        imageUrl: null,
        audioUrl: url,
        messageType: "audio",
        isRead: false,
        createdAt: Timestamp.now(),
      );

      await chatService.sendVoiceMessage(
        conversationId: widget.conversationId,
        message: message,
      );

      _scrollToBottom();

      await _deleteLocalFile(path);
    } catch (e, stackTrace) {
      debugPrint('[OWNER CHAT] VOICE ERROR=$e');

      debugPrint('[OWNER CHAT] VOICE STACK=$stackTrace');

      _showSnack("Failed to send voice message");
    } finally {
      _isStoppingRecording = false;

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
    if (!isRecording || _isStoppingRecording) {
      return;
    }

    _isStoppingRecording = true;

    try {
      _stopAmplitudeMonitor();

      final savedPath = _recordingPath;

      final stoppedPath = await _recorder.stop();

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
    } catch (e) {
      debugPrint('[OWNER CHAT] RECORD CANCEL ERROR=$e');

      if (mounted) {
        setState(() {
          isRecording = false;
          _recordingPath = null;
        });
      }
    } finally {
      _isStoppingRecording = false;
    }
  }

  // ============================================================
  // DELETE LOCAL FILE
  // ============================================================

  Future<void> _deleteLocalFile(String path) async {
    try {
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[OWNER CHAT] Delete local file error=$e');
    }
  }

  // ============================================================
  // PLAY VOICE
  // ============================================================

  Future<void> _playVoice(String url, String messageId) async {
    try {
      if (url.isEmpty) {
        _showSnack("Audio URL is missing");

        return;
      }

      // --------------------------------------------------------
      // STOP CURRENT AUDIO
      // --------------------------------------------------------

      if (currentlyPlayingId == messageId) {
        await _audioPlayer.stop();

        if (mounted) {
          setState(() {
            currentlyPlayingId = null;
          });
        }

        return;
      }

      await _audioPlayer.stop();

      if (!mounted) {
        return;
      }

      setState(() {
        currentlyPlayingId = messageId;
      });

      await _audioPlayer.play(UrlSource(url));
    } catch (e, stackTrace) {
      debugPrint('[OWNER CHAT] AUDIO ERROR=$e');

      debugPrint('[OWNER CHAT] AUDIO STACK=$stackTrace');

      if (mounted) {
        setState(() {
          currentlyPlayingId = null;
        });
      }

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

      _showSnack("Failed to delete message");
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

                  _showSnack("Failed to edit message");
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
  // MICROPHONE DIALOG
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
            "Microphone access is disabled. Please enable microphone permission in Settings to record voice messages.",
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
  // SNACK
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _textPrimary,
          ),
        ),

        titleSpacing: 0,

        title: Row(
          children: [
            // --------------------------------------------------
            // RENTER AVATAR
            // --------------------------------------------------
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary.withOpacity(0.10),
              ),
              child: ClipOval(
                child: renterImage != null && renterImage!.isNotEmpty
                    ? Image.network(
                        renterImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person_rounded,
                            color: _primary,
                          );
                        },
                      )
                    : const Icon(
                        Icons.person_rounded,
                        color: _primary,
                        size: 23,
                      ),
              ),
            ),

            const SizedBox(width: 11),

            // --------------------------------------------------
            // NAME + PROPERTY
            // --------------------------------------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    renterName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Row(
                    children: [
                      const Icon(
                        Icons.home_work_outlined,
                        size: 12,
                        color: _primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.propertyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        actions: [
          // ----------------------------------------------------
          // MORE
          // ----------------------------------------------------
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: _textPrimary),
            onSelected: (value) {
              if (value == "clear") {
                _showSnack("Conversation management");
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: "clear",
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20),
                      SizedBox(width: 10),
                      Text("Conversation Info"),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
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
                // ----------------------------------------------
                // LOADING
                // ----------------------------------------------

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primary),
                  );
                }

                // ----------------------------------------------
                // ERROR
                // ----------------------------------------------

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 42,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Failed to load messages",
                          style: TextStyle(color: _textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                // ----------------------------------------------
                // AUTO SCROLL
                // ----------------------------------------------

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

                // ----------------------------------------------
                // EMPTY
                // ----------------------------------------------

                if (messages.isEmpty) {
                  return _buildEmptyChat();
                }

                // ----------------------------------------------
                // MESSAGE LIST
                // ----------------------------------------------

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];

                    final isMe = msg.senderId == currentUser?.uid;

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
                        // ----------------------------------------
                        // DATE
                        // ----------------------------------------
                        if (showDate)
                          _buildDateSeparator(msg.createdAt.toDate()),

                        // ----------------------------------------
                        // MESSAGE
                        // ----------------------------------------
                        _buildMessageBubble(msg, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ----------------------------------------------------
          // UPLOAD PROGRESS
          // ----------------------------------------------------
          if (isUploading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: _primary,
              backgroundColor: Colors.transparent,
            ),

          // ----------------------------------------------------
          // RECORDING
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
  // EMPTY CHAT
  // ============================================================

  Widget _buildEmptyChat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 34,
                color: _primary,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              "Start a conversation",
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Send a message to $renterName about ${widget.propertyName}.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE SEPARATOR
  // ============================================================

  Widget _buildDateSeparator(DateTime date) {
    String text;

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final messageDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(messageDate).inDays;

    if (difference == 0) {
      text = "Today";
    } else if (difference == 1) {
      text = "Yesterday";
    } else {
      text = DateFormat("EEE, dd MMM yyyy").format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: _border)),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
            ),
          ),

          Expanded(child: Container(height: 1, color: _border)),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT AREA
  // ============================================================

  Widget _buildInputArea() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: _border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // --------------------------------------------------
            // IMAGE
            // --------------------------------------------------
            _inputButton(
              icon: Icons.add_photo_alternate_outlined,
              onTap: isUploading ? null : _pickAndSendImage,
            ),

            // --------------------------------------------------
            // VOICE
            // --------------------------------------------------
            GestureDetector(
              onLongPressStart: (_) {
                _startRecording();
              },
              onLongPressEnd: (_) {
                _stopAndSendRecording();
              },
              child: Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
                child: Icon(
                  Icons.mic_none_rounded,
                  size: 21,
                  color: isUploading ? _textSecondary : _primary,
                ),
              ),
            ),

            // --------------------------------------------------
            // TEXT
            // --------------------------------------------------
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 42,
                  maxHeight: 120,
                ),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(color: _border),
                ),
                child: TextField(
                  controller: messageController,
                  enabled: !isUploading,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) {
                    sendMessage();
                  },
                ),
              ),
            ),

            const SizedBox(width: 7),

            // --------------------------------------------------
            // SEND
            // --------------------------------------------------
            GestureDetector(
              onTap: isUploading ? null : sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isUploading ? Colors.grey : _primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INPUT BUTTON
  // ============================================================

  Widget _inputButton({required IconData icon, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
        child: Icon(
          icon,
          size: 21,
          color: onTap == null ? _textSecondary : _primary,
        ),
      ),
    );
  }

  // ============================================================
  // RECORDING AREA
  // ============================================================

  Widget _buildRecordingArea() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: _border)),
        ),
        child: Row(
          children: [
            // --------------------------------------------------
            // CANCEL
            // --------------------------------------------------
            GestureDetector(
              onTap: _cancelRecording,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // --------------------------------------------------
            // RECORDING
            // --------------------------------------------------
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(color: Colors.red.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 9),

                    const Expanded(
                      child: Text(
                        "Recording voice...",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const Text(
                      "Release to send",
                      style: TextStyle(color: _textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // --------------------------------------------------
            // SEND
            // --------------------------------------------------
            GestureDetector(
              onTap: _stopAndSendRecording,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    final time = DateFormat("HH:mm").format(msg.createdAt.toDate());

    final isImage = msg.messageType == "image";

    final isVoice = msg.messageType == "audio" || msg.messageType == "voice";

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          _showMessageOptions(msg);
        },
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.76,
          ),
          margin: const EdgeInsets.only(bottom: 7),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: isImage
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? _myBubble : _otherBubble,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(19),
                    topRight: const Radius.circular(19),
                    bottomLeft: Radius.circular(isMe ? 19 : 5),
                    bottomRight: Radius.circular(isMe ? 5 : 19),
                  ),
                  border: !isMe ? Border.all(color: _border) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.035),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildMessageContent(msg, isMe, isImage, isVoice),
              ),

              const SizedBox(height: 3),

              // ------------------------------------------------
              // TIME
              // ------------------------------------------------
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: const TextStyle(fontSize: 10, color: _textSecondary),
                  ),

                  if (msg.isEdited)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                        "edited",
                        style: TextStyle(
                          fontSize: 9,
                          color: _textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  if (isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        msg.isRead
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 13,
                        color: msg.isRead ? _primary : _textSecondary,
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
    // ==========================================================
    // IMAGE
    // ==========================================================

    if (isImage) {
      final imageUrl = msg.imageUrl != null && msg.imageUrl!.isNotEmpty
          ? msg.imageUrl!
          : msg.message;

      if (imageUrl.isEmpty) {
        return const SizedBox(
          width: 220,
          height: 120,
          child: Icon(Icons.broken_image_outlined, color: Colors.grey),
        );
      }

      return GestureDetector(
        onTap: () {
          _previewImage(imageUrl);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(
            imageUrl,
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

    // ==========================================================
    // AUDIO
    // ==========================================================

    if (isVoice) {
      String audioUrl = "";

      if (msg.messageType == "audio") {
        audioUrl = msg.audioUrl ?? "";
      } else {
        audioUrl = msg.message;
      }

      if (audioUrl.isEmpty) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: isMe ? Colors.white : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              "Audio unavailable",
              style: TextStyle(color: isMe ? Colors.white : _textPrimary),
            ),
          ],
        );
      }

      final isPlaying = currentlyPlayingId == msg.id;

      return GestureDetector(
        onTap: () {
          _playVoice(audioUrl, msg.id);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withOpacity(0.15)
                    : _primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isMe ? Colors.white : _primary,
                size: 23,
              ),
            ),

            const SizedBox(width: 10),

            // -----------------------------------------------
            // VOICE WAVE
            // -----------------------------------------------
            SizedBox(
              width: 90,
              height: 25,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(18, (index) {
                  final heights = [
                    7.0,
                    13.0,
                    9.0,
                    17.0,
                    11.0,
                    20.0,
                    14.0,
                    8.0,
                    18.0,
                    12.0,
                    21.0,
                    10.0,
                    16.0,
                    8.0,
                    14.0,
                    19.0,
                    10.0,
                    7.0,
                  ];

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.2),
                      height: heights[index],
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.white.withOpacity(0.75)
                            : _primary.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(width: 8),

            Text(
              isPlaying ? "..." : "Voice",
              style: TextStyle(
                color: isMe ? Colors.white : _textPrimary,
                fontSize: 12,
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
