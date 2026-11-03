import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../env.dart';
import '../models.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  static Future<void> _saveProfile(User u, {String? name}) {
    return FirebaseFirestore.instance.collection('users').doc(u.uid).set({
      'name': name ?? u.displayName ?? (u.email ?? 'Friend').split('@').first,
      'email': u.email,
      'photoUrl': u.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> signUp(String name, String email, String password) async {
    final c = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    await c.user!.updateDisplayName(name.trim());
    await _saveProfile(c.user!, name: name.trim());
  }

  static Future<void> signIn(String email, String password) async {
    final c = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    await _saveProfile(c.user!);
  }

  static Future<void> google() async {
    final g = GoogleSignIn(
      scopes: const ['email'],
      serverClientId: Env.hasGoogleClientId ? Env.googleWebClientId : null,
    );
    final acc = await g.signIn();
    if (acc == null) throw PvError('Google sign-in was cancelled.');
    final a = await acc.authentication;
    final cred = GoogleAuthProvider.credential(accessToken: a.accessToken, idToken: a.idToken);
    final c = await _auth.signInWithCredential(cred);
    await _saveProfile(c.user!);
  }

  static Future<void> apple() async {
    final c = await _auth.signInWithProvider(AppleAuthProvider());
    await _saveProfile(c.user!);
  }

  static Future<void> resetPassword(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  static Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  /// Turns Firebase error codes into plain language.
  static String friendly(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'That email address does not look right.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email or password is incorrect.';
        case 'email-already-in-use':
          return 'An account with this email already exists. Try logging in.';
        case 'weak-password':
          return 'Choose a password with at least 6 characters.';
        case 'network-request-failed':
          return 'No internet connection. Check your network and retry.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled in Firebase Authentication.';
        case 'too-many-requests':
          return 'Too many attempts. Wait a few minutes and try again.';
        default:
          return e.message ?? 'Sign-in failed (${e.code}).';
      }
    }
    final s = e.toString();
    if (s.contains('ApiException: 10') || s.contains('sign_in_failed')) {
      return 'Google sign-in is not configured for this app. Add your SHA-1 key and Web client ID (see README, Step 1).';
    }
    return s.replaceFirst('Exception: ', '');
  }
}
