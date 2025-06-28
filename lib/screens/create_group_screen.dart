import 'dart:typed_data';

import 'package:campus_connect/services/coudinary_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';


class CreateGroupScreen extends StatefulWidget {
  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  // controllers & state
  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  String  _visibility = 'public';

  FilePickerResult? _pickResult;        // holds the chosen image
  Uint8List?        _previewBytes;      // for quick preview
  bool              _saving = false;

  final _uid = FirebaseAuth.instance.currentUser!.uid;

  // pick image with FilePicker + preview
  Future<void> _pickImage() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,                    // we need bytes for preview
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() {
        _pickResult   = res;
        _previewBytes = res.files.single.bytes;
      });
    }
  }

  //  create group (upload to Cloudinary)
  Future<void> _createGroup() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name required')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // Upload cover (if any) via your helper ------------------------------
      String coverUrl = '';
      if (_pickResult != null) {
        final url = await uploadToCloudinary(_pickResult, 'image');
        if (url == null) throw 'Cover upload failed';
        coverUrl = url;
      }

      // Write the group document -------------------------------------------
      final doc = FirebaseFirestore.instance.collection('groups').doc();
      await doc.set({
        'id'             : doc.id,
        'name'           : name,
        'description'    : _descCtrl.text.trim(),
        'coverImageUrl'  : coverUrl,
        'createdBy'      : _uid,
        'createdAt'      : FieldValue.serverTimestamp(),
        'visibility'     : _visibility,
        'members'        : [_uid],
        'admins'         : [_uid],
        'pendingRequests': <String>[],
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /* ─── UI ───────────────────────────────────────────────────────────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Group Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _visibility,
              items: const [
                DropdownMenuItem(value: 'public',  child: Text('public')),
                DropdownMenuItem(value: 'private', child: Text('private')),
              ],
              decoration: const InputDecoration(labelText: 'Visibility'),
              onChanged: (v) => setState(() => _visibility = v!),
            ),
            const SizedBox(height: 12),
            _previewBytes != null
                ? Image.memory(_previewBytes!, height: 180, fit: BoxFit.cover)
                : Container(height: 180, color: Colors.grey[300]),
            TextButton.icon(
              icon : const Icon(Icons.image),
              label: Text(_previewBytes == null ? 'Choose Cover Image' : 'Change'),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _createGroup,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
