import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize();
      final googleUser = await _googleSignIn.authenticate(scopeHint: ['email']);

      // Credential Manager on Android completes Firebase sign-in internally
      // before authenticate() returns. Calling signInWithCredential() again
      // with a stale token would sign the user back out — skip it.
      if (_auth.currentUser != null) return null;

      final idToken = googleUser.authentication.idToken;
      if (idToken == null) throw Exception('Could not retrieve Google credentials.');

      return await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('canceled') || msg.contains('cancelled')) {
        return null;
      }
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
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          throw Exception('requires-recent-login');
        }
        throw Exception('Account deletion failed: ${e.message}');
      } catch (e) {
        throw Exception('Account deletion failed: $e');
      }
    }
  }

  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception('No authenticated user');
    final credential = EmailAuthProvider.credential(email: user.email!, password: password);
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> reauthenticateWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');
    await _googleSignIn.initialize();
    final googleUser = await _googleSignIn.authenticate(scopeHint: ['email']);
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) throw Exception('Could not retrieve Google credentials.');
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await user.reauthenticateWithCredential(credential);
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
