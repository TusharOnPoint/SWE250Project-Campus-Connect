import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddConversationScreen extends StatefulWidget {
  @override
  _AddConversationScreenState createState() => _AddConversationScreenState();
}

class _AddConversationScreenState extends State<AddConversationScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  String searchText = '';
  List<String> selectedUserIds = [];
  final TextEditingController _groupNameController = TextEditingController();

  Stream<QuerySnapshot> searchUsers(String text) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: text)
        .where('username', isLessThanOrEqualTo: text + '\uf8ff')
        .snapshots();
  }

  Future<List<DocumentSnapshot>> getFriends() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    List friendIds = userDoc['friends'] ?? [];

    if (friendIds.isEmpty) return [];

    final friendDocs = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: friendIds)
        .get();

    return friendDocs.docs;
  }

  void createGroup() async {
    if (_groupNameController.text.trim().isEmpty) return;

    final groupDoc = FirebaseFirestore.instance.collection('conversations').doc();
    await groupDoc.set({
      'conversationId': groupDoc.id,
      'conversationName': _groupNameController.text.trim(),
      'conversationProfile': '',
      'type': 'group',
      'participants': [currentUser.uid, ...selectedUserIds],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  Future<void> startPrivateConversation() async {
    final selectedUserId = selectedUserIds.first;

    final existingConversations = await FirebaseFirestore.instance
        .collection('conversations')
        .where('type', isEqualTo: 'private')
        .where('participants', arrayContains: currentUser.uid)
        .get();

    for (var doc in existingConversations.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(selectedUserId) && participants.length == 2) {
        Navigator.pushNamed(context, '/chat', arguments: doc.id);
        return;
      }
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(selectedUserId).get();
    final userData = userDoc.data() as Map<String, dynamic>;

    final conversationDoc = FirebaseFirestore.instance.collection('conversations').doc();

    await conversationDoc.set({
      'conversationId': conversationDoc.id,
      'conversationName': userData['username'] ?? 'Chat',
      'conversationProfile': userData.containsKey('profileImage') ? userData['profileImage'] : '',
      'type': 'private',
      'participants': [currentUser.uid, selectedUserId],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    Navigator.pushNamed(context, '/chat', arguments: conversationDoc.id);
  }

  Widget buildUserList(List<DocumentSnapshot> users) {
    return ListView(
      children: users.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final isSelected = selectedUserIds.contains(doc.id);
        final username = data['username'] ?? 'Unknown';
        final profileImage = data.containsKey('profileImage') ? data['profileImage'] : '';

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
            child: profileImage.isEmpty ? Icon(Icons.person) : null,
          ),
          title: Text(username),
          trailing: Icon(
            isSelected ? Icons.check_box : Icons.check_box_outline_blank,
            color: isSelected ? Colors.blue : null,
          ),
          onTap: () {
            setState(() {
              isSelected ? selectedUserIds.remove(doc.id) : selectedUserIds.add(doc.id);
            });
          },
        );
      }).toList(),
    );
  }

  Widget buildLoader() => Center(child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Group or Chat")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              onChanged: (value) => setState(() => searchText = value),
              decoration: InputDecoration(hintText: "Search members by username"),
            ),
          ),
          Expanded(
            child: searchText.isNotEmpty
                ? StreamBuilder<QuerySnapshot>(
              stream: searchUsers(searchText),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return buildLoader();
                final users = snapshot.data!.docs
                    .where((doc) => doc.id != currentUser.uid)
                    .toList();
                return buildUserList(users);
              },
            )
                : FutureBuilder<List<DocumentSnapshot>>(
              future: getFriends(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return buildLoader();
                if (snapshot.data!.isEmpty) return Center(child: Text("No friends to show."));
                return buildUserList(snapshot.data!);
              },
            ),
          ),
          if (selectedUserIds.length == 1)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: startPrivateConversation,
                child: Text("Start Conversation"),
              ),
            )
          else if (selectedUserIds.length >= 2)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _groupNameController,
                    decoration: InputDecoration(labelText: "Group Name"),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: createGroup,
                    child: Text("Create Group"),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }
}
