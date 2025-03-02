import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  // final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;

  CustomTextField({
    // required this.controller,
    required this.hintText,
    required this.icon,
    this.isPassword = false, required TextEditingController controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      //controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}