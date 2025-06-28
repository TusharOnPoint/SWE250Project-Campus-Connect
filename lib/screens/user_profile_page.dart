import 'package:campus_connect/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:campus_connect/services/user_sevice.dart';
import 'package:campus_connect/services/friend_manager.dart';   // <-- adjust path if needed
import '../widgets/postCard.dart';

class UserProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;  

  const UserProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  Map<String, dynamic>? userData;

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isFriend = false;
  bool _isRequestSent = false;
  bool _isRequestReceived = false;
  bool _loadingRelationship = true;

  @override
  void initState() {
    super.initState();
    userData = widget.user;
    _initRelationship();
  }

  // tiny refresh whenever this screen regains focus
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initRelationship();
  }

  Future<void> _initRelationship() async {
    final myData = await _userService.fetchUserData(); 
    if (!mounted || myData == null) return;

    final sent     = List<String>.from(myData['friend_requests_sent'] ?? []);
    final friends  = List<String>.from(myData['friends'] ?? []);
    final received = List<String>.from(myData['friend_requests'] ?? []);

    final viewedUid = widget.user['uid'] as String;

    setState(() {
      _isFriend          = friends.contains(viewedUid);
      _isRequestSent     = sent.contains(viewedUid);
      _isRequestReceived = received.contains(viewedUid);
      _loadingRelationship = false;
    });
  }

  /// Opens an existing 1-to-1 conversation with user, or creates one.
  Future<void> _openChat() async {
    // You can’t chat with yourself
    if (widget.user['uid'] == _currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can’t message yourself.")),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser!;
    final selectedUserId = widget.user['uid'] as String;

    // 1. look for an existing private conversation
    final existing = await _firestore
        .collection('conversations')
        .where('type', isEqualTo: 'private')
        .where('participants', arrayContains: currentUser.uid)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.length == 2 && participants.contains(selectedUserId)) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(conversationId: doc.id)),
        );
        return; // done
      }
    }

    // 2. otherwise create a brand-new conversation
    final userDoc =
        await _firestore.collection('users').doc(selectedUserId).get();
    final userData = userDoc.data() as Map<String, dynamic>;

    final convoRef = _firestore.collection('conversations').doc();
    await convoRef.set({
      'conversationId': convoRef.id,
      'conversationName': userData['username'] ?? 'Chat',
      'conversationProfile': userData['profileImage'] ?? '',
      'type': 'private',
      'participants': [currentUser.uid, selectedUserId],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(conversationId: convoRef.id)),
    );
  }
  
  Future<void> _sendRequest() async {
    await FriendManager.sendFriendRequest(
      context, _currentUid, widget.user['uid'], widget.user['username']);
    setState(() => _isRequestSent = true);
  }

  Future<void> _cancelRequest() async {
    await FriendManager.cancelFriendRequest(
      context, _currentUid, widget.user['uid'], widget.user['username']);
    setState(() => _isRequestSent = false);
  }

  Future<void> _acceptRequest() async {
    await FriendManager.acceptFriendRequest(
      context, _currentUid, widget.user['uid'], widget.user['username']);
    setState(() {
      _isFriend = true;
      _isRequestReceived = false;
    });
  }

  Future<void> _declineRequest() async {
    await FriendManager.cancelReceivedRequest(
      context, _currentUid, widget.user['uid'], widget.user['username']);
    setState(() => _isRequestReceived = false);
  }

  Future<void> _unfriend() async {
    await FriendManager.unfriend(
      context, _currentUid, widget.user['uid'], widget.user['username']);
    setState(() => _isFriend = false);
  }

  Widget _buildFriendButton() {
    if (_loadingRelationship || widget.user['uid'] == _currentUid) {
      return const SizedBox.shrink();
    }

    if (_isFriend) {
      return ElevatedButton.icon(
        onPressed: _unfriend,
        icon: const Icon(Icons.person_remove),
        label: const Text('Unfriend'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
      );
    }

    if (_isRequestReceived) {
      // dropdown- Accept  /  Delete
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: PopupMenuButton<String>(
          splashRadius: 24,
          onSelected: (v) => v == 'accept' ? _acceptRequest() : _declineRequest(),
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'accept',
              child: ListTile(
                leading: Icon(Icons.check_circle_outline),
                title: Text('Accept'),
              ),
            ),
            PopupMenuItem(
              value: 'decline',
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('Delete', style: TextStyle(color: Colors.red),),
              ),
            ),
          ],
          child: IgnorePointer(
            child: ElevatedButton.icon(
              onPressed: () {}, 
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Respond'),
            ),
          ),
        ),
      );
    }

    if (_isRequestSent) {
      return ElevatedButton.icon(
        onPressed: _cancelRequest,
        icon: const Icon(Icons.hourglass_top),
        label: const Text('Cancel Request'),
      );
    }

    return ElevatedButton.icon(
      onPressed: _sendRequest,
      icon: const Icon(Icons.person_add_alt_1),
      label: const Text('Add Friend'),
    );
  }

  Widget _buildProfileDetail(IconData icon, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue), const SizedBox(width: 10),
          Text('$title:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(detail,
                style: const TextStyle(fontSize: 16, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 10),
          const Text('Bio:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(userData?['bio'] ?? 'No bio set',
                style: const TextStyle(fontSize: 16, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot<Object?>> _fetchPosts() {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: widget.user['uid'])
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile'), centerTitle: true),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: userData!['coverImage'] != null
                                ? NetworkImage(userData!['coverImage'])
                                : const AssetImage(
                                        'assets/images/cover_placeholder.jpg')
                                    as ImageProvider,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -60,
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.blue,
                          child: CircleAvatar(
                            radius: 75,
                            backgroundImage: userData!['profileImage'] != null
                                ? NetworkImage(userData!['profileImage'])
                                : const AssetImage(
                                        'assets/images/user_placeholder.jpg')
                                    as ImageProvider,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),

                  //name & email
                  Text(userData!['username'] ?? 'User Name',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(userData!['email'] ?? 'user@example.com',
                      style:
                          const TextStyle(fontSize: 16, color: Colors.grey)),

                  // friend / message buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFriendButton(),
                      const SizedBox(width: 30),
                      ElevatedButton.icon(
                        onPressed: widget.user['uid'] == _currentUid ? null : _openChat,
                        icon: const Icon(Icons.message_outlined),
                        label: const Text('Message'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // details
                  _buildProfileDetail(Icons.school, "University", userData?['university'] ?? "Not set"),
                  _buildProfileDetail(Icons.apartment, "Department", userData?['department'] ?? "Not set"),
                  _buildProfileDetail(Icons.book, "Course", userData?['course'] ?? "Not set"),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 20.0),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.blue),
                        SizedBox(width: 10),
                        Text("Year & Semester:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${userData?['year']?.toString() ?? 'Not set'} - ${userData?['semester']?.toString() ?? 'Not set'}",
                            style: TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildProfileDetail(Icons.work, "Workplace", userData?['workplace'] ?? "Not set"),
                  _buildProfileDetail(Icons.sports_soccer, "Hobbies", userData?['hobbies'] ?? "Not set"),
                  _buildProfileDetail(Icons.star, "Achievements", userData?['achievements'] ?? "Not set"),
                  _buildBioSection(),

                  // posts
                  const SizedBox(height: 16),
                  const Text('Posts',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: _fetchPosts(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snap.hasError) {
                        return Text('Error: ${snap.error}');
                      }
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('No posts available.'),
                        );
                      }

                      final posts = snap.data!.docs;
                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: posts.length,
                        itemBuilder: (_, i) => PostCard(
                          postDoc: posts[i],
                          currentUserId: _currentUid,
                          navigateToUserProfile: false,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
