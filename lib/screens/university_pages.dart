import 'package:flutter/material.dart';

class PagesPage extends StatelessWidget {
  final Map<String, dynamic> university;

  PagesPage({required this.university});

  @override
  Widget build(BuildContext context) {
    // Example: List of pages for the university
    final List<String> pages = [
      'Admission',
      'Courses',
      'Faculty',
      'Research',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${university['name']} - Pages'),
      ),
      body: ListView.builder(
        itemCount: pages.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(pages[index]),
            onTap: () {
              // Add any additional actions on page tap
              print('Tapped on ${pages[index]}');
            },
          );
        },
      ),
    );
  }
}
