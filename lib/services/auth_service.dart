import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _serverClientId =
      '249245937428-llul9cjnvlpko8l3gvru40u235had8gs.apps.googleusercontent.com';

  static bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;

    await GoogleSignIn.instance.initialize(
      serverClientId: _serverClientId,
    );

    _googleInitialized = true;
  }

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user!;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email ?? email,
        'name': user.displayName ?? '',
        'photoUrl': user.photoURL ?? '',
        'provider': 'email',
        'onboardingCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Firestore save failed after signup: $e');
    }

    return userCredential;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email ?? '',
        'name': user.displayName ?? '',
        'photoUrl': user.photoURL ?? '',
        'provider': 'google',
        'onboardingCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Firestore save failed after google sign in: $e');
    }

    return userCredential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> verifyResetCode({
    required String code,
  }) async {
    await _auth.verifyPasswordResetCode(code);
  }

  Future<void> confirmNewPassword({
    required String code,
    required String newPassword,
  }) async {
    await _auth.confirmPasswordReset(
      code: code,
      newPassword: newPassword,
    );
  }
}