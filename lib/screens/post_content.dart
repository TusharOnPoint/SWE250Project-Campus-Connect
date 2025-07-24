import 'package:universal_io/io.dart' show File;        // cross-platform File
import 'package:universal_html/html.dart' as html;      // cross-platform html.*
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/coudinary_services.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();

  FilePickerResult? _selectedFile;
  String? _fileType;

  VideoPlayerController? _videoController;
  Future<void>? _videoInit;
  String? _webBlobUrl;
  bool _isLoading = false;

  /* ─────────────────── pick image / video ─────────────────── */

  Future<void> _pickMedia() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov'],
    );

    if (result == null || result.files.single.path == null) return;

    final ext = result.files.single.extension!.toLowerCase();
    _disposeVideo();

    setState(() {
      _selectedFile = result;
      _fileType = ['mp4', 'mov'].contains(ext) ? 'video' : 'image';
    });

    if (_fileType == 'video') {
      await _setupVideo(result.files.single);
      setState(() {}); // redraw once video is ready
    }
  }

  /* ────────────────── setup video controller ─────────────────── */

  Future<void> _setupVideo(PlatformFile file) async {
    _disposeVideo();

    if (kIsWeb) {
      // Turn the bytes into an object-URL for the <video> element.
      final Uint8List bytes = file.bytes!;
      final blob = html.Blob(<Uint8List>[bytes]);
      _webBlobUrl = html.Url.createObjectUrlFromBlob(blob);
      _videoController = VideoPlayerController.network(_webBlobUrl!);
    } else {
      _videoController = VideoPlayerController.file(File(file.path!));
    }

    _videoController!.setLooping(true);
    _videoInit = _videoController!.initialize().then((_) {
      setState(() {});
      _videoController!.play();
    });
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    _videoInit = null;
    if (_webBlobUrl != null) {
      html.Url.revokeObjectUrl(_webBlobUrl!);
      _webBlobUrl = null;
    }
  }

  /* ─────────────────── create Firestore post ─────────────────── */

  Future<void> _createPost() async {
    if (_textController.text.trim().isEmpty && _selectedFile == null) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    String mediaUrl = '';
    if (_selectedFile != null && _fileType != null) {
      final uploadedUrl =
          await uploadToCloudinary(_selectedFile!, _fileType!);
      if (uploadedUrl != null) mediaUrl = uploadedUrl;
    }

    await FirebaseFirestore.instance.collection('posts').add({
      'authorId': user.uid,
      'authorName': userData['username'] ?? 'Anonymous',
      'authorImageUrl': userData['profileImage'] ?? '',
      'text': _textController.text.trim(),
      'mediaUrl': mediaUrl,
      'mediaType': _fileType ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [],
    });

    // Reset UI
    _textController.clear();
    _disposeVideo();
    setState(() {
      _selectedFile = null;
      _fileType = null;
      _isLoading = false;
    });

    if (context.mounted) Navigator.pop(context);
  }

  /* ─────────────────── media preview widget ─────────────────── */

  Widget _buildMediaPreview() {
    if (_selectedFile == null) return const SizedBox.shrink();

    if (_fileType == 'image') {
      if (kIsWeb) {
        final bytes = _selectedFile!.files.single.bytes;
        if (bytes == null) return const Text('Could not load image');
        return Image.memory(bytes, fit: BoxFit.cover);
      } else {
        final path = _selectedFile!.files.single.path!;
        return Image.file(File(path), fit: BoxFit.cover);
      }
    }

    if (_fileType == 'video' && _videoController != null) {
      return FutureBuilder(
        future: _videoInit,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_videoController!),
                  VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                  ),
                ],
              ),
            );
          }
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  /* ─────────────────── lifecycle ─────────────────── */

  @override
  void dispose() {
    _textController.dispose();
    _disposeVideo();
    super.dispose();
  }

  /* ─────────────────── build ─────────────────── */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isLoading ? null : _createPost,
          ),
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
                      onPressed: () {
                        _disposeVideo();
                        setState(() {
                          _selectedFile = null;
                          _fileType = null;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isLoading) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
