
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'create_group_screen.dart';
import 'group_feed.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _uid    = FirebaseAuth.instance.currentUser!.uid;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> _myGroupsStream() {
    final coll = FirebaseFirestore.instance.collection('groups');
    final members$ = coll.where('members', arrayContains: _uid).snapshots();
    final admins$  = coll.where('admins',  arrayContains: _uid).snapshots();

    return Rx.combineLatest2(members$, admins$, (
      QuerySnapshot<Map<String, dynamic>> m,
      QuerySnapshot<Map<String, dynamic>> a,
    ) {
      final Map<String, DocumentSnapshot<Map<String, dynamic>>> uniq = {};
      for (final d in m.docs) uniq[d.id] = d;
      for (final d in a.docs) uniq[d.id] = d;
      return uniq.values.toList();
    });
  }

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> _searchStream(
      String q, {
      int limit = 200,
    }) {
    return FirebaseFirestore.instance
        .collection('groups')
        .orderBy('name') 
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .where((d) =>
                (d['name'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(q.toLowerCase()))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    final query     = _search.text.trim();
    final searching = query.isNotEmpty;
    final stream    =
        searching ? _searchStream(query) : _myGroupsStream();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create group',
            onPressed: () =>
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => CreateGroupScreen())),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search groups…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
        ),
      ),

      body: StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snap.data ?? [];
          if (groups.isEmpty) {
            return Center(
              child: Text(
                searching
                    ? 'No groups match “$query”.'
                    : 'You are not a member of any groups.',
              ),
            );
          }

          return ListView.separated(
            itemCount: groups.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 0),
            itemBuilder: (context, i) {
              final g    = groups[i];
              final data = g.data()!;
              final membersCnt =
                  (data['members'] as List<dynamic>? ?? []).length;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: (data['coverImageUrl'] ?? '').isNotEmpty
                      ? NetworkImage(data['coverImageUrl'])
                      : null,
                  child: (data['coverImageUrl'] ?? '').isEmpty
                      ? const Icon(Icons.groups)
                      : null,
                ),
                title: Text(data['name'] ?? 'Unnamed'),
                subtitle:
                    Text('$membersCnt member${membersCnt == 1 ? '' : 's'}'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupFeedScreen(
                      groupId: g.id,
                      groupName: data['name'] ?? '',
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
