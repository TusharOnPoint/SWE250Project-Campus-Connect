import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/explore.dart';

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
          Navigator.pushNamed(
            context,
            '/home',
          );
        } else if (index == 1 && idx != 1) { 
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExploreScreen()),  // Navigate to ExploreScreen
          );
        } else if (index == 2 && idx != 2) {  // Profile Icon Index
          Navigator.pushNamed(
            context,
            '/profile',
          );
        }
      },
    );
  }

  void showEmailVerificationDialog (BuildContext context){
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

                    await user?.reload(); // Refresh user info
                    if (user != null && !user.emailVerified) {
                      try {
                        await user.sendEmailVerification();
                        ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Verification email sent. Check your inbox.",
                          ),
                        ),
                      );
                      Navigator.pushNamed(context, '/login'); // Close dialog
                      } catch (e){
                        print("Error sending verification email: ${e.toString()}");
                        Navigator.pop(context); // Close dialog
                      }
                        
                    }
                    FirebaseAuth.instance.signOut();
                  } catch (e) {
                    Navigator.pop(context);
                    print(
                      "Failed to send verification email.${e.toString()}",
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Failed to send verification email.${e.toString()}",
                        ),
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