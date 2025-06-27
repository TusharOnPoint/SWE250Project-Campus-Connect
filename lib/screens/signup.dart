import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:campus_connect/screens/login.dart';
import 'home.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _userNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

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
    return RegExp(r"^[a-zA-Z0-9._%+-]+@student\.sust\.edu$").hasMatch(email);
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
        SnackBar(content: Text("Only SUST email addresses are allowed")),
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
      List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(email);

      if (signInMethods.isNotEmpty) {
        setState(() {
          _isSigningUp = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Already Signed Up. Log In Now")),
        );

        await Future.delayed(Duration(seconds: 1));

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            'login'
          );
        }
        return;
      }

      UserCredential userCredential =  await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // 🔐 Send email verification
        await user.sendEmailVerification(); // ✅ <--- Added

        await _firestore.collection("users").doc(user.uid).set({
          "username": username,
          "email": email,
          "uid": user.uid,
          "createdAt": FieldValue.serverTimestamp(),
        });

        setState(() {
          _isSigningUp = false;
        });

        // 📨 Notify user to check email
        showDialog( // ✅ <--- Added
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: Text("Verify Your Email"),
              content: Text("A verification link has been sent to your email. Please verify to continue."),
              actions: [
                TextButton(
                  onPressed: () {
                    _auth.signOut();
                    Navigator.popAndPushNamed(context, "/login");
                  },
                  child: Text("Go to Login"),
                )
              ],
            );
          },
        );
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
      appBar: AppBar(
        title: Text("Sign Up With SUST Email"),
        //backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
              focusNode: _userNameFocus,
              onSubmitted:(_) => _emailFocus.requestFocus(),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              focusNode: _emailFocus,
              onSubmitted:(_) => _passwordFocus.requestFocus(),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: _obscureText,
              focusNode: _passwordFocus,
              onSubmitted:(_) => _passwordFocus.unfocus(),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
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
