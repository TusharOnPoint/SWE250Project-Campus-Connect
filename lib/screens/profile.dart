import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile.dart';
import 'login.dart';
import 'post_content.dart';
// 2021831003@student.sust.edu
class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      print("Current user UID: ${user.uid}");
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          print("User document found: ${userDoc.data()}");
          setState(() {
            userData = userDoc.data() as Map<String, dynamic>;
          });
        } else {
          print("No user document exists for this UID.");
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    } else {
      print("User is not logged in.");
    }
  }


  // Stream for fetching posts
  Stream<QuerySnapshot> _fetchPosts() {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Update bio in Firestore
  Future<void> _updateBio(String newBio) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'bio': newBio,
        });
        _fetchUserData();  // Refresh data after update
      } catch (e) {
        print('Error updating bio: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //_fetchUserData();
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/cover_photo.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundImage: AssetImage('assets/images/user_profile.jpeg'),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 50),
            userData == null
                ? Container(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
                : Column(
              children: [
                Text(
                  userData? ['username'] ?? "User Name",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  _auth.currentUser?.email ?? "user@example.com",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 16),
                _buildProfileDetail(Icons.school, "University", userData?['university'] ?? "Not set"),
                _buildProfileDetail(Icons.work, "Workplace", userData?['workplace'] ?? "Not set"),
                _buildProfileDetail(Icons.sports_soccer, "Hobbies", userData?['hobbies'] ?? "Not set"),
                _buildProfileDetail(Icons.star, "Achievements", userData?['achievements'] ?? "Not set"),
                SizedBox(height: 16),
                // Bio Section with Edit Option
                _buildBioSection(),
                SizedBox(height: 16),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfileScreen()),
                    );
                    _fetchUserData(); // Refresh profile data after returning
                  },
                  icon: Icon(Icons.edit),
                  label: Text("Edit Profile"),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PostContentScreen()),
                    );
                  },
                  icon: Icon(Icons.add_a_photo),
                  label: Text("Post Content"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text("Your Posts", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: Icon(Icons.logout, color: Colors.red),
              label: Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetail(IconData icon, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 20.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          SizedBox(width: 10),
          Text("$title:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: Text(detail, style: TextStyle(fontSize: 16, color: Colors.black87)),
          ),
        ],
      ),
    );
  } // return

  // Bio Section with an editable bio
  Widget _buildBioSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 20.0),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue),
          SizedBox(width: 10),
          Text("Bio:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: Text(userData?['bio'] ?? "No bio set", style: TextStyle(fontSize: 16, color: Colors.black87)),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue),
            onPressed: () {
              _showEditBioDialog();
            },
          ),
        ],
      ),
    );
  }

  // Dialog for editing bio
  void _showEditBioDialog() {
    TextEditingController bioController = TextEditingController();
    bioController.text = userData?['bio'] ?? "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Bio"),
        content: TextField(
          controller: bioController,
          decoration: InputDecoration(hintText: "Enter your bio"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);  // Close dialog
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              String newBio = bioController.text.trim();
              if (newBio.isNotEmpty) {
                await _updateBio(newBio);  // Update bio in Firestore
                Navigator.pop(context);  // Close dialog
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  // Logout dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
              );
            },
            child: Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}