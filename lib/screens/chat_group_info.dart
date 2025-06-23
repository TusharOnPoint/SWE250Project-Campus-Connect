import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'add_Gchat_member.dart'; // Import the screen you're navigating to

const cloudinaryUploadPreset = 'YOUR_UPLOAD_PRESET'; // Replace with actual preset
const cloudinaryCloudName = 'YOUR_CLOUD_NAME';       // Replace with actual cloud name

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
  Map<String, Map<String, String>> userCache = {};
  bool isEditingName = false;

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

      userCache.clear();
      for (final uid in participants) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          userCache[uid] = {
            'username': userDoc.data()?['username'] ?? 'Unknown',
            'profileImage': userDoc.data()?['profileImage'] ?? '',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group name updated successfully')),
      );
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

  Future<void> navigateToAddMemberScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMemberScreen(
          conversationId: widget.conversationId,
          existingParticipants: participants,
        ),
      ),
    );

    if (result == true) {
      // If members were added, refresh UI and show snackbar
      await loadGroupInfo();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member(s) added successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Info'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(icon: Icon(Icons.person_add), onPressed: navigateToAddMemberScreen),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          GestureDetector(
            onTap: updateProfileImage,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: groupProfile.isNotEmpty ? NetworkImage(groupProfile) : null,
              child: groupProfile.isEmpty ? Icon(Icons.group, size: 40) : null,
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                child: TextField(
                  controller: nameController,
                  readOnly: !isEditingName,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: isEditingName ? UnderlineInputBorder() : InputBorder.none,
                  ),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(isEditingName ? Icons.check : Icons.edit),
                onPressed: () {
                  if (isEditingName) {
                    updateGroupName();
                  }
                  setState(() {
                    isEditingName = !isEditingName;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Members (${participants.length})',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: participants.length,
              itemBuilder: (_, i) {
                final uid = participants[i];
                final user = userCache[uid] ?? {
                  'username': 'Loading...',
                  'profileImage': '',
                };
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['profileImage']!.isNotEmpty
                        ? NetworkImage(user['profileImage']!)
                        : null,
                    child: user['profileImage']!.isEmpty ? Icon(Icons.person) : null,
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
