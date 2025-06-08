import 'package:flutter/material.dart';

class GroupsPage extends StatelessWidget {
  final Map<String, dynamic> university;

  GroupsPage({required this.university});

  @override
  Widget build(BuildContext context) {
    // Example: List of groups for the university
    final List<String> groups = [
      'Group A',
      'Group B',
      'Group C',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${university['name']} - Groups'),
      ),
      body: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(groups[index]),
            onTap: () {
              // Add any additional actions on group tap
              print('Tapped on ${groups[index]}');
            },
          );
        },
      ),
    );
  }
}
