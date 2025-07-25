import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/explore.dart';

// USING AN ENUM INSTEAD OF MAGIC NUMBERS
enum NavIndex {
  HOME, EXPLORE, PROFILE;
}

class CustomWidgetBuilder {
  
  static Widget buildBottomNavBar(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == NavIndex.HOME && currentIndex != NavIndex.HOME) {
          Navigator.pushNamed(context, '/home');
        } else if (index == NavIndex.EXPLORE && currentIndex != NavIndex.EXPLORE) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExploreScreen()),
          );
        } else if (index == NavIndex.PROFILE && currentIndex != NavIndex.PROFILE) {
          Navigator.pushNamed(context, '/profile');
        }
      },
    );
  }

  void showEmailVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Email Not Verified"),
          content: Text(
            "Your email is not verified. Please verify it to continue.",
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  User? user = FirebaseAuth.instance.currentUser;
                  await user?.reload();

                  if (user != null && !user.emailVerified) {
                    try {
                      await user.sendEmailVerification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Verification email sent. Check your inbox."),
                        ),
                      );
                      Navigator.pushNamed(context, '/login');
                    } catch (e) {
                      print("Error sending verification email: ${e.toString()}");
                      Navigator.pop(context);
                    }
                  }
                  FirebaseAuth.instance.signOut();
                } catch (e) {
                  Navigator.pop(context);
                  print("Failed to send verification email. ${e.toString()}");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to send verification email. ${e.toString()}"),
                    ),
                  );
                }
              },
              child: Text("Verify Email"),
            ),
            TextButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }
}
