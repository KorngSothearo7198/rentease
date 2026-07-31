import 'package:flutter/material.dart';

class ChaerDetailScreen extends StatefulWidget {
  final String hostName;
  final String propertyName;

  const ChaerDetailScreen({
    super.key,
    this.hostName = "Alex Montgomery",
    this.propertyName = "Azure Bay Residence",
  });

  @override
  State<ChaerDetailScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChaerDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> messages = [
    {
      "isMe": false,
      "text": "Hello! Thanks for your interest in the Azure Villa. Let me know if you have any questions about the amenities or availability.",
      "time": "10:42 AM"
    },
    {
      "isMe": true,
      "text": "Hi Alex, it looks beautiful. Could you show me what the living room looks like with natural light?",
      "time": "10:45 AM"
    },
    {
      "isMe": false,
      "text": "Here is a shot from yesterday afternoon. The floor-to-ceiling windows really open up the space.",
      "time": "10:48 AM",
      "image": "https://source.unsplash.com/random/600x400/?luxurylivingroom"
    },
    {
      "isMe": false,
      "text": "",
      "time": "10:52 AM",
      "isVoice": true,
      "duration": "0:12"
    },
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      messages.add({
        "isMe": true,
        "text": _messageController.text.trim(),
        "time": "10:55 AM",
      });
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: const NetworkImage('https://source.unsplash.com/random/100x100/?man'),
              radius: 18,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.hostName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('Host', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: const [
          IconButton(icon: Icon(Icons.videocam_outlined), onPressed: null),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 28),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.mic, color: Color(0xFF6B46C1)),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final bool isMe = msg['isMe'];

    if (msg['isVoice'] == true) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF6B46C1) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: LinearProgressIndicator(
                  value: 0.6,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(msg['duration'], style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    if (msg['image'] != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(msg['image'], width: 280),
            ),
            const SizedBox(height: 4),
            Text(msg['time'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF6B46C1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg['text'],
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              msg['time'],
              style: TextStyle(fontSize: 11, color: isMe ? Colors.white70 : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}