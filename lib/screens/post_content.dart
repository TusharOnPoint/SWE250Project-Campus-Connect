import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostContentScreen extends StatefulWidget {
  @override
  _PostContentScreenState createState() => _PostContentScreenState();
}

class _PostContentScreenState extends State<PostContentScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _textController = TextEditingController();
  dynamic _mediaFile; // File for mobile, Uint8List for web
  String? _mediaType;
  bool isLoading = false;

  Future<void> _pickMedia() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.media);
      if (result != null) {
        setState(() {
          _mediaType = result.files.single.extension == 'mp4' ? 'video' : 'image';

          if (kIsWeb) {
            _mediaFile = result.files.single.bytes; // Use Uint8List for web
          } else {
            _mediaFile = File(result.files.single.path!); // Use File for mobile
          }
        });
      }
    } catch (e) {
      print("Error picking media: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking media')));
    }
  }

  Future<void> _uploadPost() async {
    if (_textController.text.isEmpty && _mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please add content or media')));
      return;
    }

    setState(() => isLoading = true);

    User? user = _auth.currentUser;
    String? mediaMetadata;

    try {
      if (_mediaFile != null) {
        mediaMetadata = "path/to/media/${user!.uid}/${DateTime.now().millisecondsSinceEpoch}.${_mediaType == 'video' ? 'mp4' : 'jpg'}";
      }

      await _firestore.collection('posts').add({
        'userId': user?.uid,
        'text': _textController.text,
        'mediaMetadata': mediaMetadata,
        'mediaType': _mediaType,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        isLoading = false;
        _textController.clear();
        _mediaFile = null;
        _mediaType = null;
      });
      Navigator.pop(context);
    } catch (e) {
      setState(() => isLoading = false);
      print("Error uploading post: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading post')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Post")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(labelText: "Write something..."),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickMedia,
              icon: Icon(Icons.attach_file),
              label: Text("Pick File"),
            ),
            if (_mediaFile != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _mediaType == 'image'
                    ? kIsWeb
                    ? Image.memory(_mediaFile, height: 200) // Use Image.memory for web
                    : Image.file(_mediaFile, height: 200) // Use Image.file for mobile
                    : Icon(Icons.video_file, size: 100),
              ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _uploadPost,
              child: Text("Post"),
            ),
          ],
        ),
      ),
    );
  }
}