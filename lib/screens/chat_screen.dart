import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'chat_group_info.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  ChatScreen({required this.conversationId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

// Replace these with your Cloudinary details
const cloudinaryUploadPreset = 'YOUR_UPLOAD_PRESET';
const cloudinaryCloudName = 'YOUR_CLOUD_NAME';

class _ChatScreenState extends State<ChatScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String conversationName = 'Loading...';
  String? profileUrl;
  String conversationType = '';
  File? selectedImage;       // For mobile
  XFile? selectedWebImage;   // For web

  Map<String, dynamic> userCache = {}; // userId => {username, profileImage}

  @override
  void initState() {
    super.initState();
    loadConversationData();
  }

  void loadConversationData() async {
    final doc = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .get();

    if (doc.exists) {
      setState(() {
        conversationName = doc['conversationName'] ?? 'Chat';
        profileUrl = doc['conversationProfile'];
        conversationType = doc['type'] ?? '';
      });
    }
  }

  Future<String?> uploadImageToCloudinary(XFile image) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return data['secure_url'];
    } else {
      print('Cloudinary upload failed: $responseBody');
      return null;
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty && selectedImage == null && selectedWebImage == null) return;

    final conversationDoc = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId);
    final messageRef = conversationDoc.collection('messages').doc();

    String? imageUrl;

    if (selectedImage != null) {
      final xfile = XFile(selectedImage!.path);
      imageUrl = await uploadImageToCloudinary(xfile);
    } else if (selectedWebImage != null) {
      imageUrl = await uploadImageToCloudinary(selectedWebImage!);
    }

    final messageData = {
      'messageId': messageRef.id,
      'sentBy': currentUser.uid,
      'text': text.trim(),
      'seenBy': [currentUser.uid],
      'mediaUrl': imageUrl ?? '',
      'time': FieldValue.serverTimestamp(),
    };

    messageController.clear();
    selectedImage = null;
    selectedWebImage = null;
    setState(() {});

    await messageRef.set(messageData);

    await conversationDoc.update({
      'lastMessage': text.trim().isNotEmpty ? text.trim() : '[Media]',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
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

  Future<Map<String, dynamic>> getUserInfo(String userId) async {
    if (userCache.containsKey(userId)) {
      return userCache[userId]!;
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = {
      'username': doc['username'] ?? 'Unknown',
      'profileImage': doc['profileImage'] ?? '',
    };
    userCache[userId] = data;
    return data;
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('h:mm a').format(timestamp.toDate());
  }

  Widget buildMessageBubble(DocumentSnapshot msg, DocumentSnapshot? prevMsg) {
    final text = msg['text'] ?? '';
    final mediaUrl = msg['mediaUrl'];
    final sentBy = msg['sentBy'];
    final timestamp = msg['time'] as Timestamp?;
    final isMe = sentBy == currentUser.uid;
    final showProfile = prevMsg == null || prevMsg['sentBy'] != sentBy;

    return FutureBuilder<Map<String, dynamic>>(
      future: showProfile && !isMe ? getUserInfo(sentBy) : Future.value({}),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final username = user?['username'] ?? '';
        final userImage = user?['profileImage'] ?? '';

        return Padding(
          padding: EdgeInsets.only(top: showProfile ? 10 : 2, left: 8, right: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe && showProfile)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: userImage.isNotEmpty ? NetworkImage(userImage) : null,
                    child: userImage.isEmpty ? Icon(Icons.person) : null,
                  ),
                )
              else if (!isMe)
                SizedBox(width: 44),

              Flexible(
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe && showProfile)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          username,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: isMe ? Color(0xFFD2F8D2) : Color(0xFFECECEC),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(isMe ? 12 : 0),
                          bottomRight: Radius.circular(isMe ? 0 : 12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (mediaUrl != null && mediaUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(mediaUrl, height: 120, fit: BoxFit.cover),
                            ),
                          if (text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(text, style: TextStyle(fontSize: 16)),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      formatTimestamp(timestamp),
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    if (kIsWeb) {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          selectedWebImage = picked;
        });
      }
    } else {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          selectedImage = File(picked.path);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: InkWell(
          onTap: () {
            if (conversationType == 'group') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupInfoScreen(conversationId: widget.conversationId),
                ),
              );
            }
          },
          child: Row(
            children: [
              profileUrl != null && profileUrl!.isNotEmpty
                  ? CircleAvatar(backgroundImage: NetworkImage(profileUrl!))
                  : CircleAvatar(child: Icon(Icons.group)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  conversationName,
                  style: TextStyle(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
                  .orderBy('time', descending: false)
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
                    final prevMsg = index > 0 ? docs[index - 1] : null;
                    return buildMessageBubble(docs[index], prevMsg);
                  },
                );
              },
            ),
          ),

          if (selectedImage != null || selectedWebImage != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(selectedWebImage!.path, height: 100, fit: BoxFit.cover)
                        : Image.file(selectedImage!, height: 100, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => setState(() {
                        selectedImage = null;
                        selectedWebImage = null;
                      }),
                    ),
                  )
                ],
              ),
            ),

          Divider(height: 1),
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image, color: Colors.teal),
                  onPressed: pickImage,
                ),
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 120),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: messageController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final text = messageController.text.trim();
                    sendMessage(text);
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
