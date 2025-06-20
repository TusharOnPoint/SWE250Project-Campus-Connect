import 'package:campus_connect/services/user_sevice.dart';
import 'package:campus_connect/widgets/widgetBuilder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/coudinary_services.dart';
import '../widgets/postCard.dart';
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
  UserService _userService = new UserService();
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Fetch user data from Firestore
  Future<void> _loadUserData() async {
    final data = await _userService.fetchUserData();
    setState(() {
      userData = data;
    });
  }


  // Stream for fetching posts
  Stream<QuerySnapshot> _fetchPosts() {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: _auth.currentUser?.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _updatePhoto(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
      //allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.single.path == null) return;

    String? uploadedUrl = await uploadToCloudinary(result, 'image');
    if (uploadedUrl == null) return;

    String field = type == 'profile' ? 'profileImage' : 'coverImage';

    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      field: uploadedUrl,
    });

    _loadUserData(); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    //_fetchUserData();
    return Scaffold(

      appBar: AppBar(
        elevation: 15,
        centerTitle: true,
        title: Text('Profile'),
        actions: [
          TextButton.icon(
            onPressed: () => _showLogoutDialog(context),
            icon: Icon(Icons.logout, color: Colors.red),
            label: Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: userData?['coverImage'] != null
                          ? NetworkImage(userData!['coverImage'])
                          : AssetImage('assets/images/cover_placeholder.jpg') as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Cover photo edit button
                Positioned(
                  top: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey,
                    child: IconButton(
                      icon: Icon(Icons.camera_alt, size: 24, color: Colors.black54),
                      onPressed: () => _updatePhoto('cover'),
                    ),
                  ),
                ),

                // Profile picture
                Positioned(
                  bottom: -60,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topLeft,
                    children: [
                      CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.blue,
                        child: CircleAvatar(
                          radius: 75,
                          backgroundImage: userData?['profileImage'] != null
                              ? NetworkImage(userData!['profileImage'])
                              : AssetImage('assets/images/user_placeholder.jpg') as ImageProvider,
                        ),
                      ),

                      // profile picture edit button
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey,
                        child: IconButton(
                          icon: Icon(Icons.camera_alt, size: 24, color: Colors.black54),
                          onPressed: () => _updatePhoto('profile'),
                        ),
                      ),


                        ],
                      ),
                ),
              ],
            ),
            SizedBox(height: 80),
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
                    _loadUserData(); // Refresh profile data after returning
                  },
                  icon: Icon(Icons.edit),
                  label: Text("Edit Profile"),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreatePostScreen()),
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
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: _fetchPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text("You haven't posted anything yet."),
                  );
                }

                final posts = snapshot.data!.docs;
                return ListView.builder(
                  physics: NeverScrollableScrollPhysics(), // prevent nested scrolling issues
                  shrinkWrap: true,
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return PostCard(
                      postDoc: posts[index],
                      currentUserId: _auth.currentUser!.uid,
                    );
                  },
                );
              },
            ),

            //logout button
          ],
        ),
      ),
      bottomNavigationBar: CustomWidgetBuilder.buildBottomNavBar(context, 2),
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
                final data = await _userService.updateBio(newBio);  // Update bio in Firestore
                setState(() {
                  userData = data;
                });

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
              _auth.signOut();
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

