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

  final user = userCredential.user;

  if (user != null) {
    await _ensureUserDocument(
      user,
      provider: 'email',
    );
  }

  return userCredential;
}

  Future<UserCredential> signInWithEmail({
  required String email,
  required String password,
}) async {
  final userCredential = await _auth.signInWithEmailAndPassword(
    email: email,
    password: password,
  );

  final user = userCredential.user;

  if (user != null) {
    await _ensureUserDocument(
      user,
      provider: 'email',
    );
  }

  return userCredential;
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

    await _ensureUserDocument(
  user,
  provider: 'google',
);

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

  Future<void> _ensureUserDocument(
  User user, {
  String provider = 'email',
}) async {
  final userRef = _firestore.collection('users').doc(user.uid);
  final userDoc = await userRef.get();

  if (!userDoc.exists) {
    await userRef.set({
      'email': user.email ?? '',
      'name': user.displayName ?? '',
      'birthDate': null,
      'selectedLanguageId': 'sunda',
      'selectedLanguage': 'Bahasa Sunda',
      'hearts': 5,
      'maxHearts': 5,
      'streakDays': 0,
      'lastStudyDate': null,
      'earnedBadgeIds': [],
      'displayBadgeId': null,
      'notificationSettings': {
        'dailyReminder': true,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await userRef.collection('languageProgress').doc('sunda').set({
      'languageId': 'sunda',
      'currentLevel': 0,
      'maxUnlockedLevel': 1,
      'completedLevels': [],
      'totalXp': 0,
      'lastCompletedLevel': null,
      'lastStudiedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  } else {
    await userRef.set({
      'email': user.email ?? '',
      'name': user.displayName ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
}