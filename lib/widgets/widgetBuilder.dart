import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../screens/explore.dart';
import '../screens/home.dart';
import '../screens/profile.dart';

class CustomWidgetBuilder {
  static Widget buildBottomNavBar(BuildContext context, int idx) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: idx,
      onTap: (index) {
        if (index == 0 && idx != 0) {
          // Do nothing as it's the Home screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),  // Navigate to ExploreScreen
          );
        } else if (index == 1 && idx != 1) {  // Explore Icon Index
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExploreScreen()),  // Navigate to ExploreScreen
          );
        } else if (index == 2 && idx != 2) {  // Profile Icon Index
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen()),
          );
        }
      },
    );
  }
}