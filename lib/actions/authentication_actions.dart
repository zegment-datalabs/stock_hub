import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';


Future<String?> resetPassword(String email) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    return null; // Successful reset
  } catch (e) {
    return e.toString(); // Return error message
  }
}

Future<String?> loginUser(String email, String password) async {
  try {
    final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final User? user = userCredential.user;

    if (user != null && user.emailVerified) {
      final userId = user.uid;

      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();

      String userName = "User"; 
      String profileImageUrl = "";

      if (userDoc.exists) {
        userName = userDoc['name'] ?? "User"; 
        profileImageUrl = userDoc['profileImageUrl'] ?? "";
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('emailOrphone', user.email ?? '');
      await prefs.setString('name', userName);
      await prefs.setString('profilePicPath', profileImageUrl);

      return null;  // Login Success
    } else {
      if (user != null) {
        await user.sendEmailVerification();
      }
      return "Email not verified.";
    }
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      return 'No user found for that email.';
    } else if (e.code == 'wrong-password') {
      return 'Incorrect password.';
    }
    return 'An error occurred. Please try again.';
  }
}
