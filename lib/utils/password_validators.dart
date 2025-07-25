import 'package:flutter/material.dart';

String? validatePassword(String? password) {
  if (password == null || password.isEmpty) return 'Enter a password';

  final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
  final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
  final hasDigit = RegExp(r'\d').hasMatch(password);
  final hasSpecialChar = RegExp(r'[^a-zA-Z0-9]').hasMatch(password);
  final hasMinLength = password.length >= 8;

  if (!hasUppercase || !hasLowercase || !hasDigit || !hasSpecialChar || !hasMinLength) {
    return 'Password must contain:\n- Uppercase\n- Lowercase\n- Number\n- Special character\n- Min 8 characters';
  }

  return null;
}

String? Function(String?) confirmPasswordValidator(TextEditingController originalController) {
  return (value) {
    final base = validatePassword(value);
    if (base != null) return base;
    if (value != originalController.text) return "Passwords do not match";
    return null;
  };
}
