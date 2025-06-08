import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyD5IamorPxL1mW-nEApEscDdBlUAo8F-Sw",
        appId: "1:76015765405:web:4d27ffb2bd0bc4fa211174",
        messagingSenderId: "76015765405",
        projectId: "campusconnect-a1399",
      ),
    );
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Connect',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
