import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'login.dart';

class RootScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Waiting for Firebase to check auth status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
            appBar: AppBar(
              centerTitle: true,
              title: Text("Campus Connect"),
              backgroundColor: Colors.blue,
          ),
          );
        }

        // If user is logged in
        if (snapshot.hasData) {
          User? user = snapshot.data;

          // 🔄 Refresh the user to get latest verification status
          user?.reload();
          user = FirebaseAuth.instance.currentUser;

          if (user != null && user.emailVerified) {
            print("✅ Logged in and email verified");
            return HomeScreen();
          } else {
            print("❌ Email not verified");
            FirebaseAuth.instance.signOut();
            return LoginScreen();
          }
        }

        // Not logged in
        print("❌ Not logged in");
        FirebaseAuth.instance.signOut();
        return LoginScreen();
      },
    );
  }
}
