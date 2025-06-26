import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_group_screen.dart';
import 'group_feed.dart';

class GroupsScreen extends StatefulWidget {
  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Groups'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Create Group',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateGroupScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search My Groups',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .where('members', arrayContains: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final filteredGroups = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final groupName = (data['name'] ?? '').toString().toLowerCase();
                  return groupName.contains(searchController.text.trim().toLowerCase());
                }).toList();

                if (filteredGroups.isEmpty) {
                  return Center(child: Text('No groups found.'));
                }

                return ListView.builder(
                  itemCount: filteredGroups.length,
                  itemBuilder: (context, index) {
                    final group = filteredGroups[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(group['name'] ?? ''),
                      subtitle: Text(group['description'] ?? ''),
                      leading: CircleAvatar(child: Icon(Icons.group)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupFeedScreen(
                              groupId: filteredGroups[index].id,
                              groupName: group['name'] ?? '', visibility: '',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
