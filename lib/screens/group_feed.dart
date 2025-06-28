import 'dart:typed_data';
import 'package:campus_connect/services/coudinary_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../widgets/postCard.dart';
import 'invite_friend_screen.dart';

class GroupFeedScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  const GroupFeedScreen({Key? key, required this.groupId, required this.groupName}) : super(key: key);

  @override
  State<GroupFeedScreen> createState() => _GroupFeedScreenState();
}

class _GroupFeedScreenState extends State<GroupFeedScreen> {
  final _controller = TextEditingController();
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  FilePickerResult? _pickResult;
  Uint8List? _previewBytes;
  String? _fileType;
  bool _uploading = false;

  static const int _page = 10;
  DocumentSnapshot? _last;
  bool _loadingMore = false;
  bool _hasMore = true;
  final _posts = <DocumentSnapshot>[];
  final _scroll = ScrollController();

  CollectionReference get _postsRef => FirebaseFirestore.instance.collection('groups').doc(widget.groupId).collection('posts');
  DocumentReference  get _groupDoc  => FirebaseFirestore.instance.collection('groups').doc(widget.groupId);

  @override
  void initState() {
    super.initState();
    _tryFetchPage();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 && !_loadingMore && _hasMore) _fetchMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  /* ------------------------- media picker -------------------------- */
  Future<void> _pickMedia() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.media, withData: true);
    if (res == null || res.files.isEmpty) return;
    final ext = res.files.single.extension?.toLowerCase() ?? '';
    setState(() {
      _pickResult   = res;
      _fileType     = ['mp4', 'mov', 'avi'].contains(ext) ? 'video' : 'image';
      _previewBytes = _fileType == 'image' ? res.files.single.bytes : null;
    });
  }

  /* ------------------------- create post --------------------------- */
  Future<void> _createPost() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pickResult == null) return;
    setState(() => _uploading = true);

    String mediaUrl = '';
    if (_pickResult != null && _fileType != null) {
      mediaUrl = await uploadToCloudinary(_pickResult, _fileType!) ?? '';
      if (mediaUrl.isEmpty) { setState(() => _uploading = false); return; }
    }

    final ref = _postsRef.doc();
    await ref.set({
      'id'        : ref.id,
      'text'      : text,
      'mediaUrl'  : mediaUrl,
      'mediaType' : _fileType ?? '',
      'authorId'  : _uid,
      'timestamp' : FieldValue.serverTimestamp(),
      'likes'     : <String>[],
    });

    _controller.clear();
    setState(() {
      _pickResult = null;
      _previewBytes = null;
      _fileType = null;
      _uploading = false;
      _posts.clear();
      _last = null;
      _hasMore = true;
    });
    _fetchPage();
  }

  /* ------------------------- paging ------------------------------- */
  Future<void> _tryFetchPage() async {
    final g = await _groupDoc.get();
    final members = List<String>.from(g['members'] ?? []);
    if (members.contains(_uid)) _fetchPage();
  }

  Future<void> _fetchPage() async {
    final snap = await _postsRef.orderBy('timestamp', descending: true).limit(_page).get();
    setState(() {
      _posts.addAll(snap.docs);
      _last = snap.docs.isNotEmpty ? snap.docs.last : null;
      _hasMore = snap.docs.length == _page;
    });
  }

  Future<void> _fetchMore() async {
    if (!_hasMore || _last == null) return;
    setState(() => _loadingMore = true);
    final snap = await _postsRef.orderBy('timestamp', descending: true).startAfterDocument(_last!).limit(_page).get();
    setState(() {
      _posts.addAll(snap.docs);
      _last = snap.docs.isNotEmpty ? snap.docs.last : _last;
      _hasMore = snap.docs.length == _page;
      _loadingMore = false;
    });
  }

  /* ------------------------- admin helpers ------------------------ */
  Future<bool> _isAdmin() async {
    final g = await _groupDoc.get();
    final admins = List<String>.from(g['admins'] ?? []);
    return admins.contains(_uid);
  }

  Future<void> _showPending() async {
    final g = await _groupDoc.get();
    final pending = List<String>.from(g['pendingRequests'] ?? []);
    if (pending.isEmpty) {
      showDialog(context: context, builder: (_) => const AlertDialog(content: Text('No pending requests')));
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUsers(pending),
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final users = s.data!;
          return ListView(
            children: users.map((u) {
              final uid = u['uid'];
              return ListTile(
                leading: CircleAvatar(backgroundImage: u['photoUrl'] != null ? NetworkImage(u['photoUrl']) : null, child: u['photoUrl'] == null ? const Icon(Icons.person) : null),
                title: Text(u['username'] ?? uid),
                trailing: Wrap(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await _groupDoc.update({'members': FieldValue.arrayUnion([uid]), 'pendingRequests': FieldValue.arrayRemove([uid])});
                        Navigator.pop(context);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        await _groupDoc.update({'pendingRequests': FieldValue.arrayRemove([uid])});
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  /* ------------------------- members list ------------------------- */
  Future<void> _showMembers() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMembersData(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final members = snap.data ?? [];
          if (members.isEmpty) return const Center(child: Text('No members yet'));
          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (_, i) {
              final m = members[i];
              return ListTile(
                leading: CircleAvatar(backgroundImage: m['photoUrl'] != null ? NetworkImage(m['photoUrl']) : null, child: m['photoUrl'] == null ? const Icon(Icons.person) : null),
                title: Text(m['username'] ?? m['uid']),
                subtitle: Text(m['role']),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchMembersData() async {
    final g = await _groupDoc.get();
    final memberIds = List<String>.from(g['members'] ?? []);
    final adminIds  = List<String>.from(g['admins']  ?? []);
    if (memberIds.isEmpty) return [];
    final users = await _fetchUsers(memberIds);
    for (var u in users) { u['role'] = adminIds.contains(u['uid']) ? 'admin' : 'member'; }
    users.sort((a, b) => memberIds.indexOf(a['uid']).compareTo(memberIds.indexOf(b['uid'])));
    return users;
  }

  Future<List<Map<String, dynamic>>> _fetchUsers(List<String> ids) async {
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < ids.length; i += 10) {
      final batch = ids.sublist(i, (i + 10).clamp(0, ids.length));
      final q = await FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: batch).get();
      for (final d in q.docs) {
        final u = d.data();
        result.add({'uid': d.id, 'username': u['username'] ?? u['displayName'] ?? d.id, 'photoUrl': u['photoUrl']});
      }
    }
    return result;
  }

  /* ------------------------- UI ----------------------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.groupName)),
      body: FutureBuilder<DocumentSnapshot>(
        future: _groupDoc.get(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!.data() as Map<String, dynamic>? ?? {};
          final memberIds = List<String>.from(data['members'] ?? []);
          final banner = data['coverImageUrl'] ?? '';
          final isMember = memberIds.contains(_uid);

          return SingleChildScrollView(
            controller: _scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                banner.isNotEmpty
                    ? Image.network(banner, width: double.infinity, height: 200, fit: BoxFit.cover)
                    : Container(height: 200, color: Colors.grey[300], child: const Center(child: Text('No cover image'))),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(widget.groupName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                      InkWell(onTap: _showMembers, child: Text('${memberIds.length} members', style: const TextStyle(decoration: TextDecoration.underline))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<bool>(
                  future: _isAdmin(),
                  builder: (c, s) {
                    final admin = s.data ?? false;
                    if (!isMember && !admin) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          if (admin)
                            ElevatedButton.icon(icon: const Icon(Icons.pending), label: const Text('Pending'), onPressed: _showPending),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.person_add_alt),
                            label: const Text('Invite friends'),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InviteFriendsScreen(groupId: widget.groupId,),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 30),
                if (isMember) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        if (_pickResult != null) ...[
                          _fileType == 'image'
                              ? Image.memory(_previewBytes!, height: 160, fit: BoxFit.cover)
                              : Container(height: 160, color: Colors.black12, child: const Center(child: Icon(Icons.videocam, size: 48))),
                          const SizedBox(height: 8),
                        ],
                        TextField(controller: _controller, maxLines: 3, decoration: const InputDecoration(hintText: 'Write something…', border: OutlineInputBorder())),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            OutlinedButton.icon(onPressed: _pickMedia, icon: const Icon(Icons.attach_file), label: const Text('Media')),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: _uploading ? null : _createPost,
                              child: _uploading
                                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Post'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 30),
                  ..._posts.map((d) => PostCard(postDoc: d, currentUserId: _uid, isNavigate: true)),
                  if (_loadingMore) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
                ] else ...[
                  const Padding(padding: EdgeInsets.all(32.0), child: Center(child: Text('Only members can view posts.', style: TextStyle(fontSize: 16)))),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
