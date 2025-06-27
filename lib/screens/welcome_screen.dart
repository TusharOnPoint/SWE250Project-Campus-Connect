import 'package:campus_connect/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'login.dart';
class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/welcome_logo.png', height: 150,width:200,),
              SizedBox(height: 20),
              Text(
                "Campus Connect",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 40),
              CustomButton(text: "Get Started", onPressed: (){
                Navigator.pushNamed(
                  context,
                  '/check',
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
