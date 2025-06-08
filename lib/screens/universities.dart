import 'package:flutter/material.dart';
import 'university_detail.dart';
class UniversitiesScreen extends StatelessWidget {
  final List<Map<String, String>> universities = [
    {
      'name': 'University of Dhaka',
      'logo': 'assets/logos/du_logo.png',
    },
    {
      'name': 'Bangladesh University of Engineering and Technology (BUET)',
      'logo': 'assets/logos/buet_logo.png',
    },
    {
      'name': 'Jahangirnagar University',
      'logo': 'assets/logos/ju_logo.png',
    },
    {
      'name': 'Chittagong University of Engineering and Technology (CUET)',
      'logo': 'assets/logos/cuet_logo.png',
    },
    {
      'name': 'Khulna University of Engineering and Technology (KUET)',
      'logo': 'assets/logos/kuet_logo.png',
    },
    {
      'name': 'Rajshahi University of Engineering and Technology (RUET)',
      'logo': 'assets/logos/ruet_logo.png',
    },
    {
      'name': 'Shahajalal University of Science and Technology (SUST)',
      'logo': 'assets/logos/sust_logo.png',
    },
    {
      'name': 'North South University',
      'logo': 'assets/logos/nsu_logo.png',
    },
    {
      'name': 'BRAC University',
      'logo': 'assets/logos/bracu_logo.png',
    },
    {
      'name': 'Independent University, Bangladesh (IUB)',
      'logo': 'assets/logos/iub_logo.png',
    },
    {
      'name': 'American International University-Bangladesh (AIUB)',
      'logo': 'assets/logos/aiub_logo.png',
    },
    //more universities
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Universities'),
      ),
      body: ListView.builder(
        itemCount: universities.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Image.asset(
              universities[index]['logo']!,
              width: 40.0,
              height: 40.0,
              fit: BoxFit.cover,
            ),
            title: Text(universities[index]['name']!),
            onTap: () {
              // Navigate to the specific university's details screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UniversityDetailsScreen(
                    university: universities[index],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
