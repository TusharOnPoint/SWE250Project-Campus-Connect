import 'package:campus_connect/screens/user_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'friend_list.dart'; // Ensure this path is correct

class AddFriendScreen extends StatefulWidget {
  @override
  _AddFriendScreenState createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen>
    with TickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  String searchText = '';
  final currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friend'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt),
            tooltip: 'Your Friends',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FriendListScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: (value) => setState(() => searchText = value.trim()),
              decoration: const InputDecoration(
                labelText: 'Search by username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            if (searchText.isEmpty)
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Friend Requests'),
                  Tab(text: 'Sent Requests'),
                ],
              ),
            const SizedBox(height: 8),
            Expanded(
              child:
                  searchText.isNotEmpty
                      ? _buildUserSearchResults()
                      : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildFriendRequests(),
                          _buildSentFriendRequests(),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('username')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const Center(child: Text('No users found.'));

        // Client-side filtering (case-insensitive)
        final users = snapshot.data!.docs.where((doc) {
          final username = (doc['username'] ?? '') as String;
          return username.toLowerCase().contains(searchText.toLowerCase());
        }).toList();

        if (users.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .get(),
          builder: (context, currentUserSnapshot) {
            if (!currentUserSnapshot.hasData) return const SizedBox();

            final currentUserData =
            currentUserSnapshot.data!.data() as Map<String, dynamic>?;
            final sentList =
            List<String>.from(currentUserData?['friend_requests_sent'] ?? []);
            final friendList =
            List<String>.from(currentUserData?['friends'] ?? []);
            final receivedList =
            List<String>.from(currentUserData?['friend_requests'] ?? []);

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final userId = user.id;
                final userData = user.data() as Map<String, dynamic>;

                if (userId == currentUser!.uid) return const SizedBox.shrink();

                final isSent = sentList.contains(userId);
                final isFriend = friendList.contains(userId);
                final isReceived = receivedList.contains(userId);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: userData.containsKey('profileImage') &&
                        user['profileImage'] != null
                        ? NetworkImage(userData['profileImage'])
                        : const AssetImage('assets/images/user_placeholder.jpg')
                    as ImageProvider,
                  ),
                  title: InkWell(
                    child: Text(user['username'] ?? 'No username'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UserProfileScreen(user: userData),
                        ),
                      );
                    },
                  ),
                  trailing: isFriend
                      ? const ElevatedButton(
                    onPressed: null,
                    child: Text('Friends'),
                  )
                      : isReceived
                      ? _buildRespondButton(userId, user['username'])
                      : ElevatedButton(
                    onPressed: () => isSent
                        ? _cancelFriendRequest( 
                        userId, user['username'])
                        : _sendFriendRequest(
                        userId, user['username']),
                    child: Text(isSent ? 'Cancel' : 'Add'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }


  Widget _buildFriendRequests() {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final requestIds = List<String>.from(data?['friend_requests'] ?? []);

        if (requestIds.isEmpty)
          return const Center(child: Text('No friend requests.'));

        return ListView.builder(
          itemCount: requestIds.length,
          itemBuilder: (context, index) {
            final senderId = requestIds[index];

            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(senderId)
                      .get(),
              builder: (context, senderSnapshot) {
                if (!senderSnapshot.hasData)
                  return const ListTile(title: Text('Loading...'));

                final senderData =
                    senderSnapshot.data!.data() as Map<String, dynamic>;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      senderData?['profileImage'] ??
                          'https://res.cloudinary.com/ddfycczdx/image/upload/v1750106503/xqyhfxyryfeykfxozxcr.jpg',
                    ),
                  ),
                  title: InkWell(
                    child: Text(senderData?['username'] ?? 'No name'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => UserProfileScreen(user: senderData),
                        ),
                      );
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed:
                            () => _acceptFriendRequest(
                              senderId,
                              senderData?['username'] ?? '',
                            ),
                        child: const Text('Accept'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed:
                            () => _cancelReceivedRequest(
                              senderId,
                              senderData?['username'] ?? '',
                            ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSentFriendRequests() {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final sentIds = List<String>.from(data?['friend_requests_sent'] ?? []);

        if (sentIds.isEmpty)
          return const Center(child: Text('No sent requests.'));

        return ListView.builder(
          itemCount: sentIds.length,
          itemBuilder: (context, index) {
            final receiverId = sentIds[index];

            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(receiverId)
                      .get(),
              builder: (context, receiverSnapshot) {
                if (!receiverSnapshot.hasData)
                  return const ListTile(title: Text('Loading...'));

                final receiverData =
                    receiverSnapshot.data!.data() as Map<String, dynamic>;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      receiverData?['profileImage'] ??
                          'https://res.cloudinary.com/ddfycczdx/image/upload/v1750106503/xqyhfxyryfeykfxozxcr.jpg',
                    ),
                  ),
                  title: InkWell(
                    child: Text(receiverData?['username'] ?? 'No name'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  UserProfileScreen(user: receiverData),
                        ),
                      );
                    },
                  ),
                  trailing: OutlinedButton(
                    onPressed:
                        () => _cancelFriendRequest(
                          receiverId,
                          receiverData?['username'] ?? '',
                        ),
                    child: const Text('Cancel'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _sendFriendRequest(
      String receiverId,
      String receiverUsername,
      ) async {
    if (currentUser == null || receiverId == currentUser!.uid) return;

    final senderId = currentUser!.uid;
    final senderRef = FirebaseFirestore.instance.collection('users').doc(senderId);
    final receiverRef = FirebaseFirestore.instance.collection('users').doc(receiverId);

    try {
      await senderRef.update({
        'friend_requests_sent': FieldValue.arrayUnion([receiverId]),
      });
      await receiverRef.update({
        'friend_requests': FieldValue.arrayUnion([senderId]),
      });

      final senderSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();

      final senderUsername = senderSnapshot.data()?['username'] ?? 'Someone';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .add({
        'type': 'friend_request',
        'senderId': senderId,
        'message': '$senderUsername sent you a friend request!',
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
      });


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request sent to $receiverUsername')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending request: $e')),
      );
    }
  }


  Future<void> _cancelFriendRequest(
    String receiverId,
    String receiverUsername,
  ) async {
    if (currentUser == null) return;

    final senderId = currentUser!.uid;
    final senderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(senderId);
    final receiverRef = FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(senderRef, {
          'friend_requests_sent': FieldValue.arrayRemove([receiverId]),
        });
        transaction.update(receiverRef, {
          'friend_requests': FieldValue.arrayRemove([senderId]),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancelled request to $receiverUsername')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _cancelReceivedRequest(
    String senderId,
    String senderUsername,
  ) async {
    if (currentUser == null) return;

    final receiverId = currentUser!.uid;
    final receiverRef = FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId);
    final senderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(senderId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(receiverRef, {
          'friend_requests': FieldValue.arrayRemove([senderId]),
        });
        transaction.update(senderRef, {
          'friend_requests_sent': FieldValue.arrayRemove([receiverId]),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancelled request from $senderUsername')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _acceptFriendRequest(
      String senderId,
      String senderUsername,
      ) async {
    if (currentUser == null) return;

    final receiverId = currentUser!.uid;
    final receiverRef = FirebaseFirestore.instance.collection('users').doc(receiverId);
    final senderRef = FirebaseFirestore.instance.collection('users').doc(senderId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(receiverRef, {
          'friend_requests': FieldValue.arrayRemove([senderId]),
          'friends': FieldValue.arrayUnion([senderId]),
        });

        transaction.update(senderRef, {
          'friend_requests_sent': FieldValue.arrayRemove([receiverId]),
          'friends': FieldValue.arrayUnion([receiverId]),
        });
      });

      final receiverSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .get();

      final receiverUsername = receiverSnapshot.data()?['username'] ?? 'Someone';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .collection('notifications')
          .add({
        'type': 'friend_acceptance',
        'senderId': receiverId,
        'message': '$receiverUsername accepted your friend request!',
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
      });


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You and $senderUsername are now friends!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  Widget _buildRespondButton(String userId, String username) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'accept') {
          _acceptFriendRequest(userId, username);
        } else if (value == 'delete') {
          _cancelReceivedRequest(userId, username);
        }
      },
      itemBuilder:
          (context) => [
            PopupMenuItem(value: 'accept', child: Text('Accept')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
      child: Builder(
        builder: (context) {
          final ButtonStyle defaultStyle = ElevatedButton.styleFrom();
          final Color foregroundColor =
              defaultStyle.backgroundColor?.resolve({}) ??
              Theme.of(context).colorScheme.primary;
          final Color backgroundColor =
              defaultStyle.foregroundColor?.resolve({}) ?? Colors.white;

          return Material(
            color: backgroundColor,
            elevation: 2,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              splashColor: foregroundColor.withOpacity(0.12),
              highlightColor: foregroundColor.withOpacity(0.05),
              //onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  'Respond',
                  style: TextStyle(color: foregroundColor),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// friends // delete // accept // add friend // cancel request
