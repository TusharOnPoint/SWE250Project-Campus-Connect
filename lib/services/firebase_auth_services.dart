import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService{
  FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user
  User? get currentUser => _auth.currentUser;

  Future<User?>signUpWithEmailAndPassword(String email,String password) async{
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } catch (e){
      print("some error occured");
    }
    return null;
  }

  Future<User?>SignInWithEmailAndPassword(String email,String password) async{
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } catch (e){
      print("some error occured");
    }
    return null;
  }

  // Logout (sign out)
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print("User signed out");
    } catch (e) {
      print("Error signing out: $e");
      rethrow;
    }
  }
}