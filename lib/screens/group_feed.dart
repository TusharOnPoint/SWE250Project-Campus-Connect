import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';

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
    final post = doc.data() as Map<String, dynamic>? ?? {};
    final createdBy = post['createdBy'];
    final postId = post['id'] ?? doc.id;
    if (createdBy == null) return SizedBox();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(createdBy).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return ListTile(title: Text('Loading...'));

        final user = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final username = user['username'] ?? 'User';
        final profileUrl = user['profileImage'] ?? '';
        final timestamp = post['createdAt'] != null
            ? (post['createdAt'] as Timestamp).toDate()
            : DateTime.now();
        final likes = post['likes'] ?? [];
        final isLiked = likes.contains(currentUser.uid);
        final commentsCount = post['commentsCount'] ?? 0;

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.all(12),
                leading: CircleAvatar(
                  backgroundImage:
                  profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                  child: profileUrl.isEmpty ? Icon(Icons.person) : null,
                ),
                title: Text(username),
                subtitle: Text(timeago.format(timestamp)),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') await editPost(postId, post['text'] ?? '');
                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Delete Post?'),
                          content: Text('Confirm delete this post?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Delete')),
                          ],
                        ),
                      ) ??
                          false;
                      if (confirm) await deletePost(postId);
                    }
                  },
                  itemBuilder: (_) => [
                    if (createdBy == currentUser.uid)
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (createdBy == currentUser.uid)
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
              if ((post['text'] ?? '').isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(post['text']),
                ),
              if ((post['imageUrl'] ?? '').isNotEmpty || (post['videoUrl'] ?? '').isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: post['imageUrl'].isNotEmpty
                      ? Image.network(post['imageUrl'])
                      : _VideoPlayerWidget(url: post['videoUrl']),
                ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : null,
                      ),
                      onPressed: () => toggleLike(postId, likes),
                    ),
                    Text('${likes.length}'),
                    SizedBox(width: 16),
                    InkWell(
                      onTap: () => openCommentsScreen(postId),
                      child: Row(
                        children: [
                          Icon(Icons.comment_outlined),
                          SizedBox(width: 4),
                          Text('$commentsCount'),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InviteFriendsScreen(groupId: widget.groupId),
                ),
              );
            },
          ),
          if (widget.visibility == 'private')
            TextButton(
              onPressed: requestToJoinGroup,
              child: Text('Request to Join', style: TextStyle(color: Colors.white)),
            )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: postController,
                        decoration: InputDecoration(
                          labelText: 'Write a post...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isLoading ? null : createPost,
                      child: Text('Post'),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: pickMedia,
                      icon: Icon(Icons.image),
                      label: Text('Attach Image/Video'),
                    ),
                    if (selectedFile != null)
                      Text('File Selected', style: TextStyle(color: Colors.green)),
                  ],
                ),
                if (isLoading) Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: posts.length + (hasMorePosts ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == posts.length) {
                  return isLoadingMore
                      ? Center(child: CircularProgressIndicator())
                      : SizedBox.shrink();
                }
                return buildPostTile(posts[index]);
              },
            ),
          ),
        ],
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