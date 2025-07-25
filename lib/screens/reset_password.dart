import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/password_field.dart';
import '../utils/password_validators.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool isLoading = false;

  void _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        await _auth.currentUser!.updatePassword(_newPasswordController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password updated successfully.")),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
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
      appBar: AppBar(title: const Text("Set New Password")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("Enter a strong new password:", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              StatefulPasswordField(
                controller: _newPasswordController,
                label: "New Password",
                validator: validatePassword,
              ),
              const SizedBox(height: 20),
              StatefulPasswordField(
                controller: _confirmPasswordController,
                label: "Confirm Password",
                validator: confirmPasswordValidator(_newPasswordController),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading ? null : _updatePassword,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Update Password"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
