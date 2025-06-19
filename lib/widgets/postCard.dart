import 'package:campus_connect/services/user_sevice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

class PostCard extends StatefulWidget {
  final DocumentSnapshot postDoc;
  final String currentUserId;

  const PostCard({
    super.key,
    required this.postDoc,
    required this.currentUserId,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late Map<String, dynamic> postData;
  bool isLiked = false;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    postData = widget.postDoc.data()! as Map<String, dynamic>;
    isLiked = (postData['likes'] as List).contains(widget.currentUserId);

    if (postData['mediaType'] == 'video' && (postData['mediaUrl'] ?? '').isNotEmpty) {
      _videoController = VideoPlayerController.network(postData['mediaUrl'])
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _toggleLike() async {
    final postRef = widget.postDoc.reference;
    final wasLiked = isLiked;
    final likesList = List<String>.from(postData['likes']);

    setState(() {
      isLiked = !wasLiked;
      if (!wasLiked) {
        postData['likes'].add(widget.currentUserId);
      } else {
        postData['likes'].remove(widget.currentUserId);
      }
    });

    try {
      await postRef.update({
        'likes': !wasLiked
            ? FieldValue.arrayUnion([widget.currentUserId])
            : FieldValue.arrayRemove([widget.currentUserId])
      });
    } catch (e) {
      setState(() {
        isLiked = wasLiked;
        postData['likes'] = likesList;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update like. Please try again.')),
      );
    }
  }

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : const AssetImage('assets/images/profile_placeholder.jpg') as ImageProvider,
                ),
                title: Text(authorName),
                subtitle: timestamp != null
                    ? Text(DateFormat.yMMMd().add_jm().format(timestamp))
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ),

              // Media
              if ((postData['mediaUrl'] ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: postData['mediaType'] == 'video'
                        ? (_videoController != null && _videoController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    VideoPlayer(_videoController!),
                                    VideoProgressIndicator(_videoController!, allowScrubbing: true),
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
                                    )
                                  ],
                                ),
                              )
                            : const SizedBox(
                                height: 200,
                                child: Center(child: CircularProgressIndicator()),
                              ))
                        : Image.network(postData['mediaUrl']),
                  ),
                ),

              // Text
              if ((postData['text'] ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(postData['text']),
                ),

              // Like & Comment Buttons
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
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/postDetail',
                          arguments: {
                            'postDoc': widget.postDoc,
                            'currentUserId': widget.currentUserId,
                          },
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.comment_outlined),
                          const SizedBox(width: 4),
                          StreamBuilder<QuerySnapshot>(
                            stream: widget.postDoc.reference.collection('comments').snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Text('...');
                              return Text('${snapshot.data!.docs.length}');
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
