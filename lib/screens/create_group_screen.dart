import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/group_model.dart';

class CreateGroupScreen extends StatefulWidget {
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String visibility = 'public';
  File? coverImage;
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        coverImage = File(picked.path);
      });
      // Upload image to your cloud storage and retrieve the URL
    }
  }

  Future<void> createGroup() async {
    final doc = FirebaseFirestore.instance.collection('groups').doc();
    final group = GroupModel(
      id: doc.id,
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      coverImageUrl: '', // TODO: Replace with uploaded image URL
      createdBy: currentUser!.uid,
      createdAt: DateTime.now(),
      visibility: visibility,
      members: [currentUser!.uid],
      pendingRequests: [],
      roles: {currentUser!.uid: 'admin'},
    );

    await doc.set(group.toMap());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Group')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Group Name'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: visibility,
              items: ['public', 'private']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (val) => setState(() => visibility = val!),
              decoration: InputDecoration(labelText: 'Visibility'),
            ),
            SizedBox(height: 12),
            coverImage != null
                ? Image.file(coverImage!, height: 150, fit: BoxFit.cover)
                : Container(height: 150, color: Colors.grey[300]),
            TextButton.icon(
              icon: Icon(Icons.image),
              label: Text('Choose Cover Image'),
              onPressed: pickImage,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: createGroup,
              child: Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }
}