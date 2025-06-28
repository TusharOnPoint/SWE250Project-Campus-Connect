import 'package:campus_connect/screens/user_profile_page.dart';
import 'package:campus_connect/widgets/postCard.dart';
import 'package:campus_connect/widgets/widgetBuilder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  List<DocumentSnapshot<Map<String, dynamic>>> userResults = [];
  List<DocumentSnapshot<Map<String, dynamic>>> groupResults = [];

  List<Map<String, dynamic>> postResults = [];

  Map<String, dynamic> userMap = {};
  final String currentUserId =
      FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.isAbsolute &&
        (url.startsWith('http') || url.startsWith('https'));
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 0, 4),
        child: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _resultsList<T>(
    List<T> items,
    Widget Function(T item) itemBuilder,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(children: items.map(itemBuilder).toList());
  }

  // search

  Future<void> _performSearch() async {
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

    final usersSnap  = FirebaseFirestore.instance.collection('users').get();
    final groupsSnap = FirebaseFirestore.instance.collection('groups').get();
    final postsSnap  = FirebaseFirestore.instance.collection('posts').get();

    final results = await Future.wait([usersSnap, groupsSnap, postsSnap]);
    final usersSnapshot  = results[0] as QuerySnapshot;
    final groupsSnapshot = results[1] as QuerySnapshot;
    final postsSnapshot  = results[2] as QuerySnapshot;

    userMap = {
      for (final doc in usersSnapshot.docs) doc.id: doc.data(),
    };

    setState(() {
      userResults = usersSnapshot.docs
          .where((d) => (d['username'] ?? '').toLowerCase().contains(query))
          .cast<DocumentSnapshot<Map<String, dynamic>>>()
          .toList();

      groupResults = groupsSnapshot.docs
          .where((d) => (d['name'] ?? '').toLowerCase().contains(query))
          .cast<DocumentSnapshot<Map<String, dynamic>>>()
          .toList();

      postResults = postsSnapshot.docs
          .where((d) => (d['text'] ?? '').toLowerCase().contains(query))
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final user = userMap[data['authorId']] ?? {};

            return {
              'doc'         : doc,                         // ◄─ keep snapshot
              ...data,
              'username'    : user['username'] ?? 'Unknown',
              'profileImage': user['profileImage'] ?? '',
            };
          })
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Explore'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              autofocus: true,
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users, groups, or posts…',
                prefixIcon: const Icon(Icons.search),
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
          ? const Center(child: Text('Start typing to search…'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // users
                  if (userResults.isNotEmpty) _buildSectionTitle('Users'),
                  _resultsList(userResults, (doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final url  = data['profileImage'] ?? '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: _isValidImageUrl(url)
                            ? NetworkImage(url)
                            : null,
                        child: !_isValidImageUrl(url)
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(data['username'] ?? ''),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfileScreen(user: data),
                          ),
                        );
                      },
                    );
                  }),

                  // groups
                  if (groupResults.isNotEmpty) _buildSectionTitle('Groups'),
                  _resultsList(groupResults, (doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final cover = data['coverImageUrl'] ?? '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: _isValidImageUrl(cover)
                            ? NetworkImage(cover)
                            : null,
                        child: !_isValidImageUrl(cover)
                            ? const Icon(Icons.group)
                            : null,
                      ),
                      title: Text(data['name'] ?? ''),
                      subtitle: Text(data['description'] ?? ''),
                    );
                  }),

                  // posts
                  if (postResults.isNotEmpty) _buildSectionTitle('Posts'),
                  ...postResults.map((map) {
                    final snap         = map['doc'] as DocumentSnapshot;
                    final profileUrl   = map['profileImage'] ?? '';
                    final mediaUrl     = map['mediaUrl'] ?? '';
                    final mediaType    = map['mediaType'] ?? '';

                    return Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: _isValidImageUrl(profileUrl)
                                  ? NetworkImage(profileUrl)
                                  : null,
                              child: !_isValidImageUrl(profileUrl)
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(map['username'] ?? 'Unknown'),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/postDetail',
                                arguments: {
                                  'postDoc'     : snap, 
                                  'currentUserId': currentUserId,
                                },
                              );
                            },
                          ),

                          // media
                          if (mediaType == 'image' &&
                              _isValidImageUrl(mediaUrl))
                            Image.network(mediaUrl),

                          // text
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(map['text'] ?? ''),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

      bottomNavigationBar: CustomWidgetBuilder.buildBottomNavBar(context, 1),
    );
  }
}
