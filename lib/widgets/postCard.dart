import 'package:campus_connect/screens/user_profile_page.dart';
import 'package:campus_connect/services/user_sevice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

class PostCard extends StatefulWidget {
  final DocumentSnapshot postDoc;
  final String currentUserId;
  final isNavigate;
  bool navigateToUserProfile;

  PostCard({
    super.key,
    required this.postDoc,
    required this.currentUserId,
    this.isNavigate = true, this.navigateToUserProfile=true,
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

      // Send notification only if it was a like (not unlike)
      if (!wasLiked && widget.currentUserId != postData['authorId']) {
        final currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId)
            .get();
        final username = currentUserDoc.data()?['username'] ?? 'Someone';

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
        final authorId = author?['uid'] ?? 'Unknown';
        //print(authorId);
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
                title: InkWell(
                  child: Text(authorName),
                  onTap: () {
                    if(author!=null&&widget.navigateToUserProfile){
                      Navigator.push(context, MaterialPageRoute(
                      builder: (context) => UserProfileScreen(user: author,),));
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
                    SizedBox(width: 20,),
                    GestureDetector(
                      onTap: widget.isNavigate ?  () {
                        Navigator.pushNamed(
                          context,
                          '/postDetail',
                          arguments: {
                            'postDoc': widget.postDoc,
                            'currentUserId': widget.currentUserId,
                          },
                        );
                      } : () {},
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
