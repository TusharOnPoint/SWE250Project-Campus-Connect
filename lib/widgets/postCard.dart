import 'package:campus_connect/screens/user_profile_page.dart';
import 'package:campus_connect/services/user_sevice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

class PostCard extends StatefulWidget {
  final DocumentSnapshot postDoc;
  final String currentUserId;
  final bool isNavigate;
  final bool navigateToUserProfile;

  const PostCard({
    super.key,
    required this.postDoc,
    required this.currentUserId,
    this.isNavigate = true,
    this.navigateToUserProfile = true,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late Map<String, dynamic> postData;
  bool isLiked = false;
  VideoPlayerController? _videoController;

  // text expand / collapse
  bool _isTextExpanded = false;
  static const _previewMaxLines = 3;
  static const _previewCutoff = 150; // characters

  @override
  void initState() {
    super.initState();
    postData = widget.postDoc.data()! as Map<String, dynamic>;
    isLiked = (postData['likes'] as List).contains(widget.currentUserId);

    if (postData['mediaType'] == 'video' &&
        (postData['mediaUrl'] ?? '').isNotEmpty) {
      _videoController = VideoPlayerController.network(postData['mediaUrl'])
        ..initialize().then((_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  // like / unlike

  Future<void> _toggleLike() async {
    final postRef = widget.postDoc.reference;
    final wasLiked = isLiked;
    final originalLikes = List<String>.from(postData['likes']);

    setState(() {
      isLiked = !wasLiked;
      wasLiked
          ? postData['likes'].remove(widget.currentUserId)
          : postData['likes'].add(widget.currentUserId);
    });

    try {
      await postRef.update({
        'likes': wasLiked
            ? FieldValue.arrayRemove([widget.currentUserId])
            : FieldValue.arrayUnion([widget.currentUserId]),
      });

      if (!wasLiked && widget.currentUserId != postData['authorId']) {
        final me = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId)
            .get();
        final username = me.data()?['username'] ?? 'Someone';

        await FirebaseFirestore.instance
            .collection('users')
            .doc(postData['authorId'])
            .collection('notifications')
            .add({
          'type': 'post_reaction',
          'senderId': widget.currentUserId,
          'postId': widget.postDoc.id,
          'message': '$username liked your post.',
          'timestamp': FieldValue.serverTimestamp(),
          'seen': false,
        });
      }
    } catch (e) {
      // roll back UI on failure
      setState(() {
        isLiked = wasLiked;
        postData['likes'] = originalLikes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update like. Please try again.')),
      );
    }
  }

  // expandable text widget

  Widget _buildPostText(String text) {
    final isLong = text.length > _previewCutoff;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          maxLines: _isTextExpanded ? null : _previewMaxLines,
          overflow:
              _isTextExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15),
        ),
        if (isLong)
          GestureDetector(
            onTap: () => setState(() => _isTextExpanded = !_isTextExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _isTextExpanded ? 'Show less' : 'Show more',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // build

  @override
  Widget build(BuildContext context) {
    final timestamp = (postData['timestamp'] as Timestamp?)?.toDate();
    final likeCount = (postData['likes'] as List).length;

    return FutureBuilder<Map<String, dynamic>?>(
      future: UserService.getUserDataByUid(postData['authorId']),
      builder: (context, snapshot) {
        final author = snapshot.data;
        final authorName = author?['username'] ?? 'Unknown';
        final profileImage = author?['profileImage'] ?? '';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : const AssetImage(
                              'assets/images/profile_placeholder.jpg')
                          as ImageProvider,
                ),
                title: InkWell(
                  child: Text(authorName),
                  onTap: () {
                    if (author != null && widget.navigateToUserProfile) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(user: author),
                        ),
                      );
                    }
                  },
                ),
                subtitle: timestamp != null
                    ? Text(DateFormat.yMMMd().add_jm().format(timestamp))
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ),

              // media
              if ((postData['mediaUrl'] ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: postData['mediaType'] == 'video'
                        ? (_videoController != null &&
                                _videoController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio:
                                    _videoController!.value.aspectRatio,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    VideoPlayer(_videoController!),
                                    VideoProgressIndicator(
                                      _videoController!,
                                      allowScrubbing: true,
                                    ),
                                    Positioned(
                                      bottom: 10,
                                      left: 10,
                                      child: IconButton(
                                        icon: Icon(
                                          _videoController!.value.isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _videoController!.value.isPlaying
                                                ? _videoController!.pause()
                                                : _videoController!.play();
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox(
                                height: 200,
                                child:
                                    Center(child: CircularProgressIndicator()),
                              ))
                        : Image.network(postData['mediaUrl']),
                  ),
                ),

              // text
              if ((postData['text'] ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _buildPostText(postData['text']),
                ),

              // like & comment row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey,
                          ),
                          onPressed: _toggleLike,
                        ),
                        Text('$likeCount'),
                      ],
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: widget.isNavigate
                          ? () {
                              Navigator.pushNamed(
                                context,
                                '/postDetail',
                                arguments: {
                                  'postDoc': widget.postDoc,
                                  'currentUserId': widget.currentUserId,
                                },
                              );
                            }
                          : null,
                      child: Row(
                        children: [
                          const Icon(Icons.comment_outlined),
                          const SizedBox(width: 4),
                          StreamBuilder<QuerySnapshot>(
                            stream: widget.postDoc.reference
                                .collection('comments')
                                .snapshots(),
                            builder: (context, snap) {
                              if (!snap.hasData) return const Text('...');
                              return Text('${snap.data!.docs.length}');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
