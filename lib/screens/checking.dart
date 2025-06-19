
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RootScreen extends StatefulWidget {
  @override
  _RootScreenState createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  void initState() {
    super.initState();
    _handleAuthState();
  }

  void _handleAuthState() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("❌ Not logged in");
      await FirebaseAuth.instance.signOut();
      _navigateTo('/login');
    } else {
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        print("✅ Logged in and email verified");
        _navigateTo('/home');
      } else {
        print("❌ Email not verified");
        //await FirebaseAuth.instance.signOut();
        _navigateTo('/login');
        FirebaseAuth.instance.signOut();
      }
    }

  }

  void _navigateTo(String routeName) {
    print("navigating to ${routeName}");
    Navigator.of(context).pushReplacementNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Campus Connect"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
