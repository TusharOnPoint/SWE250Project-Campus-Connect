import 'package:flutter/material.dart';

class StatefulPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  const StatefulPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
  });

  @override
  _StatefulPasswordFieldState createState() => _StatefulPasswordFieldState();
}

class _StatefulPasswordFieldState extends State<StatefulPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscureText = !_obscureText),
        ),
      ),
      validator: widget.validator,
    );
  }
}
