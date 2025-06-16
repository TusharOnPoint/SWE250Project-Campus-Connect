import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import '../services/coudinary_services.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  FilePickerResult? _selectedFile;
  String? _fileType; // "image" or "video"
  bool _isLoading = false;

  Future<void> _pickMedia() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg', 'mp4', 'mov'],
    );

    if (result != null && result.files.single.path != null) {
      final ext = result.files.single.extension!;
      setState(() {
        _selectedFile = result;
        _fileType = ['mp4', 'mov'].contains(ext.toLowerCase()) ? 'video' : 'image';
      });
    }
  }

  Future<void> _createPost() async {
    if (_textController.text.trim().isEmpty && _selectedFile == null) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    String mediaUrl = '';
    if (_selectedFile != null && _fileType != null) {
      final uploadedUrl = await uploadToCloudinary(_selectedFile!, _fileType!);
      if (uploadedUrl != null) {
        mediaUrl = uploadedUrl;

      }
    }

    await FirebaseFirestore.instance.collection('posts').add({
      'authorId': user.uid,
      'authorName': userData['username'] ?? 'Anonymous',
      'authorImageUrl': userData['profileImage'] ?? '',
      'text': _textController.text.trim(),
      'mediaUrl': mediaUrl,
      'mediaType': _fileType ?? '', // "image" or "video"
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [],
    });

    _textController.clear();
    setState(() {
      _selectedFile = null;
      _fileType = null;
      _isLoading = false;
    });

    Navigator.pop(context);
  }

  Widget _buildMediaPreview() {
    if (_selectedFile == null) return const SizedBox();

    if (_fileType == 'image') {
      print(_selectedFile?.files.single.path);
      return Image.network(_selectedFile!.files.single.path!);
    } else if (_fileType == 'video') {
      return const Text("📹 Video selected");
    }
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isLoading ? null : _createPost,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _textController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'What’s on your mind?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              _buildMediaPreview(),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Add Image/Video'),
                    onPressed: _pickMedia,
                  ),
                  const Spacer(),
                  if (_selectedFile != null)
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => setState(() {
                        _selectedFile = null;
                        _fileType = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isLoading) const CircularProgressIndicator(),
            ],
          ),
        )
      ),
    );
  }
}
