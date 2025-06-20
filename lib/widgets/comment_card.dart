import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommentCard extends StatefulWidget {
  final DocumentSnapshot commentDoc;
  final String currentUserId;
  final String postAuthorId;

  const CommentCard({
    super.key,
    required this.commentDoc,
    required this.currentUserId,
    required this.postAuthorId,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  late Map<String, dynamic> commentData;
  late String authorId;
  late bool isCommentAuthor;
  late bool isPostAuthor;
  String authorName = 'User';
  String? profilePicUrl;

  @override
  void initState() {
    super.initState();
    commentData = widget.commentDoc.data() as Map<String, dynamic>;
    authorId = commentData['userId'] ?? '';
    isCommentAuthor = widget.currentUserId == authorId;
    isPostAuthor = widget.currentUserId == widget.postAuthorId;
    _loadAuthorData();
  }

  Future<void> _loadAuthorData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(authorId).get();
    if (doc.exists) {
      final userData = doc.data()!;
      setState(() {
        authorName = userData['username'] ?? 'User';
        profilePicUrl = userData['profileImage'];
      });
    }
  }

  Future<void> _deleteComment() async {
    await widget.commentDoc.reference.delete();
  }

  Future<void> _editComment() async {
    final TextEditingController controller =
        TextEditingController(text: commentData['text']);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Update your comment'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await widget.commentDoc.reference.update({'text': result});
    }
  }

  @override
  Widget build(BuildContext context) {
    final String text = commentData['text'] ?? '';
    final Timestamp? timestamp = commentData['timestamp'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Profile Image
          CircleAvatar(
            radius: 20,
            backgroundImage: profilePicUrl != null ? NetworkImage(profilePicUrl!) : null,
            child: profilePicUrl == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 10),

          /// Comment Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Author name and options menu
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (isCommentAuthor || isPostAuthor)
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') _editComment();
                                  if (value == 'delete') _deleteComment();
                                },
                                itemBuilder: (context) {
                                  final items = <PopupMenuEntry<String>>[];
                                  if (isCommentAuthor) {
                                    items.add(const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ));
                                  }
                                  items.add(const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ));
                                  return items;
                                },
                                icon: const Icon(Icons.more_vert, size: 18),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        /// Comment text
                        Text(
                          text,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                /// Timestamp (outside card, slightly below)
                if (timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat.yMMMd().add_jm().format(timestamp.toDate()),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
