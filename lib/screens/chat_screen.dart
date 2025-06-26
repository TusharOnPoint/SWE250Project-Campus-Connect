import 'dart:io';
import 'package:campus_connect/screens/full_screen_image.dart';
import 'package:campus_connect/services/coudinary_services.dart';
import 'package:file_picker/file_picker.dart';
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

class _ChatScreenState extends State<ChatScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String conversationName = 'Loading...';
  String? profileUrl;
  String conversationType = '';
  FilePickerResult? _selectedFile;

  Map<String, dynamic> userCache = {};

  @override
  void initState() {
    super.initState();
    loadConversationData();
  }

  void loadConversationData() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(widget.conversationId)
            .get();

    if (doc.exists) {
      final data = doc.data()!;
      final participants = List<String>.from(data['participants'] ?? []);
      conversationType = data['type'] ?? '';

      if (conversationType == 'private') {
        final otherUserId = participants.firstWhere(
          (id) => id != currentUser.uid,
          orElse: () => '',
        );
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(otherUserId)
                .get();

        setState(() {
          conversationName = userDoc.data()?['username'] ?? 'Chat';
          profileUrl = userDoc.data()?['profileImage'] ?? '';
        });
      } else {
        setState(() {
          conversationName = data['conversationName'] ?? 'Group';
          profileUrl = data['conversationProfile'];
        });
      }
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty && _selectedFile == null) return;

    final conversationDoc = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId);
    final messageRef = conversationDoc.collection('messages').doc();

    String? imageUrl;
    imageUrl = await uploadToCloudinary(_selectedFile, 'image');

    final messageData = {
      'messageId': messageRef.id,
      'sentBy': currentUser.uid,
      'text': text.trim(),
      'seenBy': [currentUser.uid],
      'mediaUrl': imageUrl ?? '',
      'time': FieldValue.serverTimestamp(),
    };

    messageController.clear();
    _selectedFile = null;
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
          'seenBy': FieldValue.arrayUnion([currentUser.uid]),
        });
      }
    }
  }

  Future<Map<String, dynamic>> getUserInfo(String userId) async {
    if (userCache.containsKey(userId)) {
      return userCache[userId]!;
    }
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final docData = doc.data(); // nullable

    final data = {
      'username': docData?['username'] ?? 'Unknown',
      'profileImage': (docData?['profileImage'] ?? '').toString(),
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
        final userImage = (user?['profileImage'] ?? '') as String;

        return Padding(
          padding: EdgeInsets.only(
            top: showProfile ? 10 : 2,
            left: 8,
            right: 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe && showProfile)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage:
                        userImage.isNotEmpty ? NetworkImage(userImage) : null,
                    child: userImage.isEmpty ? Icon(Icons.person) : null,
                  ),
                )
              else if (!isMe)
                SizedBox(width: 44),

              Flexible(
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe && showProfile)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
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
                          // display message image
                          if (mediaUrl != null && mediaUrl.isNotEmpty)
                            if (mediaUrl != null && mediaUrl.isNotEmpty)
                              GestureDetector(
                                onTap:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => FullScreenImage(
                                              image: NetworkImage(mediaUrl),
                                              heroTag: mediaUrl,
                                            ),
                                      ),
                                    ),
                                child: Hero(
                                  tag: mediaUrl,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      mediaUrl,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),

                          // message txt show
                          if (text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: SelectableText(
                                text,
                                style: TextStyle(fontSize: 16),
                              ),
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

  Future<void> _pickMedia() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() {
      _selectedFile = result;
    });
  }

  Widget _buildMediaPreview() {
    if (_selectedFile == null) return const SizedBox.shrink();

    final img =
        kIsWeb
            ? Image.memory(
              _selectedFile!.files.single.bytes!,
              fit: BoxFit.cover,
            )
            : Image.file(
              File(_selectedFile!.files.single.path!),
              fit: BoxFit.cover,
            );

    const heroTag = 'preview-image';

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => FullScreenImage(
                    image:
                        kIsWeb
                            ? MemoryImage(_selectedFile!.files.single.bytes!)
                            : FileImage(File(_selectedFile!.files.single.path!))
                                as ImageProvider,
                    heroTag: heroTag,
                  ),
            ),
          ),
      child: Hero(
        tag: heroTag,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 100, maxHeight: 100),
          child: ClipRRect(borderRadius: BorderRadius.circular(8), child: img),
        ),
      ),
    );
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
                  builder:
                      (_) => GroupInfoScreen(
                        conversationId: widget.conversationId,
                      ),
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
              stream:
                  FirebaseFirestore.instance
                      .collection('conversations')
                      .doc(widget.conversationId)
                      .collection('messages')
                      .orderBy('time', descending: false)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  markMessagesAsSeen(snapshot.data!);
                  if (scrollController.hasClients) {
                    scrollController.jumpTo(
                      scrollController.position.maxScrollExtent,
                    );
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

          // image preview
          if (_selectedFile != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildMediaPreview(),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.cancel, color: Colors.red),
                      onPressed:
                          () => setState(() {
                            _selectedFile = null;
                          }),
                    ),
                  ),
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
                  onPressed: _pickMedia,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
