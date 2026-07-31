import 'package:flutter/material.dart';

import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
   ChatListScreen({super.key});

  final List<Map<String, dynamic>> chats = [
    {
      "name": "Alex Montgomery",
      "property": "Azure Bay Residence",
      "lastMessage": "Here is a shot from yesterday afternoon...",
      "time": "10:52 AM",
      "unread": 2,
      "avatar": "https://source.unsplash.com/random/100x100/?man",
      "isOnline": true,
    },
    {
      "name": "Sophie Laurent",
      "property": "Villa Belle Époque",
      "lastMessage": "The booking is confirmed for next month.",
      "time": "Yesterday",
      "unread": 0,
      "avatar": "https://source.unsplash.com/random/100x100/?woman",
      "isOnline": false,
    },
    {
      "name": "Michael Chen",
      "property": "Downtown Penthouse",
      "lastMessage": "Would you like to schedule a viewing?",
      "time": "Yesterday",
      "unread": 1,
      "avatar": "https://source.unsplash.com/random/100x100/?asianman",
      "isOnline": true,
    },
    {
      "name": "Emma Thompson",
      "property": "Seaside Cottage",
      "lastMessage": "Thank you! Looking forward to hosting you.",
      "time": "Jul 22",
      "unread": 0,
      "avatar": "https://source.unsplash.com/random/100x100/?woman",
      "isOnline": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(chat['avatar']),
                ),
                if (chat['isOnline'])
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              chat['name'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat['property'],
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B46C1)),
                ),
                Text(
                  chat['lastMessage'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: chat['unread'] > 0 ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat['time'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (chat['unread'] > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6B46C1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      chat['unread'].toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChaerDetailScreen(
                    hostName: chat['name'],
                    propertyName: chat['property'],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: New message / Contact new owner
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New message feature coming soon')),
          );
        },
        backgroundColor: const Color(0xFF6B46C1),
        child: const Icon(Icons.message),
      ),
    );
  }
}