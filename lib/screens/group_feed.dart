import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';

import '../widgets/postCard.dart';
import 'invite_friend_screen.dart';

const cloudinaryUploadPreset = 'your_upload_preset';
const cloudinaryCloudName = 'your_cloud_name';

class GroupFeedScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String visibility;

  const GroupFeedScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.visibility,
  }) : super(key: key);

  @override
  _GroupFeedScreenState createState() => _GroupFeedScreenState();
}

class _GroupFeedScreenState extends State<GroupFeedScreen> {
  final TextEditingController postController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser!;
  File? selectedFile;
  String? fileType;
  bool isLoading = false;

  static const int postsLimit = 10;
  DocumentSnapshot? lastPostDoc;
  bool isLoadingMore = false;
  bool hasMorePosts = true;
  List<DocumentSnapshot> posts = [];

  ScrollController scrollController = ScrollController();

  CollectionReference get postsRef => FirebaseFirestore.instance
      .collection('groups')
      .doc(widget.groupId)
      .collection('posts');

  @override
  void initState() {
    super.initState();
    fetchInitialPosts();
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore &&
          hasMorePosts) {
        fetchMorePosts();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    postController.dispose();
    super.dispose();
  }

  Future<void> pickMedia() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      final ext = result.path.split('.').last.toLowerCase();
      setState(() {
        selectedFile = File(result.path);
        fileType = ['mp4', 'mov', 'avi'].contains(ext) ? 'video' : 'image';
      });
    }
  }

  Future<String?> uploadToCloudinary(File file, String type) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/${type == 'image' ? 'image' : 'video'}/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final res = await request.send();
    if (res.statusCode == 200) {
      final responseData = await res.stream.bytesToString();
      return jsonDecode(responseData)['secure_url'];
    }
    return null;
  }

  Future<void> createPost() async {
    final text = postController.text.trim();
    if (text.isEmpty && selectedFile == null) return;
    setState(() => isLoading = true);

    String mediaUrl = '';
    if (selectedFile != null && fileType != null) {
      final uploadedUrl = await uploadToCloudinary(selectedFile!, fileType!);
      if (uploadedUrl == null) return;
      mediaUrl = uploadedUrl;
    }

    final postRef = postsRef.doc();
    await postRef.set({
      'id': postRef.id,
      'text': text,
      'imageUrl': fileType == 'image' ? mediaUrl : '',
      'videoUrl': fileType == 'video' ? mediaUrl : '',
      'createdBy': currentUser.uid,
      'createdAt': Timestamp.now(),
      'likes': [],
      'commentsCount': 0,
    });

    postController.clear();
    setState(() {
      selectedFile = null;
      fileType = null;
      isLoading = false;
      posts.clear();
      lastPostDoc = null;
      hasMorePosts = true;
    });
    await fetchInitialPosts();
  }

  Future<void> fetchInitialPosts() async {
    setState(() => isLoading = true);
    final snapshot = await postsRef
        .orderBy('createdAt', descending: true)
        .limit(postsLimit)
        .get();
    posts = snapshot.docs;
    hasMorePosts = posts.length == postsLimit;
    lastPostDoc = posts.isNotEmpty ? posts.last : null;
    setState(() => isLoading = false);
  }

  Future<void> fetchMorePosts() async {
    if (!hasMorePosts) return;
    setState(() => isLoadingMore = true);
    final snapshot = await postsRef
        .orderBy('createdAt', descending: true)
        .startAfterDocument(lastPostDoc!)
        .limit(postsLimit)
        .get();
    if (snapshot.docs.isNotEmpty) {
      posts.addAll(snapshot.docs);
      lastPostDoc = snapshot.docs.last;
      hasMorePosts = snapshot.docs.length == postsLimit;
    } else {
      hasMorePosts = false;
    }
    setState(() => isLoadingMore = false);
  }

  Future<void> toggleLike(String postId, List likes) async {
    final ref = postsRef.doc(postId);
    final uid = currentUser.uid;
    await ref.update({
      'likes': likes.contains(uid)
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid])
    });
  }

  Future<void> deletePost(String postId) async {
    await postsRef.doc(postId).delete();
    setState(() => posts.removeWhere((doc) => doc.id == postId));
  }

  Future<void> editPost(String postId, String oldText) async {
    final controller = TextEditingController(text: oldText);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Post'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(hintText: 'Edit your post'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
              onPressed: () async {
                final newText = controller.text.trim();
                if (newText.isNotEmpty) {
                  await postsRef.doc(postId).update({'text': newText});
                  Navigator.pop(context);
                  await fetchInitialPosts();
                }
              },
              child: Text('Save')),
        ],
      ),
    );
  }

  void openCommentsScreen(String postId) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Open comments for post $postId')));
  }

  Widget buildPostTile(DocumentSnapshot doc) {
    return PostCard(
      postDoc: doc,
      currentUserId: currentUser.uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          if (widget.visibility == 'private')
            TextButton(
              onPressed: requestToJoinGroup,
              child: Text('Request to Join', style: TextStyle(color: Colors.white)),
            )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final groupData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final coverUrl = groupData['coverImageUrl'] ?? '';
          final participants = List<String>.from(groupData['participants'] ?? []);
          final nameController = TextEditingController(text: (groupData['groupName'] ?? widget.groupName) ?? '');

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    coverUrl.isNotEmpty
                        ? Image.network(
                      coverUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(child: Text('No Cover Image')),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: ElevatedButton.icon(
                        onPressed: () {

                           _updateCoverImage();
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Cover'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextFormField(
                    controller: nameController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                    onFieldSubmitted: (newName) {
                      FirebaseFirestore.instance
                          .collection('groups')
                          .doc(widget.groupId)
                          .update({'groupName': newName});
                    },
                  ),
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${participants.length} Members',
                          style: const TextStyle(fontSize: 16)),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InviteFriendsScreen(groupId: widget.groupId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Member'),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 30),

                // Post Composer UI (scrollable with ListView inside a fixed height box)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // Add your post composer UI here
                    ],
                  ),
                ),

                SizedBox(
                  height: 400, // or MediaQuery height-based value
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: posts.length + (hasMorePosts ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == posts.length) {
                        return isLoadingMore
                            ? const Center(child: CircularProgressIndicator())
                            : const SizedBox.shrink();
                      }
                      return buildPostTile(posts[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),


    );
  }

  Future<void> requestToJoinGroup() async {
    if (widget.visibility != 'private') {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('This group is public, you can join directly')));
      return;
    }
    final groupRef = FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
    final doc = await groupRef.get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final pendingRequests = List<String>.from(data['pendingRequests'] ?? []);
    if (pendingRequests.contains(currentUser.uid)) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Join request already sent')));
      return;
    }
    await groupRef.update({
      'pendingRequests': FieldValue.arrayUnion([currentUser.uid])
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Join request sent')));
  }
  Future<void> _updateCoverImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final file = File(image.path);
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final resData = jsonDecode(await response.stream.bytesToString());
      final imageUrl = resData['secure_url'];
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({'coverImageUrl': imageUrl});
      setState(() {}); // Refresh UI
    }
  }

}

class _VideoPlayerWidget extends StatefulWidget {
  final String url;
  const _VideoPlayerWidget({Key? key, required this.url}) : super(key: key);

  @override
  __VideoPlayerWidgetState createState() => __VideoPlayerWidgetState();
}

class __VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() => _initialized = true);
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return !_initialized
        ? Container(
      height: 200,
      color: Colors.black12,
      child: Center(child: CircularProgressIndicator()),
    )
        : AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}

