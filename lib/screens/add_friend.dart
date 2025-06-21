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
            tooltip: 'Friends',
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
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .orderBy('username')
              //.where(searchText, isGreaterThanOrEqualTo: true)
              .startAt([searchText])
              .endAt([searchText + '\uf8ff'])
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const Center(child: Text('No users found.'));

        final users = snapshot.data!.docs;

        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser!.uid)
                  .get(),
          builder: (context, currentUserSnapshot) {
            if (!currentUserSnapshot.hasData) return const SizedBox();

            final currentUserData =
                currentUserSnapshot.data!.data() as Map<String, dynamic>?;
            final sentList = List<String>.from(
              currentUserData?['friend_requests_sent'] ?? [],
            );
            final friendList = List<String>.from(
              currentUserData?['friends'] ?? [],
            );
            final receivedList = List<String>.from(
              currentUserData?['friend_requests'] ?? [],
            );

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final userId = user.id;

                if (userId == currentUser!.uid) return const SizedBox.shrink();

                final isSent = sentList.contains(userId);
                final isFriend = friendList.contains(userId);
                final isReceieved = receivedList.contains(userId);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        user['profileImage'] != null
                            ? NetworkImage(user['profileImage'])
                            : AssetImage('assets/images/user_placeholder.jpg')
                                as ImageProvider,
                  ),
                  title: Text(user['username'] ?? 'No username'),
                  trailing:
                      isFriend
                          ? ElevatedButton(
                            onPressed: null,
                            child: const Text('Friends'),
                          )
                          : isReceieved
                          ? _buildRespondButton(userId, user['username'])
                          : ElevatedButton(
                            onPressed:
                                () =>
                                    isSent
                                        ? _cancelFriendRequest(
                                          userId,
                                          user['username'],
                                        )
                                        : _sendFriendRequest(
                                          userId,
                                          user['username'],
                                        ),
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
                    senderSnapshot.data!.data() as Map<String, dynamic>?;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      senderData?['profileImage'] ??
                          'https://res.cloudinary.com/ddfycczdx/image/upload/v1750106503/xqyhfxyryfeykfxozxcr.jpg',
                    ),
                  ),
                  title: Text(senderData?['username'] ?? 'No name'),
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
                        child: const Text('Cancel'),
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
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .get(),
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
                    receiverSnapshot.data!.data() as Map<String, dynamic>?;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      receiverData?['profileImage'] ??
                          'https://res.cloudinary.com/ddfycczdx/image/upload/v1750106503/xqyhfxyryfeykfxozxcr.jpg',
                    ),
                  ),
                  title: Text(receiverData?['username'] ?? 'No name'),
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
    final senderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(senderId);
    final receiverRef = FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId);

    try {
      await senderRef.update({
        'friend_requests_sent': FieldValue.arrayUnion([receiverId]),
      });
      await receiverRef.update({
        'friend_requests': FieldValue.arrayUnion([senderId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request sent to $receiverUsername')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending request: $e')));
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
          'friends': FieldValue.arrayUnion([senderId]),
        });

        transaction.update(senderRef, {
          'friend_requests_sent': FieldValue.arrayRemove([receiverId]),
          'friends': FieldValue.arrayUnion([receiverId]),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You and $senderUsername are now friends!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    itemBuilder: (context) => [
      PopupMenuItem(
        value: 'accept',
        child: Text('Accept'),
      ),
      PopupMenuItem(
        value: 'delete',
        child: Text('Delete'),
      ),
    ],
    child: ElevatedButton.icon(
      icon: Icon(Icons.reply),
      label: Text('Respond'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onPressed: () {},
    ),
  );
}

}

// friends // delete // accept // add friend // cancel request
