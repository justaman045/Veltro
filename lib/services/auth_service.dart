import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Use the new singleton pattern required by google_sign_in 7.2.0
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Stream exposed for Riverpod to listen to Auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current User
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Initialize the singleton
      await _googleSignIn.initialize();
      
      // 2. Trigger the new authentication flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email']
      ); // User canceled the sign-in

      // 3. Extract tokens
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }

  Future<UserCredential> registerWithEmailPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await user.delete();
        await _googleSignIn.signOut();
      } catch (e) {
        // App Store rules dictate developers must guide users on credential errors
        throw Exception('Account deletion failed: $e. You may need to log out and log back in to verify your identity before deleting.');
      }
    }
  }

  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
