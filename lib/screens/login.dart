import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscureText = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _errorMessage = "";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    //2021831031@student.sust.edu

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      print("sign in successful");

      if (user != null) {
        if (user.emailVerified) {
          // Email is verified
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Login Successful!")));
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("Email Not Verified"),
                content: Text(
                  "Your email is not verified. Please verify it to continue.",
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      try {
                        User? user = await FirebaseAuth.instance.currentUser;
                        await user?.reload();
                        print(user);
                        if (user != null && !user.emailVerified) {
                          print(UserCredential);
                          try {
                            await user.sendEmailVerification();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Verification email sent. Check your inbox.",
                                ),
                              ),
                            );
                            await FirebaseAuth.instance.signOut();
                            print("signout after sending email");

                            Navigator.pop(context);
                          }
                          // Close dialog
                          catch (e) {
                            print(
                              "Error sending verification email: ${e.toString()}",
                            );
                            Navigator.pop(context); // Close dialog
                            await FirebaseAuth.instance.signOut();
                            print("signout after failing to send email");
                          }
                        }
                      } catch (e) {
                        Navigator.pop(context);
                        print(
                          "Failed to send verification email.${e.toString()}",
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Failed to send verification email.${e.toString()}",
                            ),
                          ),
                        );
                        await FirebaseAuth.instance.signOut();
                        print("signout after failing get the user");
                      }
                    },
                    child: Text("Verify Email"),
                  ),
                  TextButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pop(context);
                    },
                    child: Text("Cancel"),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      print("sign in not successful");
      if (e is FirebaseAuthException) {
        debugPrint(
          "Firebase Auth Error Code: ${e.code}, Message: ${e.message}",
        );

        setState(() {
          _errorMessage =
              "If you're new, SignUp or Did you forget your password?";
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage)));
      } else {
        setState(() {
          _errorMessage = "Unexpected Error: ${e.toString()}";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login With SUST Email"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, "/");
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 100),
            SizedBox(height: 20),
            Text(
              "Login",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              focusNode: _emailFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              controller: _emailController,
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
            ),
            SizedBox(height: 20),
            TextField(
              focusNode: _passwordFocus,
              controller: _passwordController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                _passwordFocus.unfocus();
              },
              obscureText: _obscureText,
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
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 20),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ForgotPasswordScreen(),
                    ),
                  );
                },
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: _login,
              child: Text("Login"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.blue,
              ),
            ),

            SizedBox(height: 10),

            Text("Don't have an account?"),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, "/signup");
              },
              child: Text("Sign Up", style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }
}
