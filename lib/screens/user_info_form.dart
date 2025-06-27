import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserInfoForm extends StatefulWidget {
  const UserInfoForm({super.key});

  @override
  State<UserInfoForm> createState() => _UserInfoFormState();
}

class _UserInfoFormState extends State<UserInfoForm> {
  final _formKey = GlobalKey<FormState>();

  String? name;
  String? gender;
  String? department;
  String? course;
  String? year;
  String? semester;
  String? university;
  String? skills;
  String? workplace;

  final List<String> genders = ['Male', 'Female', 'Other'];
  final List<String> departments = ['CSE', 'EEE', 'BBA', 'LLB'];
  final List<String> courses = ['Bachelors', 'Masters'];
  final List<String> years = ['1st', '2nd', '3rd', '4th'];
  final List<String> semesters = ['1st', '2nd'];
  final List<String> universities = ['BUET', 'DU', 'NSU', 'BRAC', 'RUET'];

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'name': name,
          'gender': gender,
          'department': department,
          'course': course,
          'year': year,
          'semester': semester,
          'university': university,
          'skills': skills,
          'workplace': workplace,
          'isProfileUpdated': true,
        });

        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(label: 'Name', onSaved: (val) => name = val),
              _buildDropdown(label: 'Gender', items: genders, onChanged: (val) => gender = val),
              _buildDropdown(label: 'Department', items: departments, onChanged: (val) => department = val),
              _buildDropdown(label: 'Course', items: courses, onChanged: (val) => course = val),
              Row(
                children: [
                  Expanded(child: _buildDropdown(label: 'Year', items: years, onChanged: (val) => year = val)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdown(label: 'Semester', items: semesters, onChanged: (val) => semester = val)),
                ],
              ),
              _buildDropdown(label: 'University', items: universities, onChanged: (val) => university = val),
              _buildTextField(label: 'Skills', onSaved: (val) => skills = val),
              _buildTextField(label: 'Workplace', onSaved: (val) => workplace = val),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  OutlinedButton(onPressed: _skip, child: const Text('Skip')),
                  ElevatedButton(onPressed: _submitForm, child: const Text('Done')),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required void Function(String?) onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Please select $label' : null,
      ),
    );
  }
}
