import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//import 'package:campus_connect/services/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:campus_connect/screens/login.dart';
import 'home.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  //final FirebaseAuthService _auth = FirebaseAuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _isSigningUp = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  Future<void> _signUp() async {
    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter a valid email address")),
      );
      return;
    }

    if (!_isValidPassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    setState(() {
      _isSigningUp = true;
    });

    try {
      List<String> signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

      if (signInMethods.isNotEmpty) {
        setState(() {
          _isSigningUp = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Already Signed Up. Log In Now")),
        );

        await Future.delayed(Duration(seconds: 1)); // Short delay to show message

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection("users").doc(user.uid).set({
          "username": username,
          "email": email,
          "uid": user.uid,
          "createdAt": FieldValue.serverTimestamp(),
        });

        setState(() {
          _isSigningUp = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signup Successful! Redirecting...")),
        );

        await Future.delayed(Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushNamed(
            context,
            "/home",
          );
        }
      } else {
        setState(() {
          _isSigningUp = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signup failed. Please try again.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isSigningUp = false;
      });

      String errorMessage = "Signup failed. Please try again.";
      if (e.code == 'email-already-in-use') {
        errorMessage = "Already Signed Up. Log In Now";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );

        await Future.delayed(Duration(seconds: 1));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
        return;
      } else if (e.code == 'weak-password') {
        errorMessage = "Password is too weak.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email format.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      setState(() {
        _isSigningUp = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up"), backgroundColor: Colors.blue),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 100),
            SizedBox(height: 20),
            Text("Sign Up", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSigningUp ? null : _signUp,
              child: _isSigningUp
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Sign Up"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.blue,
              ),
            ),
            SizedBox(height: 10),
            Text("Already have an account?"),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  "/login",
                );
              },
              child: Text("Login", style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }
}
