import 'package:campus_connect/screens/user_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class FriendListScreen extends StatefulWidget {
  @override
  _FriendListScreenState createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        centerTitle: true,
      ),
      body: currentUser == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final friendIds = List<String>.from(userData?['friends'] ?? []);

          if (friendIds.isEmpty) {
            return const Center(child: Text('No friends yet.'));
          }

          return FutureBuilder<List<DocumentSnapshot>>(
            future: _fetchFriends(friendIds),
            builder: (context, friendsSnapshot) {
              if (!friendsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final friends = friendsSnapshot.data!;

              return ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  final friendId = friend.id;
                  final data = friend.data() as Map<String, dynamic>?;

                  return InkWell(
                    child: ListTile(
                      onTap: () {
                      if (data!=null)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UserProfileScreen(user: data),
                        ),
                      );
                    },
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          data?['profileImage'] ??
                              'https://res.cloudinary.com/ddfycczdx/image/upload/v1750106503/xqyhfxyryfeykfxozxcr.jpg',
                        ),
                      ),
                      title: Text(data?['username'] ?? 'No username'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'unfriend') {
                            _unfriend(friendId, data?['username'] ?? '');
                          } else if (value == 'chat') {
                            try {
                              final conversationId =
                              await _getOrCreateConversation(
                                  currentUser!.uid, friendId);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                      conversationId: conversationId),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                    Text('Failed to chat: $e')),
                              );
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'chat',
                            child: Text('Chat'),
                          ),
                          PopupMenuItem(
                            value: 'unfriend',
                            child: Text('Unfriend'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<DocumentSnapshot>> _fetchFriends(List<String> friendIds) async {
    if (friendIds.isEmpty) return [];
    final futures = friendIds
        .map((id) => FirebaseFirestore.instance.collection('users').doc(id).get());
    return await Future.wait(futures);
  }

  Future<void> _unfriend(String friendId, String friendName) async {
    final currentId = currentUser?.uid;
    if (currentId == null) return;

    final myRef = FirebaseFirestore.instance.collection('users').doc(currentId);
    final friendRef = FirebaseFirestore.instance.collection('users').doc(friendId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(myRef, {
          'friends': FieldValue.arrayRemove([friendId])
        });
        transaction.update(friendRef, {
          'friends': FieldValue.arrayRemove([currentId])
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unfriended $friendName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unfriend: $e')),
      );
    }
  }

  Future<String> _getOrCreateConversation(String userId1, String userId2) async {
    final conversationsRef = FirebaseFirestore.instance.collection('conversations');

    // Check for existing private conversation
    final snapshot = await conversationsRef
        .where('participants', arrayContains: userId1)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);
      final type = data['type'] ?? 'private';

      if (participants.contains(userId2) &&
          participants.length == 2 &&
          type == 'private') {
        return doc.id;
      }
    }

    // Fetch friend's data
    final friendDoc =
    await FirebaseFirestore.instance.collection('users').doc(userId2).get();
    final friendData = friendDoc.data() as Map<String, dynamic>?;

    // Create a new private conversation
    final newDoc = conversationsRef.doc();
    await newDoc.set({
      'conversationId': newDoc.id,
      'participants': [userId1, userId2],
      'type': 'private',
      'conversationName': friendData?['username'] ?? 'Chat',
      'conversationProfile': friendData?['profileImage'] ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageTime': null,
    });

    return newDoc.id;
  }
}
