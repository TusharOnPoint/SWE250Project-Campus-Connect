import 'package:flutter/material.dart';

class AddFriendScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Friend'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Search for friends',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 10, // Example list of users
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage('assets/images/user_placeholder.jpg'),
                    ),
                    title: Text('User ${index + 1}'),
                    subtitle: Text('user${index + 1}@campusconnect.com'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Friend request sent to User ${index + 1}')),
                        );
                      },
                      child: Text('Add'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
