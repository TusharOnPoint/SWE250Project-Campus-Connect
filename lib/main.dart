import 'package:campus_connect/services/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyD5IamorPxL1mW-nEApEscDdBlUAo8F-Sw",
        appId: "1:76015765405:web:4d27ffb2bd0bc4fa211174",
        messagingSenderId: "76015765405",
        projectId: "campusconnect-a1399",
      ),
    );
  }else {
    await Firebase.initializeApp();
  }
  runApp(MyApp());
}
//2021831031@student.sust.edu
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Connect',
      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      //home: WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

