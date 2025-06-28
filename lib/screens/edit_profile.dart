import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _workplaceController = TextEditingController();
  final TextEditingController _hobbiesController = TextEditingController();
  final TextEditingController _achievementsController = TextEditingController();

  String? department;
  String? course;
  String? year;
  String? semester;

  final List<String> departments = ['SWE', 'CSE', 'EEE', 'BBA', 'LLB'];
  final List<String> courses = ['Bachelors', 'Masters'];
  final List<String> years = ['1st', '2nd', '3rd', '4th'];
  final List<String> semesters = ['1st', '2nd','3rd'];
  final List<String> universities = ['SUST', 'BUET', 'DU', 'NSU', 'BRAC', 'RUET'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _dobController.text = data['dob'] ?? '';
          _universityController.text = data['university'] ?? '';
          _workplaceController.text = data['workplace'] ?? '';
          _hobbiesController.text = data['hobbies'] ?? '';
          _achievementsController.text = data['achievements'] ?? '';
          department = data['department'];
          course = data['course'];
          year = data['year'];
          semester = data['semester'];
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'name': _nameController.text,
        'dob': _dobController.text,
        'university': _universityController.text,
        'workplace': _workplaceController.text,
        'hobbies': _hobbiesController.text,
        'achievements': _achievementsController.text,
        'department': department,
        'course': course,
        'year': year,
        'semester': semester,
      });
      Navigator.pop(context);
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Edit Profile"),
        elevation: 10,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _selectDate,
              child: AbsorbPointer(
                child: TextField(
                  controller: _dobController,
                  decoration: InputDecoration(
                    labelText: "Date of Birth",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildDropdown(
              label: 'Department',
              value: department,
              items: departments,
              onChanged: (val) => setState(() => department = val),
            ),
            _buildDropdown(
              label: 'Course',
              value: course,
              items: courses,
              onChanged: (val) => setState(() => course = val),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Year',
                    value: year,
                    items: years,
                    onChanged: (val) => setState(() => year = val),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Semester',
                    value: semester,
                    items: semesters,
                    onChanged: (val) => setState(() => semester = val),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildDropdown(
              label: 'University',
              value: _universityController.text.isEmpty ? null : _universityController.text,
              items: universities,
              onChanged: (val) => setState(() => _universityController.text = val ?? ''),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _workplaceController,
              decoration: InputDecoration(
                labelText: "Workplace",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _hobbiesController,
              decoration: InputDecoration(
                labelText: "Hobbies",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _achievementsController,
              decoration: InputDecoration(
                labelText: "Achievements",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
