import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordScreen extends StatefulWidget {
  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String? _validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Enter a password';
    }

    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSpecialChar = RegExp(r'[^a-zA-Z0-9]').hasMatch(password);
    final hasMinLength = password.length >= 6;

    if (!hasUppercase || !hasLowercase || !hasDigit || !hasSpecialChar || !hasMinLength) {
      return 'Password must contain:\n- Uppercase\n- Lowercase\n- Number\n- Special character\n- Min 8 characters';
    }

    return null;
  }

  void _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        await _auth.currentUser!.updatePassword(_newPasswordController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password updated successfully.")));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set New Password")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text("Enter a strong new password:", style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: "New Password",
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                validator: _validatePassword,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Confirm your password";
                  if (value != _newPasswordController.text) return "Passwords do not match";
                  return null;
                },
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading ? null : _updatePassword,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Update Password"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
