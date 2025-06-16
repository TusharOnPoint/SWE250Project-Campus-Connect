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

        // User is logged in
        if (snapshot.hasData) {
          print("Logged in already");
          return HomeScreen();
        }

        // User is NOT logged in
        print("not Logged in already");
        return LoginScreen();
      },
    );
  }
}
