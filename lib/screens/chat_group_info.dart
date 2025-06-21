import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const cloudinaryUploadPreset = 'YOUR_UPLOAD_PRESET'; // <-- Replace with actual preset
const cloudinaryCloudName = 'YOUR_CLOUD_NAME';       // <-- Replace with actual cloud name

class GroupInfoScreen extends StatefulWidget {
  final String conversationId;

  GroupInfoScreen({required this.conversationId});

  @override
  _GroupInfoScreenState createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  String groupName = '';
  String groupProfile = '';
  List<String> participants = [];
  final nameController = TextEditingController();
  Map<String, Map<String, String>> userCache = {}; // uid => {username, profileImage}

  @override
  void initState() {
    super.initState();
    loadGroupInfo();
  }

  Future<void> loadGroupInfo() async {
    final doc = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      participants = List<String>.from(data['participants'] ?? []);
      groupName = data['conversationName'] ?? '';
      groupProfile = data['conversationProfile'] ?? '';
      nameController.text = groupName;

      // Load user info
      for (final uid in participants) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          userCache[uid] = {
            'username': userDoc['username'] ?? 'Unknown',
            'profileImage': userDoc['profileImage'] ?? '',
          };
        }
      }

      setState(() {});
    }
  }

  Future<void> updateGroupName() async {
    final newName = nameController.text.trim();
    if (newName.isNotEmpty && newName != groupName) {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({'conversationName': newName});
      setState(() {
        groupName = newName;
      });
    }
  }

  Future<String?> uploadImageToCloudinary(XFile file) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return data['secure_url'];
    } else {
      print('Upload failed: $responseBody');
      return null;
    }
  }

  Future<void> updateProfileImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final url = await uploadImageToCloudinary(file);
      if (url != null) {
        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(widget.conversationId)
            .update({'conversationProfile': url});
        setState(() {
          groupProfile = url;
        });
      }
    }
  }

  Future<void> removeMember(String uid) async {
    participants.remove(uid);
    userCache.remove(uid);
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .update({'participants': participants});
    setState(() {});
  }

  void showAddMemberDialog() {
    String newUid = '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Member'),
        content: TextField(
          decoration: InputDecoration(hintText: 'Enter user ID'),
          onChanged: (val) => newUid = val,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (newUid.trim().isNotEmpty && !participants.contains(newUid)) {
                participants.add(newUid.trim());

                final userDoc = await FirebaseFirestore.instance.collection('users').doc(newUid).get();
                if (userDoc.exists) {
                  userCache[newUid] = {
                    'username': userDoc['username'] ?? 'Unknown',
                    'profileImage': userDoc['profileImage'] ?? '',
                  };
                }

                await FirebaseFirestore.instance
                    .collection('conversations')
                    .doc(widget.conversationId)
                    .update({'participants': participants});

                setState(() {});
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Info'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(icon: Icon(Icons.person_add), onPressed: showAddMemberDialog),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          GestureDetector(
            onTap: updateProfileImage,
            child: CircleAvatar(
              radius: 50,
              backgroundImage:
              groupProfile.isNotEmpty ? NetworkImage(groupProfile) : null,
              child: groupProfile.isEmpty ? Icon(Icons.group, size: 40) : null,
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                child: TextField(
                  controller: nameController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(border: InputBorder.none),
                  style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(icon: Icon(Icons.edit), onPressed: updateGroupName),
            ],
          ),
          SizedBox(height: 20),
          Text('Members (${participants.length})',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(
            child: ListView.builder(
              itemCount: participants.length,
              itemBuilder: (_, i) {
                final uid = participants[i];
                final user = userCache[uid] ??
                    {'username': 'Loading...', 'profileImage': ''};
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['profileImage']!.isNotEmpty
                        ? NetworkImage(user['profileImage']!)
                        : null,
                    child: user['profileImage']!.isEmpty
                        ? Icon(Icons.person)
                        : null,
                  ),
                  title: Text(user['username']!),
                  trailing: IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => removeMember(uid),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
