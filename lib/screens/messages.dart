import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
            return Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(),
              ),
            );
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

          // Separate and sort manually
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

              final name = (data['conversationName'] ?? 'Unnamed').toString().trim();
              final profile = (data['conversationProfile'] ?? '').toString();
              final lastMessage = (data['lastMessage'] ?? '').toString();
              final subtitle = lastMessage.isNotEmpty ? lastMessage : 'No messages yet';

              final seen = data.containsKey('seenBy')
                  ? List<String>.from(data['seenBy']).contains(currentUser.uid)
                  : false;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                  profile.isNotEmpty ? NetworkImage(profile) : null,
                  child: profile.isEmpty ? Icon(Icons.group) : null,
                ),
                title: Text(name.isEmpty ? 'Unnamed Conversation' : name),
                subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: seen ? null : Icon(Icons.circle, color: Colors.blueAccent, size: 10),
                onTap: () => Navigator.pushNamed(context, '/chat', arguments: doc.id),
              );
            },
          );
        },
      ),
      floatingActionButton: Tooltip(
        message: 'Create Group',
        child: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () => Navigator.pushNamed(context, '/addConversation'),
        ),
      ),
    );
  }
}
