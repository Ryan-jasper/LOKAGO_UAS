import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveOnboarding({
    required String uid,
    required String name,
    required String birthDate,
    required String selectedLanguage,
    required String selectedLevel,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'birthDate': birthDate,
      'selectedLanguage': selectedLanguage,
      'selectedLevel': selectedLevel,
      'onboardingCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}