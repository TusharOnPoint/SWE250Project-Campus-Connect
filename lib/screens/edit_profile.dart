import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _workplaceController = TextEditingController();
  final TextEditingController _hobbiesController = TextEditingController();
  final TextEditingController _achievementsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _nameController.text = userDoc['name'] ?? '';
          _universityController.text = userDoc['university'] ?? '';
          _workplaceController.text = userDoc['workplace'] ?? '';
          _hobbiesController.text = userDoc['hobbies'] ?? '';
          _achievementsController.text = userDoc['achievements'] ?? '';
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'name': _nameController.text,
        'university': _universityController.text,
        'workplace': _workplaceController.text,
        'hobbies': _hobbiesController.text,
        'achievements': _achievementsController.text,
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: _universityController, decoration: InputDecoration(labelText: "University")),
            TextField(controller: _workplaceController, decoration: InputDecoration(labelText: "Workplace")),
            TextField(controller: _hobbiesController, decoration: InputDecoration(labelText: "Hobbies")),
            TextField(controller: _achievementsController, decoration: InputDecoration(labelText: "Achievements")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _updateProfile, child: Text("Save Changes")),
          ],
        ),
      ),
    );
  }
}
