import 'package:campus_connect/widgets/postCard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/widgetBuilder.dart';
import 'groups.dart';
import 'pages.dart';
import 'notifications.dart';
import 'messages.dart';
import 'add_friend.dart';
import 'universities.dart';

class HomeScreen extends StatelessWidget {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Campus Connect'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationScreen(userId: FirebaseAuth.instance.currentUser!.uid),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person_add), // Add Friend Icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddFriendScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.message),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MessagesScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.group),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GroupsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.pages),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PagesScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.school), // University Icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UniversitiesScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if(!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No posts available"));
          }
          final snap = snapshot.data;
          return ListView.builder(
            itemCount: snap!.docs.length,
            itemBuilder: (context, index) {
              final post = snap.docs[index];
              return PostCard(postDoc: post, currentUserId: currentUserId);
            },
          );
        },
      ),
      bottomNavigationBar: CustomWidgetBuilder.buildBottomNavBar(context, 0),
    );
  }
}