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
  final String propertyName;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.hostName,
    required this.propertyName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

// ============================================================
// EDIT MESSAGE DIALOG
// ============================================================

class _EditMessageDialog extends StatefulWidget {
  final String initialText;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color surface;
  final ValueChanged<String> onSave;

  const _EditMessageDialog({
    required this.initialText,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.surface,
    required this.onSave,
  });

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialText);

    // Put cursor at the end.
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      return;
    }

    widget.onSave(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.surface,

      title: Text(
        "Edit Message",
        style: TextStyle(
          color: widget.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),

      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 5,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(color: widget.textPrimary),
        cursorColor: const Color(0xFF4F46E5),

        decoration: InputDecoration(
          hintText: "Enter message",

          hintStyle: TextStyle(color: widget.textSecondary),

          filled: true,

          fillColor: widget.isDark
              ? const Color(0xFF1A1A1A)
              : const Color(0xFFF8FAFC),

          contentPadding: const EdgeInsets.all(12),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
          ),
        ),

        onSubmitted: (_) {
          _save();
        },
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Cancel"),
        ),

        ElevatedButton(
          onPressed: _save,

          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 0,
          ),

          child: const Text(
            "Save",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  // ============================================================
  // SERVICES
  // ============================================================

  final TextEditingController messageController = TextEditingController();

  final ChatService chatService = ChatService();

  final CloudinaryService cloudinaryService = CloudinaryService();

  final ScrollController _scrollController = ScrollController();

  final ImagePicker _picker = ImagePicker();

  final AudioRecorder _recorder = AudioRecorder();

  final AudioPlayer _audioPlayer = AudioPlayer();

  // ============================================================
  // STATE
  // ============================================================

  User? currentUser;

  bool isUploading = false;

  bool isRecording = false;

  String? currentlyPlayingId;

  String? _recordingPath;

  StreamSubscription<void>? _audioCompleteSubscription;

  // Monitors microphone input while recording.
  Timer? _amplitudeTimer;

  // Used to detect new messages and scroll only when needed.
  int _lastMessageCount = 0;

  // ============================================================
  // LOGGER
  // ============================================================

  void _log(String message) {
    debugPrint('[CHAT][${DateTime.now().toIso8601String()}] $message');
  }

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _primary = Color(0xFF4F46E5);

  static const Color _lightBackground = Color(0xFFF8FAFC);

  static const Color _lightSurface = Colors.white;

  static const Color _lightTextPrimary = Color(0xFF0F172A);

  static const Color _lightTextSecondary = Color(0xFF64748B);

  static const Color _darkBackground = Colors.black;

  static const Color _darkSurface = Color(0xFF111111);

  static const Color _darkTextPrimary = Color(0xFFF8FAFC);

  static const Color _darkTextSecondary = Color(0xFF94A3B8);

  // ============================================================
  // THEME
  // ============================================================

  bool _isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _backgroundColor(BuildContext context) {
    return _isDarkMode(context) ? _darkBackground : _lightBackground;
  }

  Color _surfaceColor(BuildContext context) {
    return _isDarkMode(context) ? _darkSurface : _lightSurface;
  }

  Color _textPrimaryColor(BuildContext context) {
    return _isDarkMode(context) ? _darkTextPrimary : _lightTextPrimary;
  }

  Color _textSecondaryColor(BuildContext context) {
    return _isDarkMode(context) ? _darkTextSecondary : _lightTextSecondary;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _log('01 - initState START');

    currentUser = FirebaseAuth.instance.currentUser;

    debugPrint('[CHAT DEBUG] 02 - currentUser.uid = ${currentUser?.uid}');

    debugPrint('[CHAT DEBUG] 03 - currentUser.email = ${currentUser?.email}');

    debugPrint('[CHAT DEBUG] 04 - conversationId = ${widget.conversationId}');

    debugPrint('[CHAT DEBUG] 05 - hostName = ${widget.hostName}');

    debugPrint('[CHAT DEBUG] 06 - propertyName = ${widget.propertyName}');

    _audioCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      debugPrint('[CHAT DEBUG] AUDIO - playback completed');

      if (!mounted) {
        debugPrint('[CHAT DEBUG] AUDIO - widget is NOT mounted');
        return;
      }

      setState(() {
        currentlyPlayingId = null;
      });

      debugPrint('[CHAT DEBUG] AUDIO - currentlyPlayingId cleared');
    });

    _log('07 - initState END');
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();

    _audioCompleteSubscription?.cancel();
    _amplitudeTimer?.cancel();

    _recorder.dispose();
    _audioPlayer.dispose();

    super.dispose();
  }

  // ============================================================
  // MESSAGE LOGGER
  // ============================================================

  void _logMessage(String prefix, MessageModel msg) {
    debugPrint(
      '[CHAT DEBUG] $prefix | '
      'id=${msg.id} | '
      'senderId=${msg.senderId} | '
      'type=${msg.messageType} | '
      'message="${msg.message}" | '
      'isRead=${msg.isRead} | '
      'isEdited=${msg.isEdited} | '
      'createdAt=${msg.createdAt.toDate()}',
    );
  }

  // ============================================================
  // MICROPHONE AMPLITUDE MONITOR
  // ============================================================

  void _startAmplitudeMonitor() {
    // Prevent multiple timers.
    _amplitudeTimer?.cancel();

    _log('VOICE AMP 01 - Starting amplitude monitor');

    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 500), (
      _,
    ) async {
      if (!isRecording) {
        return;
      }

      try {
        final amplitude = await _recorder.getAmplitude();

        _log(
          'VOICE AMPLITUDE - '
          'current=${amplitude.current} '
          'max=${amplitude.max}',
        );
      } catch (e) {
        _log('VOICE AMPLITUDE ERROR - $e');
      }
    });
  }

  void _stopAmplitudeMonitor() {
    if (_amplitudeTimer != null) {
      _log('VOICE AMP 02 - Stopping amplitude monitor');
    }

    _amplitudeTimer?.cancel();

    _amplitudeTimer = null;
  }

  // ============================================================
  // SEND TEXT MESSAGE
  // ============================================================

  Future<void> sendMessage() async {
    if (currentUser == null) {
      _showSnack("Please login first");
      return;
    }

    if (isUploading || isRecording) {
      return;
    }

    final text = messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

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

      if (!mounted) return;

      messageController.clear();

      _scrollToBottom();
    } catch (e) {
      debugPrint("Send message error: $e");

      if (!mounted) return;

      _showSnack("Failed to send message");
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
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (pickedFile == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        isUploading = true;
      });

      final url = await cloudinaryService.uploadImage(File(pickedFile.path));

      if (url == null || url.isEmpty) {
        if (mounted) {
          _showSnack("Failed to upload image");
        }

        return;
      }

      if (currentUser == null) {
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

      await chatService.sendMessage(
        conversationId: widget.conversationId,
        message: message,
      );

      _scrollToBottom();
    } catch (e) {
      debugPrint("Image error: $e");

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
    _log('VOICE 01 - _startRecording START');

    if (isUploading) {
      _log('VOICE 02 - STOP: currently uploading');
      return;
    }

    if (isRecording) {
      _log('VOICE 03 - STOP: already recording');
      return;
    }

    try {
      // --------------------------------------------------------
      // MICROPHONE PERMISSION
      // --------------------------------------------------------

      _log('VOICE 04 - Requesting microphone permission');

      final status = await Permission.microphone.request();

      if (!status.isGranted) {
        _log('VOICE 04A - Microphone permission NOT granted: $status');

        if (status.isPermanentlyDenied || status.isRestricted) {
          if (mounted) {
            _showMicrophonePermissionDialog();
          }
        } else {
          _showSnack("Microphone permission is required");
        }

        return;
      }

      _log('VOICE 05 - Microphone permission status=$status');

      _log('VOICE 06 - isGranted=${status.isGranted}');

      _log('VOICE 07 - isDenied=${status.isDenied}');

      _log(
        'VOICE 08 - isPermanentlyDenied='
        '${status.isPermanentlyDenied}',
      );

      _log('VOICE 09 - isRestricted=${status.isRestricted}');

      if (status.isPermanentlyDenied || status.isRestricted) {
        _log('VOICE 10 - Permission permanently denied/restricted');

        if (mounted) {
          _showMicrophonePermissionDialog();
        }

        return;
      }

      if (!status.isGranted) {
        _log('VOICE 11 - Permission NOT granted');
        return;
      }

      _log('VOICE 12 - Permission granted');

      // --------------------------------------------------------
      // RECORDER PERMISSION
      // --------------------------------------------------------

      final hasPermission = await _recorder.hasPermission();

      _log('VOICE 13 - recorder.hasPermission=$hasPermission');

      if (!hasPermission) {
        _log('VOICE 14 - Recorder does not have permission');

        if (mounted) {
          _showSnack("Microphone permission is required");
        }

        return;
      }

      // --------------------------------------------------------
      // RECORDING PATH
      // --------------------------------------------------------

      final directory = await getTemporaryDirectory();

      _log('VOICE 15 - Temporary directory=${directory.path}');

      final path =
          "${directory.path}/voice_"
          "${DateTime.now().millisecondsSinceEpoch}.wav";

      _log('VOICE 16 - Recording path=$path');

      // --------------------------------------------------------
      // START WAV RECORDING
      // --------------------------------------------------------

      _log('VOICE 17 - Starting recorder');

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );

      _log('VOICE 18 - Recorder STARTED');

      if (!mounted) {
        _log('VOICE 19 - STOP: widget no longer mounted');
        return;
      }

      setState(() {
        isRecording = true;
        _recordingPath = path;
      });

      _log('VOICE 20 - isRecording=true');

      _log('VOICE 21 - _recordingPath=$path');

      // --------------------------------------------------------
      // START MICROPHONE AMPLITUDE MONITOR
      // --------------------------------------------------------

      _startAmplitudeMonitor();

      _log('VOICE 22 - _startRecording END');
    } catch (e, stackTrace) {
      _log('VOICE ERROR - $e');

      debugPrint('[CHAT][VOICE ERROR STACK] $stackTrace');

      if (mounted) {
        _showSnack("Could not start recording");
      }
    }
  }

  // ============================================================
  // MICROPHONE PERMISSION DIALOG
  // ============================================================

  void _showMicrophonePermissionDialog() {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Microphone Permission"),
          content: const Text(
            "Microphone access is disabled for RentEase. "
            "Please enable microphone permission in Settings "
            "to send voice messages.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                await openAppSettings();
              },
              child: const Text("Open Settings"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // STOP + SEND RECORDING
  // ============================================================

  Future<void> _stopAndSendRecording() async {
    if (!isRecording) {
      return;
    }

    try {
      // Stop amplitude monitoring before stopping recorder.
      _stopAmplitudeMonitor();

      _log('VOICE STOP 01 - Stopping recorder');

      final path = await _recorder.stop();

      _log('VOICE STOP 02 - Recorder stopped, path=$path');

      if (mounted) {
        setState(() {
          isRecording = false;
          _recordingPath = null;
        });
      }

      if (path == null || path.isEmpty) {
        _log('VOICE STOP 03 - No recording path');
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

      final file = File(path);

      if (!await file.exists()) {
        throw Exception("Recording file does not exist");
      }

      // --------------------------------------------------------
      // CHECK LOCAL FILE
      // --------------------------------------------------------

      final fileSize = await file.length();

      _log('VOICE FILE - path=$path');

      _log('VOICE FILE - size=$fileSize bytes');

      final bytes = await file.readAsBytes();

      _log('VOICE FILE - total bytes=${bytes.length}');

      // --------------------------------------------------------
      // UPLOAD TO CLOUDINARY
      // --------------------------------------------------------

      _log('VOICE UPLOAD - Starting Cloudinary upload');

      final url = await cloudinaryService.uploadAudio(file);

      if (url == null || url.isEmpty) {
        if (mounted) {
          _showSnack("Failed to upload voice");
        }

        await _deleteLocalFile(path);

        return;
      }

      _log('VOICE UPLOAD - Cloudinary URL=$url');

      // --------------------------------------------------------
      // CREATE MESSAGE
      // --------------------------------------------------------

      final message = MessageModel(
        id: "",
        senderId: currentUser!.uid,
        message: url,
        messageType: "voice",
        isRead: false,
        createdAt: Timestamp.now(),
      );

      // Use generic sendMessage().
      await chatService.sendMessage(
        conversationId: widget.conversationId,
        message: message,
      );

      _log('VOICE SEND - Voice message sent successfully');

      _scrollToBottom();

      await _deleteLocalFile(path);
    } catch (e, stackTrace) {
      debugPrint("Voice upload error: $e");

      debugPrint("Voice upload stack: $stackTrace");

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
      debugPrint(
        '[CHAT DEBUG] RECORD - '
        'cancel ignored, not recording',
      );

      return;
    }

    try {
      // Stop amplitude monitor first.
      _stopAmplitudeMonitor();

      debugPrint('[CHAT DEBUG] RECORD - cancelling recording');

      final savedPath = _recordingPath;

      debugPrint('[CHAT DEBUG] RECORD - savedPath=$savedPath');

      final stoppedPath = await _recorder.stop();

      debugPrint(
        '[CHAT DEBUG] RECORD - '
        'stoppedPath=$stoppedPath',
      );

      if (mounted) {
        setState(() {
          isRecording = false;
          _recordingPath = null;
        });
      }

      final localPath = stoppedPath ?? savedPath;

      debugPrint(
        '[CHAT DEBUG] RECORD - '
        'deleting path=$localPath',
      );

      if (localPath != null && localPath.isNotEmpty) {
        await _deleteLocalFile(localPath);
      }

      debugPrint('[CHAT DEBUG] RECORD - cancel completed');
    } catch (e, stackTrace) {
      debugPrint('[CHAT DEBUG] RECORD CANCEL ERROR=$e');

      debugPrint('[CHAT DEBUG] RECORD CANCEL STACK=$stackTrace');

      if (mounted) {
        setState(() {
          isRecording = false;
          _recordingPath = null;
        });
      }
    }
  }

  // ============================================================
  // DELETE LOCAL RECORDING FILE
  // ============================================================

  Future<void> _deleteLocalFile(String path) async {
    try {
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("Delete local file error: $e");
    }
  }

  // ============================================================
  // PLAY VOICE
  // ============================================================

  Future<void> _playVoice(String url, String messageId) async {
    try {
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
    } catch (e) {
      debugPrint("Play voice error: $e");

      if (!mounted) return;

      setState(() {
        currentlyPlayingId = null;
      });

      _showSnack("Unable to play voice message");
    }
  }

  // ============================================================
  // EDIT MESSAGE
  // ============================================================

  // ============================================================
  // EDIT MESSAGE
  // ============================================================

  Future<void> _editMessage(MessageModel msg) async {
    _log('EDIT 01 - _editMessage START');

    if (!mounted) return;

    if (msg.messageType != "text") {
      _showSnack("Only text messages can be edited");
      return;
    }

    if (msg.senderId != currentUser?.uid) {
      _log('EDIT 02 - Message does not belong to current user');
      return;
    }

    _logMessage("EDIT 03 - Selected message", msg);

    // ----------------------------------------------------------
    // SHOW EDIT DIALOG
    //
    // The controller belongs to the dialog.
    // Do NOT create/dispose it in the parent State.
    // ----------------------------------------------------------

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _EditMessageDialog(
          initialText: msg.message,
          isDark: _isDarkMode(dialogContext),
          textPrimary: _textPrimaryColor(dialogContext),
          textSecondary: _textSecondaryColor(dialogContext),
          surface: _surfaceColor(dialogContext),
          onSave: (text) {
            Navigator.of(dialogContext).pop(text);
          },
        );
      },
    );

    _log('EDIT 04 - Dialog closed');
    _log('EDIT 05 - result=$result');

    if (!mounted) return;

    if (result == null) {
      _log('EDIT 06 - Edit cancelled');
      return;
    }

    final newText = result.trim();

    if (newText.isEmpty) {
      _showSnack("Message cannot be empty");
      return;
    }

    if (newText == msg.message.trim()) {
      _log('EDIT 07 - Text unchanged');
      return;
    }

    try {
      _log('EDIT 08 - Updating Firestore');

      await chatService.editMessage(
        conversationId: widget.conversationId,
        messageId: msg.id,
        newText: newText,
      );

      _log('EDIT 09 - Firestore update successful');

      if (!mounted) return;

      _showSnack("Message edited");
    } catch (e, stackTrace) {
      debugPrint('[CHAT DEBUG] EDIT ERROR - $e');
      debugPrint('[CHAT DEBUG] EDIT STACKTRACE - $stackTrace');

      if (!mounted) return;

      _showSnack("Failed to edit message");
    }

    _log('EDIT 10 - _editMessage END');
  }

  // ============================================================
  // DELETE MESSAGE
  // ============================================================

  Future<void> _deleteMessage(MessageModel msg) async {
    if (msg.senderId != currentUser?.uid) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceColor(dialogContext),
          title: Text(
            "Delete Message?",
            style: TextStyle(color: _textPrimaryColor(dialogContext)),
          ),
          content: Text(
            "Are you sure you want to delete this message?",
            style: TextStyle(color: _textSecondaryColor(dialogContext)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    try {
      await chatService.deleteMessage(
        conversationId: widget.conversationId,
        messageId: msg.id,
      );

      if (currentlyPlayingId == msg.id) {
        await _audioPlayer.stop();

        if (!mounted) return;

        setState(() {
          currentlyPlayingId = null;
        });
      }
    } catch (e) {
      debugPrint("Delete message error: $e");

      if (!mounted) return;

      _showSnack("Failed to delete message");
    }
  }

  // ============================================================
  // MESSAGE ACTION MENU
  // ============================================================

  Future<void> _showMessageActions(MessageModel msg) async {
    if (!mounted) return;

    final bool isMe = msg.senderId == currentUser?.uid;

    if (!isMe) {
      return;
    }

    final bool isText = msg.messageType == "text";

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _surfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),

              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 12),

              if (isText)
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: _primary),
                  title: Text(
                    "Edit Message",
                    style: TextStyle(color: _textPrimaryColor(sheetContext)),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop("edit");
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
                  Navigator.of(sheetContext).pop("delete");
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.close_rounded,
                  color: _textSecondaryColor(sheetContext),
                ),
                title: Text(
                  "Cancel",
                  style: TextStyle(color: _textPrimaryColor(sheetContext)),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop("cancel");
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    if (result == "edit") {
      await _editMessage(msg);
    } else if (result == "delete") {
      await _deleteMessage(msg);
    }
  }

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================

  void _previewImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                "Image",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return const CircularProgressIndicator(color: Colors.white);
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 60,
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
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_scrollController.hasClients) {
        return;
      }

      if (!_scrollController.position.hasContentDimensions) {
        return;
      }

      final maxScroll = _scrollController.position.maxScrollExtent;

      _scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnack(String text) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isDarkMode(context);

    final Color background = _backgroundColor(context);

    final Color surface = _surfaceColor(context);

    final Color textPrimary = _textPrimaryColor(context);

    final Color textSecondary = _textSecondaryColor(context);

    return Scaffold(
      backgroundColor: background,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.hostName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            Text(
              widget.propertyName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ],
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: Column(
        children: [
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
                  debugPrint(
                    "Message stream error: "
                    "${snapshot.error}",
                  );

                  return Center(
                    child: Text(
                      "Failed to load messages",
                      style: TextStyle(color: _textSecondaryColor(context)),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                // Detect new messages.
                if (messages.length > _lastMessageCount) {
                  _lastMessageCount = messages.length;

                  if (_lastMessageCount > 1) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;

                      if (!_scrollController.hasClients) {
                        return;
                      }

                      if (!_scrollController.position.hasContentDimensions) {
                        return;
                      }

                      _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent,
                      );
                    });
                  }
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No messages yet",
                          style: TextStyle(color: textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Start a conversation",
                          style: TextStyle(
                            color: textSecondary.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildBubble(messages[index]);
                  },
                );
              },
            ),
          ),

          // ======================================================
          // UPLOAD PROGRESS
          // ======================================================
          if (isUploading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: _primary,
              backgroundColor: Colors.transparent,
            ),

          // ======================================================
          // RECORDING AREA
          // ======================================================
          if (isRecording) _buildRecordingArea(),

          // ======================================================
          // INPUT
          // ======================================================
          if (!isRecording)
            Container(
              padding: const EdgeInsets.fromLTRB(8, 10, 12, 20),
              decoration: BoxDecoration(
                color: surface,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.white.withOpacity(0.03)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ==================================================
                  // GALLERY
                  // ==================================================
                  IconButton(
                    onPressed: isUploading ? null : _pickAndSendImage,
                    icon: const Icon(Icons.photo_library_rounded),
                    color: _primary,
                  ),

                  // ==================================================
                  // VOICE
                  // ==================================================
                  GestureDetector(
                    onLongPressStart: (_) {
                      _startRecording();
                    },
                    onLongPressEnd: (_) {
                      _stopAndSendRecording();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: Icon(
                        Icons.mic_none_rounded,
                        color: isUploading ? Colors.grey : _primary,
                      ),
                    ),
                  ),

                  // ==================================================
                  // TEXT FIELD
                  // ==================================================
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !isUploading,
                      style: TextStyle(color: textPrimary, fontSize: 15),
                      cursorColor: _primary,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: textSecondary),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1A1A1A)
                            : _lightBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: const BorderSide(color: _primary),
                        ),
                      ),
                      onSubmitted: (_) {
                        sendMessage();
                      },
                    ),
                  ),

                  const SizedBox(width: 6),

                  // ==================================================
                  // SEND
                  // ==================================================
                  GestureDetector(
                    onTap: isUploading ? null : sendMessage,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isUploading ? Colors.grey : _primary,
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
        ],
      ),
    );
  }

  // ============================================================
  // RECORDING AREA
  // ============================================================

  Widget _buildRecordingArea() {
    final bool isDark = _isDarkMode(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      color: _surfaceColor(context),
      child: Row(
        children: [
          // ======================================================
          // CANCEL RECORDING
          // ======================================================
          IconButton(
            onPressed: _cancelRecording,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            tooltip: "Cancel recording",
          ),

          // ======================================================
          // RECORDING STATUS
          // ======================================================
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : _lightBackground,
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

          // ======================================================
          // SEND RECORDING
          // ======================================================
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

  Widget _buildBubble(MessageModel msg) {
    final bool isMe = msg.senderId == currentUser?.uid;

    final bool isDark = _isDarkMode(context);

    final Color textPrimary = _textPrimaryColor(context);

    final Color textSecondary = _textSecondaryColor(context);

    final Color otherBubble = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    final time = DateFormat('HH:mm').format(msg.createdAt.toDate());

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMe ? () => _showMessageActions(msg) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // ==================================================
              // MESSAGE CONTENT
              // ==================================================
              Container(
                padding: msg.messageType == "image"
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? _primary : otherBubble,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                ),
                child: _buildContent(msg, isMe),
              ),

              const SizedBox(height: 3),

              // ==================================================
              // TIME + EDITED
              // ==================================================
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                  if (msg.isEdited) ...[
                    const SizedBox(width: 4),
                    Text(
                      "Edited",
                      style: TextStyle(
                        fontSize: 10,
                        color: textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
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

  Widget _buildContent(MessageModel msg, bool isMe) {
    final Color textPrimary = _textPrimaryColor(context);

    switch (msg.messageType) {
      // ========================================================
      // IMAGE
      // ========================================================

      case "image":
        return GestureDetector(
          onTap: () {
            _previewImage(msg.message);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              msg.message,
              width: 220,
              height: 220,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }

                return const SizedBox(
                  width: 220,
                  height: 220,
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
                  height: 160,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
          ),
        );

      // ========================================================
      // VOICE
      // ========================================================

      case "voice":
        final bool isPlaying = currentlyPlayingId == msg.id;

        return GestureDetector(
          onTap: () {
            _playVoice(msg.message, msg.id);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: isMe ? Colors.white : _primary,
                size: 36,
              ),
              const SizedBox(width: 10),
              Text(
                isPlaying ? "Playing..." : "Voice message",
                style: TextStyle(
                  color: isMe ? Colors.white : textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );

      // ========================================================
      // TEXT
      // ========================================================

      case "text":
      default:
        return Text(
          msg.message,
          style: TextStyle(
            color: isMe ? Colors.white : textPrimary,
            fontSize: 15,
            height: 1.35,
          ),
        );
    }
  }
}
