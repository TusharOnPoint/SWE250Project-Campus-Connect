import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = "Abdul Kuddus";
  String university = "Dhaka University";
  String workplace = "Software Engineer at ABC Tech";
  String hobbies = "Football, Reading, Coding";
  String achievements = "Hackathon Winner 2023";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Profile")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Name", name, (val) => name = val),
              _buildTextField("University", university, (val) => university = val),
              _buildTextField("Workplace", workplace, (val) => workplace = val),
              _buildTextField("Hobbies", hobbies, (val) => hobbies = val),
              _buildTextField("Achievements", achievements, (val) => achievements = val),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    Navigator.pop(context);
                  }
                },
                child: Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String initialValue, Function(String) onSaved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        onSaved: (val) => onSaved(val!),
      ),
    );
  }
}
