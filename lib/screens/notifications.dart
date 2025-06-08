import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  // Sample data for notifications
  final List<String> notifications = [
    'New comment on your post.',
    'You have a new friend request.',
    'Your post has been liked.',
    'A new event has been created.',
    'Someone mentioned you in a comment.',
    'Your profile picture was updated.',
    'Your friend shared a post.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.notifications, color: Colors.blue),
            title: Text(notifications[index]),
            subtitle: Text('Just now'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Handle notification tap
            },
          );
        },
      ),
    );
  }
}
