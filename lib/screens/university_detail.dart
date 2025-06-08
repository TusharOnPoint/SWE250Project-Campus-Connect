import 'package:flutter/material.dart';
import 'university_groups.dart';
import 'university_pages.dart';
class UniversityDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> university;

  UniversityDetailsScreen({required this.university});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(university['name']!),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Display university logo and name
            Image.asset(
              university['logo']!,
              width: 100.0,
              height: 100.0,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 20),
            Text(
              university['name']!,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),

            // Group button
            ElevatedButton(
              onPressed: () {
                // Navigate to the Groups page for this university
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupsPage(university: university),
                  ),
                );
              },
              child: Text('Groups'),
            ),
            SizedBox(height: 20),

            // Pages button
            ElevatedButton(
              onPressed: () {
                // Navigate to the Pages page for this university
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PagesPage(university: university),
                  ),
                );
              },
              child: Text('Pages'),
            ),
          ],
        ),
      ),
    );
  }
}
