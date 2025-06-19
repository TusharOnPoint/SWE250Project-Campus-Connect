import 'package:campus_connect/widgets/postCard.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.postDoc,
    required this.currentUserId,
  });
  final DocumentSnapshot postDoc;
  final String currentUserId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  // late DocumentSnapshot postDoc;
  // late String currentUserId;
  final TextEditingController _commentController = TextEditingController();

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    await widget.postDoc.reference.collection('comments').add({
      'text': text,
      'userId': widget.currentUserId,
      'timestamp': Timestamp.now(),
    });

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                PostCard(
                  postDoc: widget.postDoc,
                  currentUserId: widget.currentUserId,
                ),
                const Divider(),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      widget.postDoc.reference
                          .collection('comments')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final comments = snapshot.data!.docs;
                    return Column(
                      children:
                          comments.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text(data['text'] ?? ''),
                              subtitle:
                                  data['timestamp'] != null
                                      ? Text(
                                        DateFormat.yMMMd().add_jm().format(
                                          (data['timestamp'] as Timestamp)
                                              .toDate(),
                                        ),
                                      )
                                      : null,
                            );
                          }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: TextField(
              controller: _commentController,
              onSubmitted: (_) => _postComment(),
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _postComment,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
