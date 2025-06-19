import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  ChatScreen({required this.conversationId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String conversationName = 'Loading...';
  String profileUrl = '';

  void loadConversationData() async {
    final doc = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .get();

    setState(() {
      conversationName = doc['conversationName'] ?? 'Chat';
      profileUrl = doc['conversationProfile'] ?? 'https://via.placeholder.com/150';
    });
  }

  void sendMessage(String text) async {
    final messageRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .doc();

    await messageRef.set({
      'messageId': messageRef.id,
      'sentBy': currentUser.uid,
      'text': text,
      'seenBy': [currentUser.uid],
      'time': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    messageController.clear();
  }

  void markMessagesAsSeen(QuerySnapshot snapshot) async {
    for (var doc in snapshot.docs) {
      List seenBy = doc['seenBy'] ?? [];
      if (!seenBy.contains(currentUser.uid)) {
        await doc.reference.update({
          'seenBy': FieldValue.arrayUnion([currentUser.uid])
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadConversationData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(profileUrl),
            ),
            SizedBox(width: 10),
            Text(conversationName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('time')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  markMessagesAsSeen(snapshot.data!);
                  if (scrollController.hasClients) {
                    scrollController.jumpTo(scrollController.position.maxScrollExtent);
                  }
                });

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final msg = docs[index];
                    final isMe = msg['sentBy'] == currentUser.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Color(0xFFD2F8D2) : Color(0xFFECECEC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.emoji_emotions, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.mic, color: Colors.grey),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (messageController.text.trim().isNotEmpty) {
                      sendMessage(messageController.text.trim());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text('Send', style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
