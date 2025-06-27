import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  final String userId;

  const NotificationScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No notifications"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String type = data['type'] ?? '';
              final String message = data['message'] ?? '';
              final String senderId = data['senderId'] ?? '';
              final String? postId = data['postId'];
              final String? groupId = data['groupId'];
              final Timestamp? ts = data['timestamp'];
              final bool seen = data['seen'] ?? false;

              final DateTime time = ts?.toDate() ?? DateTime.now();

              return ListTile(
                leading: Icon(_getIconForType(type)),
                title: Text(message),
                subtitle: Text(_formatTimestamp(time)),
                tileColor: seen ? null : Colors.blue.withOpacity(0.08),
                onTap: () {
                  _markAsSeen(userId, doc.id);
                  _handleTap(context, type, senderId, postId, groupId);
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'friend_request': return Icons.person_add;
      case 'group_invite': return Icons.group_add;
      case 'post_reaction': return Icons.thumb_up;
      case 'post_comment': return Icons.comment;
      default: return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  void _markAsSeen(String userId, String notifId) {
    if (notifId.isEmpty || userId.isEmpty) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notifId)
        .update({'seen': true});
  }

  void _handleTap(BuildContext context, String type, String senderId, String? postId, String? groupId) {
    switch (type) {
      case 'friend_request':
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navigate to $senderId\'s profile')));
        break;
      case 'group_invite':
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open group $groupId')));
        break;
      case 'post_reaction':
      case 'post_comment':
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open post $postId')));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unknown notification')));
    }
  }
}
