import 'package:campus_connect/utils/userModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/postCard.dart';

class UserProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  //final String? userId;

  const UserProfileScreen({super.key, required this.user});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //final UserService _userService = UserService();
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    //_loadUserData();
    userData = widget.user;
  }

  // Future<void> _loadUserData() async {
  //   //final doc = await _firestore.collection('users').doc(widget.userId).get();
  //   if (doc.exists) {
  //     setState(() {
  //       userData = doc.data();
  //     });
  //   }
  // }

  Stream<QuerySnapshot> _fetchPosts() {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: widget.user['uid'])
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        centerTitle: true,
      ),
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
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
                            image: userData!['coverImage'] != null
                                ? NetworkImage(userData!['coverImage'])
                                : AssetImage('assets/images/cover_placeholder.jpg') as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -60,
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.blue,
                          child: CircleAvatar(
                            radius: 75,
                            backgroundImage: userData!['profileImage'] != null
                                ? NetworkImage(userData!['profileImage'])
                                : AssetImage('assets/images/user_placeholder.jpg') as ImageProvider,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 80),
                  Text(
                    userData!['username'] ?? "User Name",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    userData!['email'] ?? "user@example.com",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 100),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(onPressed: () {}, label: Text('Add friend')),
                        SizedBox(width: 30,),
                        ElevatedButton.icon(onPressed: () {}, label: Text('Message')),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildProfileDetail(Icons.school, "University", userData!['university'] ?? "Not set"),
                  _buildProfileDetail(Icons.work, "Workplace", userData!['workplace'] ?? "Not set"),
                  _buildProfileDetail(Icons.sports_soccer, "Hobbies", userData!['hobbies'] ?? "Not set"),
                  _buildProfileDetail(Icons.star, "Achievements", userData!['achievements'] ?? "Not set"),
                  _buildBioSection(),
                  SizedBox(height: 16),
                  Text("Posts", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                          child: Text("No posts available."),
                        );
                      }

                      final posts = snapshot.data!.docs;
                      return ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          return PostCard(
                            postDoc: posts[index],
                            currentUserId: userData!['uid'],
                            navigateToUserProfile: false,
                          );
                        },
                      );
                    },
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
  }

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
        ],
      ),
    );
  }
}
