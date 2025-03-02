//import 'package:campusconnect/lib/screens/welcome_screen.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'screens/welcome_screen.dart' show WelcomeScreen;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp();

  //GoogleSignIn googleSignIn = GoogleSignIn(
    //clientId: "216386977487-klji74h7eshu5ooda7dqhq03r7eg6c0a.apps.googleusercontent.com",
  //);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Connect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: WelcomeScreen(), // Start with the Welcome Screen
      debugShowCheckedModeBanner: false,
    );
  }
}
