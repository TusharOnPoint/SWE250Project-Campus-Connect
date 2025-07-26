import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:campus_connect/screens/login.dart';

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
  final _confirmPasswordFocus = FocusNode();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureText = true;
  bool _isSigningUp = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@student\.sust\.edu$").hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  bool _isStrongPassword(String password) {
    return password.length >= 6 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password) &&
        RegExp(r'[^a-zA-Z0-9]').hasMatch(password);
  }

  // break _signUp() into:

  // _validateInputs() → handles input checks and returns early if any fail.

  // _isEmailAlreadyRegistered(email) → checks if email is taken.

  // _createUserAccount() → wraps Firebase account creation.

  // _saveUserToFirestore() → stores user info.

  // _showVerificationDialog() → shows the email verification alert.

  bool _validateInputs(
    String username,
    String email,
    String password,
    String confirmPassword,
  ) {
    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar("Please fill all fields");
      return false;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar("Only SUST email addresses are allowed");
      return false;
    }

    if (password != confirmPassword) {
      _showSnackBar("Passwords do not match");
      return false;
    }

    if (!_isStrongPassword(password)) {
      _showSnackBar(
        "Password must contain uppercase, lowercase, number and special character",
      );
      return false;
    }

    if (!_isValidPassword(password)) {
      _showSnackBar("Password must be at least 6 characters");
      return false;
    }

    return true;
  }

  Future<bool> _isEmailAlreadyRegistered(String email) async {
    final methods = await _auth.fetchSignInMethodsForEmail(email);
    return methods.isNotEmpty;
  }

  Future<void> _handleExistingUserFlow() async {
    setState(() => _isSigningUp = false);
    _showSnackBar("Already Signed Up. Log In Now");
    await Future.delayed(Duration(seconds: 1));
    if (mounted) {
      Navigator.pushReplacementNamed(context, 'login');
    }
  }

  Future<UserCredential> _createUserAccount(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> _saveUserToFirestore(String uid, String username, String email) {
    return _firestore.collection("users").doc(uid).set({
      "username": username,
      "email": email,
      "uid": uid,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text("Verify Your Email"),
            content: Text(
              "A verification link has been sent to your email. Please verify to continue.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _auth.signOut();
                  Navigator.popAndPushNamed(context, "/login");
                },
                child: Text("Go to Login"),
              ),
            ],
          ),
    );
  }

  void _handleFirebaseError(FirebaseAuthException e) async {
    setState(() => _isSigningUp = false);

    String errorMessage = switch (e.code) {
      'email-already-in-use' => "Already Signed Up. Log In Now",
      'weak-password' => "Password is too weak.",
      'invalid-email' => "Invalid email format.",
      _ => "Signup failed. Please try again.",
    };

    _showSnackBar(errorMessage);

    if (e.code == 'email-already-in-use') {
      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      }
    }
  }

  void _handleGenericError(String message) {
    setState(() => _isSigningUp = false);
    _showSnackBar(message);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (!_validateInputs(username, email, password, confirmPassword)) return;

    setState(() => _isSigningUp = true);

    try {
      final alreadyRegistered = await _isEmailAlreadyRegistered(email);
      if (alreadyRegistered) {
        await _handleExistingUserFlow();
        return;
      }

      final userCredential = await _createUserAccount(email, password);
      final user = userCredential.user;

      if (user != null) {
        await user.sendEmailVerification();
        await _saveUserToFirestore(user.uid, username, email);
        setState(() => _isSigningUp = false);
        _showVerificationDialog();
      } else {
        _handleGenericError("Signup failed. Please try again.");
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } catch (e) {
      _handleGenericError("Signup failed: ${e.toString()}");
    }
  }

  InputDecoration _buildInputDecoration(
    String labelText, {
    bool isPassword = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue, width: 2.0),
      ),
      suffixIcon:
          isPassword
              ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
              : null,
    );
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
            Text(
              "Sign Up",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              focusNode: _userNameFocus,
              onSubmitted: (_) => _emailFocus.requestFocus(),
              textInputAction: TextInputAction.next,
              decoration: _buildInputDecoration("Username"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              focusNode: _emailFocus,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              textInputAction: TextInputAction.next,
              decoration: _buildInputDecoration("Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: _obscureText,
              focusNode: _passwordFocus,
              onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
              textInputAction: TextInputAction.next,
              decoration: _buildInputDecoration("Password", isPassword: true),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocus,
              obscureText: _obscureText,
              onSubmitted: (_) => _confirmPasswordFocus.unfocus(),
              textInputAction: TextInputAction.done,
              decoration: _buildInputDecoration(
                "Confirm Password",
                isPassword: true,
              ),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSigningUp ? null : _signUp,
              child:
                  _isSigningUp
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
                Navigator.pushNamed(context, "/login");
              },
              child: Text("Login", style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }
}
