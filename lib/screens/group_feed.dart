// group_feed.dart
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../widgets/postCard.dart';
import 'invite_friend_screen.dart';

const cloudinaryUploadPreset = 'your_upload_preset';
const cloudinaryCloudName   = 'your_cloud_name';

class GroupFeedScreen extends StatefulWidget {
  final String groupId;
  final String groupName;         // 'public' | 'private'

  const GroupFeedScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  State<GroupFeedScreen> createState() => _GroupFeedScreenState();
}

/* ───────────────────────────────────────────────────────────── */
class _GroupFeedScreenState extends State<GroupFeedScreen> {
/* ------------------------------------------------ state ------ */
  final _controller = TextEditingController();
  final _uid        = FirebaseAuth.instance.currentUser!.uid;

  File?   _file;
  String? _fileType;                   // 'image' | 'video'
  bool    _uploading = false;

/* paging */
  static const int _page = 10;
  DocumentSnapshot? _last;
  bool _loadingMore = false;
  bool _hasMore     = true;
  final _posts  = <DocumentSnapshot>[];
  final _scroll = ScrollController();

/* refs */
  CollectionReference get _postsRef => FirebaseFirestore.instance
      .collection('groups')
      .doc(widget.groupId)
      .collection('posts');

  DocumentReference get _groupDoc =>
      FirebaseFirestore.instance.collection('groups').doc(widget.groupId);

/* ------------------------------------------------ init / dispose ------ */
  @override
  void initState() {
    super.initState();
    _tryFetchPage();                       // will fetch only if member
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
          !_loadingMore &&
          _hasMore) _fetchMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

/* ------------------------------------------------ media picker ------ */
  Future<void> _pickMedia() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) return;
    final ext = x.name.split('.').last.toLowerCase();
    setState(() {
      _file     = File(x.path);
      _fileType = ['mp4', 'mov', 'avi'].contains(ext) ? 'video' : 'image';
    });
  }

/* ------------------------------------------------ upload helper ------ */
  Future<String?> _uploadToCloudinary(File f, String t) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/${t == 'image' ? 'image' : 'video'}/upload',
    );
    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', f.path));
    final res = await req.send();
    if (res.statusCode == 200) {
      final data = jsonDecode(await res.stream.bytesToString());
      return data['secure_url'];
    }
    return null;
  }

/* ------------------------------------------------ create post ------ */
  Future<void> _createPost() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _file == null) return;

    setState(() => _uploading = true);
    var mediaUrl = '';
    if (_file != null && _fileType != null) {
      final url = await _uploadToCloudinary(_file!, _fileType!);
      if (url == null) return setState(() => _uploading = false);
      mediaUrl = url;
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
      _file = null;
      _fileType = null;
      _uploading = false;
      _posts.clear();
      _last = null;
      _hasMore = true;
    });
    _fetchPage();
  }

/* ------------------------------------------------ paging ------ */
  Future<void> _tryFetchPage() async {
    final g = await _groupDoc.get();
    final members = List<String>.from(g['members'] ?? []);
    if (members.contains(_uid)) _fetchPage();          // only members
  }

  Future<void> _fetchPage() async {
    final snap = await _postsRef
        .orderBy('timestamp', descending: true)
        .limit(_page)
        .get();
    setState(() {
      _posts.addAll(snap.docs);
      _last   = snap.docs.isNotEmpty ? snap.docs.last : null;
      _hasMore = snap.docs.length == _page;
    });
  }

  Future<void> _fetchMore() async {
    if (!_hasMore || _last == null) return;
    setState(() => _loadingMore = true);
    final snap = await _postsRef
        .orderBy('timestamp', descending: true)
        .startAfterDocument(_last!)
        .limit(_page)
        .get();
    setState(() {
      _posts.addAll(snap.docs);
      _last   = snap.docs.isNotEmpty ? snap.docs.last : _last;
      _hasMore = snap.docs.length == _page;
      _loadingMore = false;
    });
  }

/* ------------------------------------------------ admin helpers ------ */
  Future<bool> _isAdmin() async {
    final g = await _groupDoc.get();
    final admins = List<String>.from(g['admins'] ?? []);
    return admins.contains(_uid);
  }

/* ---------------- Pending-requests sheet (array-based) --------------- */
  Future<void> _showPending() async {
    final g = await _groupDoc.get();
    final List<String> pending =
        List<String>.from(g['pendingRequests'] ?? []);

    if (pending.isEmpty) {
      showDialog(
        context: context,
        builder: (_) =>
            const AlertDialog(content: Text('No pending requests')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUsers(pending),
        builder: (c, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = s.data!;
          return ListView(
            children: users.map((u) {
              final uid = u['uid'];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: u['photoUrl'] != null
                      ? NetworkImage(u['photoUrl'])
                      : null,
                  child: u['photoUrl'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(u['username'] ?? uid),
                trailing: Wrap(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await _groupDoc.update({
                          'members'        : FieldValue.arrayUnion([uid]),
                          'pendingRequests': FieldValue.arrayRemove([uid]),
                        });
                        Navigator.pop(context);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        await _groupDoc.update({
                          'pendingRequests': FieldValue.arrayRemove([uid]),
                        });
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

/* ---------------- Members sheet (array-based) ----------------------- */
  Future<void> _showMembers() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMembersData(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error: ${snap.error}'),
            );
          }

          final members = snap.data ?? [];
          if (members.isEmpty) {
            return const SizedBox(
              height: 160,
              child: Center(child: Text('No members yet')),
            );
          }

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (_, i) {
              final m = members[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: m['photoUrl'] != null
                      ? NetworkImage(m['photoUrl'])
                      : null,
                  child: m['photoUrl'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title : Text(m['username'] ?? m['uid']),
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

    // mark role
    for (var u in users) {
      u['role'] = adminIds.contains(u['uid']) ? 'admin' : 'member';
    }
    // preserve original order
    users.sort((a, b) =>
        memberIds.indexOf(a['uid']).compareTo(memberIds.indexOf(b['uid'])));

    return users;
  }

/* ---------------- helper to fetch user docs in <=10 batches ---------- */
  Future<List<Map<String, dynamic>>> _fetchUsers(List<String> ids) async {
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < ids.length; i += 10) {
      final batch = ids.sublist(i, (i + 10).clamp(0, ids.length));
      final q = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final d in q.docs) {
        final u = d.data();
        result.add({
          'uid'      : d.id,
          'username' : u['username'] ?? u['displayName'] ?? d.id,
          'photoUrl' : u['photoUrl'],
        });
      }
    }
    return result;
  }

/* ---------------- join / request join (array-based) ----------------- */
  Future<void> _requestJoin() async {
    final g = await _groupDoc.get();
    final members = List<String>.from(g['members'] ?? []);
    final pending = List<String>.from(g['pendingRequests'] ?? []);

    if (members.contains(_uid)) return;        // already a member
    if (pending.contains(_uid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request already sent')),
      );
      return;
    }

    await _groupDoc.update({
      'pendingRequests': FieldValue.arrayUnion([_uid]),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request sent')),
    );
    setState(() {});                           // refresh UI
  }

/* ────────────────────────────────────────────── UI build ------ */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.groupName)),
      body: FutureBuilder<DocumentSnapshot>(
        future: _groupDoc.get(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data() as Map<String, dynamic>? ?? {};
          final memberIds = List<String>.from(data['members'] ?? []);
          final pendingIds = List<String>.from(data['pendingRequests'] ?? []);
          final isMember  = memberIds.contains(_uid);
          final hasRequested = pendingIds.contains(_uid);

          final membersCount = memberIds.length;
          final banner = data['coverImageUrl'] ?? '';

          return SingleChildScrollView(
            controller: _scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /* banner */
                banner.isNotEmpty
                    ? Image.network(
                        banner,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(child: Text('No cover image')),
                      ),

                const SizedBox(height: 12),

                /* name + member-count */
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.groupName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _showMembers,
                        child: Text(
                          '$membersCount members',
                          style: const TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                /* action buttons */
                FutureBuilder<bool>(
                  future: _isAdmin(),
                  builder: (c, s) {
                    final admin = s.data ?? false;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          admin
                              ? ElevatedButton.icon(
                                  onPressed: _showPending,
                                  icon: const Icon(Icons.pending),
                                  label: const Text('Pending requests'),
                                )
                              : isMember
                                  ? ElevatedButton.icon(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => InviteFriendsScreen(
                                            groupId: widget.groupId,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(Icons.person_add_alt),
                                      label: const Text('Invite friends'),
                                    )
                                  : ElevatedButton(
                                      onPressed:
                                          hasRequested ? null : _requestJoin,
                                      child: Text(
                                        hasRequested
                                            ? 'Requested'
                                            : 'Join group',
                                      ),
                                    ),
                        ],
                      ),
                    );
                  },
                ),

                const Divider(height: 30),

                /* ---- composer & feed (MEMBERS ONLY) ---- */
                if (isMember) ...[
                  /* composer */
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _controller,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Write something…',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickMedia,
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Media'),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: _uploading ? null : _createPost,
                              child: _uploading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Post'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 30),

                  /* feed */
                  ..._posts.map(
                    (d) => PostCard(
                      postDoc: d,
                      currentUserId: _uid,
                      isNavigate: false,
                    ),
                  ),
                  if (_loadingMore)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'Only members can view posts.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
