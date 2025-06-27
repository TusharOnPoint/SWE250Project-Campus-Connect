import 'package:campus_connect/widgets/widgetBuilder.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExploreScreen extends StatefulWidget {
  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  List<DocumentSnapshot> userResults = [];
  List<DocumentSnapshot> groupResults = [];
  List<Map<String, dynamic>> postResults = [];
  Map<String, dynamic> userMap = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_performSearch);
  }

  void _performSearch() async {
    final query = _searchController.text.trim().toLowerCase();
    setState(() => _searchText = query);

    if (query.isEmpty) {
      setState(() {
        userResults = [];
        groupResults = [];
        postResults = [];
      });
      return;
    }

    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    userMap = {
      for (var doc in usersSnapshot.docs) doc.id: doc.data(),
    };

    final groupsSnapshot = await FirebaseFirestore.instance.collection('groups').get();
    final postsSnapshot = await FirebaseFirestore.instance.collection('posts').get();

    setState(() {
      userResults = usersSnapshot.docs
          .where((doc) => (doc['username'] ?? '').toLowerCase().contains(query))
          .toList();

      groupResults = groupsSnapshot.docs
          .where((doc) => (doc['name'] ?? '').toLowerCase().contains(query))
          .toList();

      postResults = postsSnapshot.docs
          .where((doc) => (doc['text'] ?? '').toLowerCase().contains(query))
          .map((doc) {
        final postData = doc.data() as Map<String, dynamic>;
        final userData = userMap[postData['userId']] ?? {};
        return {
          ...postData,
          'username': userData['authorName'] ?? 'Unknown',
          'profileImage': userData['authorImageUrl'] ?? '',
        };
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 0, 4),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _resultsList(List<DocumentSnapshot> docs, Widget Function(DocumentSnapshot) itemBuilder) {
    if (docs.isEmpty) return SizedBox.shrink();
    return Column(children: docs.map((doc) => itemBuilder(doc)).toList());
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null && uri.isAbsolute && (url.startsWith('http') || url.startsWith('https'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Explore"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search users, groups, or posts...",
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _searchText.isEmpty
          ? Center(child: Text("Start typing to search..."))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userResults.isNotEmpty) _buildSectionTitle("Users"),
            _resultsList(userResults, (doc) {
              final data = doc.data() as Map<String, dynamic>;
              final profileUrl = data['profileImage'] ?? '';
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: _isValidImageUrl(profileUrl)
                      ? NetworkImage(profileUrl)
                      : null,
                  child: !_isValidImageUrl(profileUrl)
                      ? Icon(Icons.person)
                      : null,
                ),
                title: Text(data['username'] ?? ''),
              );
            }),

            if (groupResults.isNotEmpty) _buildSectionTitle("Groups"),
            _resultsList(groupResults, (doc) {
              final data = doc.data() as Map<String, dynamic>;
              final coverUrl = data['coverImageUrl'] ?? '';
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: _isValidImageUrl(coverUrl)
                      ? NetworkImage(coverUrl)
                      : null,
                  child: !_isValidImageUrl(coverUrl)
                      ? Icon(Icons.group)
                      : null,
                ),
                title: Text(data['name'] ?? ''),
                subtitle: Text(data['description'] ?? ''),
              );
            }),

            if (postResults.isNotEmpty) _buildSectionTitle("Posts"),
            ...postResults.map((data) {
              final profileUrl = data['authorImageUrl'] ?? '';
              final mediaUrl = data['mediaUrl'] ?? '';
              final mediaType = data['mediaType'] ?? '';
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: _isValidImageUrl(profileUrl)
                            ? NetworkImage(profileUrl)
                            : null,
                        child: !_isValidImageUrl(profileUrl)
                            ? Icon(Icons.person)
                            : null,
                      ),
                      title: Text(data['authorName'] ?? 'Unknown'),
                    ),
                    if (mediaType == 'image' && _isValidImageUrl(mediaUrl))
                      Image.network(mediaUrl),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(data['text'] ?? ''),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
      bottomNavigationBar: CustomWidgetBuilder.buildBottomNavBar(context, 1),
    );
  }
}
