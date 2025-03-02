import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'profile.dart';  // Ensure this file exists and has ProfileScreen

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Campus Connect'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Open notifications
            },
          ),
          IconButton(
            icon: Icon(Icons.message),
            onPressed: () {
              // Open messages
            },
          ),
        ],
      ),
      body: _buildPostsList(context),  // Removed the stories section
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (index) {
        if (index == 2) {  // Profile Icon Index
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen()),
          );
        }
      },
    );
  }

  Widget _buildPostsList(BuildContext context) {
    return ListView(
      children: [
        _buildTextPost('Alice Johnson', '1 hour ago', 'Excited for the upcoming campus event! Who else is joining?'),
        _buildPhotoPost(context, 'Michael Smith', '3 hours ago', 'Captured a beautiful sunset on campus today!', 'assets/images/sunset.jpg'),
        _buildPhotoPost(context, 'Emily Davis', '5 hours ago', 'Loving the new library setup!', 'assets/images/library.jpeg'),
        VideoPost(
          userName: 'Daniel Brown',
          time: '6 hours ago',
          content: 'Beautiful SUST at starting of spring!',
          videoPath: 'assets/videos/boshonto.mp4',
        ),
        _buildTextPost('Sophia Wilson', '8 hours ago', 'Finally submitted my final project! Time to relax.'),
      ],
    );
  }

  Widget _buildTextPost(String userName, String time, String content) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage('assets/images/user_placeholder.jpg'),  // Changed placeholder
            ),
            title: Text(userName),
            subtitle: Text(time),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(content),
          ),
          _buildPostActions(),
        ],
      ),
    );
  }

  Widget _buildPhotoPost(BuildContext context, String userName, String time, String content, String imagePath) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage('assets/images/user_placeholder.jpg'),  // Changed placeholder
            ),
            title: Text(userName),
            subtitle: Text(time),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(content),
          ),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.width * 0.6, // Dynamic height based on screen width
            ),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
          _buildPostActions(),
        ],
      ),
    );
  }

  Widget _buildPostActions() {
    return ButtonBar(
      alignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(icon: Icon(Icons.thumb_up_alt_outlined), onPressed: () {}),
        IconButton(icon: Icon(Icons.comment_outlined), onPressed: () {}),
        IconButton(icon: Icon(Icons.share_outlined), onPressed: () {}),
      ],
    );
  }
}

class VideoPost extends StatefulWidget {
  final String userName;
  final String time;
  final String content;
  final String videoPath;

  VideoPost({required this.userName, required this.time, required this.content, required this.videoPath});

  @override
  _VideoPostState createState() => _VideoPostState();
}

class _VideoPostState extends State<VideoPost> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        setState(() {}); // Refresh UI when video loads
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage('assets/images/user_placeholder.jpg'),  // Changed placeholder
            ),
            title: Text(widget.userName),
            subtitle: Text(widget.time),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(widget.content),
          ),
          _controller.value.isInitialized
              ? Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.width * 0.6, // Dynamically limit height
            ),
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          )
              : Container(
            height: 200,
            color: Colors.black12,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          IconButton(
            icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _controller.value.isPlaying ? _controller.pause() : _controller.play();
              });
            },
          ),
          _buildPostActions(),
        ],
      ),
    );
  }

  Widget _buildPostActions() {
    return ButtonBar(
      alignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(icon: Icon(Icons.thumb_up_alt_outlined), onPressed: () {}),
        IconButton(icon: Icon(Icons.comment_outlined), onPressed: () {}),
        IconButton(icon: Icon(Icons.share_outlined), onPressed: () {}),
      ],
    );
  }
}
