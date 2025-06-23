import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool _showSearch = false;
  String _searchQuery = '';

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) _searchQuery = '';
    });
  }

  Stream<QuerySnapshot> getConversationsStream() {
    return FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: !_showSearch
            ? Text('Messages')
            : TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search username, group, or conversation name',
            border: InputBorder.none,
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getConversationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No conversations found."));
          }

          final allDocs = snapshot.data!.docs;

          // Filter by search
          final filteredDocs = allDocs.where((doc) {
            final name = (doc['conversationName'] ?? '').toString().toLowerCase();
            return _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
          }).toList();

          if (filteredDocs.isEmpty) {
            return Center(child: Text("No conversations match your search."));
          }

          // Separate and sort
          final docsWithTime = <DocumentSnapshot>[];
          final docsWithoutTime = <DocumentSnapshot>[];

          for (var doc in filteredDocs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('lastMessageTime') && data['lastMessageTime'] != null) {
              docsWithTime.add(doc);
            } else {
              docsWithoutTime.add(doc);
            }
          }

          docsWithTime.sort((a, b) {
            final aTime = (a['lastMessageTime'] as Timestamp).toDate();
            final bTime = (b['lastMessageTime'] as Timestamp).toDate();
            return bTime.compareTo(aTime); // Descending
          });

          final sortedDocs = [...docsWithTime, ...docsWithoutTime];

          return ListView.builder(
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              final conversationType = data['type'] ?? 'group';
              final lastMessage = (data['lastMessage'] ?? '').toString();
              final subtitle = lastMessage.isNotEmpty ? lastMessage : 'No messages yet';
              final seen = data.containsKey('seenBy')
                  ? List<String>.from(data['seenBy']).contains(currentUser.uid)
                  : false;

              if (conversationType == 'group') {
                // Direct rendering for group
                final name = data['conversationName'] ?? 'Unnamed Group';
                final profile = data['conversationProfile'] ?? '';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: profile.isNotEmpty ? NetworkImage(profile) : null,
                    child: profile.isEmpty ? Icon(Icons.group) : null,
                  ),
                  title: Text(name),
                  subtitle: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: seen ? null : Icon(Icons.circle, color: Colors.blueAccent, size: 10),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(conversationId: doc.id),
                      ),
                    );
                  },
                );
              } else {
                // Render private using FutureBuilder to fetch other participant
                final participantIds = List<String>.from(data['participants']);
                final otherUserId =
                participantIds.firstWhere((id) => id != currentUser.uid, orElse: () => '');

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        title: Text("Loading..."),
                        subtitle: Text("Fetching user info"),
                      );
                    }

                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return ListTile(
                        title: Text("Unknown user"),
                        subtitle: Text(subtitle),
                      );
                    }

                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    final name = userData['username'] ?? 'Unknown';
                    final profile = userData['profileImage'] ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profile.isNotEmpty ? NetworkImage(profile) : null,
                        child: profile.isEmpty ? Icon(Icons.person) : null,
                      ),
                      title: Text(name),
                      subtitle: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: seen ? null : Icon(Icons.circle, color: Colors.blueAccent, size: 10),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(conversationId: doc.id),
                          ),
                        );
                      },
                    );
                  },
                );
              }
            },
          );
        },
      ),
      floatingActionButton: Tooltip(
        message: 'Create conversation',
        child: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () => Navigator.pushNamed(context, '/addConversation'),
        ),
      ),
    );
  }
}
