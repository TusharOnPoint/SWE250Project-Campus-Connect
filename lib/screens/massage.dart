import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';

class MessagesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Messages')),
      body: FriendListScreen(),
    );
  }
}

class FriendListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String? currentUserID = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserID == null) {
      return Center(child: Text('Please log in.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserID)
          .collection('friends')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No friends found.'));
        }

        var friends = snapshot.data!.docs;
        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            String friendID = friends[index].id;
            return ListTile(
              title: Text(friends[index]['username']),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(friendID: friendID),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String friendID;
  ChatScreen({required this.friendID});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController _messageController = TextEditingController();
  File? _file;
  String? _fileType;

  Future<void> _sendMessage() async {
    String messageContent = _messageController.text;
    if (messageContent.isNotEmpty || _file != null) {
      String userID = FirebaseAuth.instance.currentUser!.uid;
      String message = _file != null ? await _encodeFileToBase64(_file!) : messageContent;
      await FirebaseFirestore.instance.collection('messages').add({
        'senderID': userID,
        'receiverID': widget.friendID,
        'content': message,
        'fileType': _fileType,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        _messageController.clear();
        _file = null;
        _fileType = null;
      });
    }
  }

  Future<String> _encodeFileToBase64(File file) async {
    List<int> fileBytes = await file.readAsBytes();
    return base64Encode(fileBytes);
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null) {
      setState(() {
        _file = File(result.files.single.path!);
        String fileExtension = result.files.single.extension!.toLowerCase();
        if (['jpg', 'jpeg', 'png'].contains(fileExtension)) {
          _fileType = 'image';
        } else if (['mp4', 'avi', 'mov'].contains(fileExtension)) {
          _fileType = 'video';
        } else if (['mp3', 'wav', 'ogg'].contains(fileExtension)) {
          _fileType = 'audio';
        } else {
          _fileType = 'file';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with Friend')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('receiverID', isEqualTo: widget.friendID)
                  .where('senderID', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No messages yet.'));
                }

                var messages = snapshot.data!.docs;
                return ListView(
                  reverse: true,
                  children: messages.map((message) {
                    String content = message['content'];
                    String? fileType = message['fileType'];
                    if (fileType == 'image') {
                      return ListTile(title: Image.memory(base64Decode(content)));
                    } else if (fileType == 'video') {
                      return ListTile(title: Icon(Icons.play_arrow));
                    } else if (fileType == 'audio') {
                      return ListTile(title: Icon(Icons.play_arrow));
                    } else {
                      return ListTile(title: Text(content));
                    }
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(icon: Icon(Icons.attach_file), onPressed: _pickFile),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: 'Enter message...'),
                  ),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}