import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveOnboarding({
    required String uid,
    required String name,
    required String birthDate,
    required String selectedLanguage,
    required String selectedLevel,
  }) async {
    final languageId = _languageIdFromName(selectedLanguage);
    final languageName = _languageNameFromId(languageId);

    final userRef = _db.collection('users').doc(uid);

    await userRef.set(
      {
        'name': name,
        'birthDate': birthDate,
        'selectedLanguageId': languageId,
        'selectedLanguage': languageName,
        'selectedLevel': selectedLevel,
        'hearts': 5,
        'maxHearts': 5,
        'streakDays': 0,
        'earnedBadgeIds': [],
        'displayBadgeId': '',
        'notificationSettings': {
          'studyReminder': true,
          'streakReminder': true,
          'heartReminder': true,
          'badgeNotification': true,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await userRef.collection('languageProgress').doc(languageId).set(
      {
        'languageId': languageId,
        'languageName': languageName,
        'currentLevel': 0,
        'maxUnlockedLevel': 1,
        'completedLevels': <int>[],
        'totalXp': 0,
        'lastCompletedLevel': null,
        'lastStudiedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  String _languageIdFromName(String value) {
    final raw = value.trim().toLowerCase();

    if (raw.contains('batak') || raw.contains('toba')) {
      return 'batak_toba';
    }

    if (raw.contains('jawa')) {
      return 'jawa';
    }

    if (raw.contains('sunda')) {
      return 'sunda';
    }

    return 'sunda';
  }

  String _languageNameFromId(String languageId) {
    if (languageId == 'batak_toba') return 'Bahasa Batak Toba';
    if (languageId == 'jawa') return 'Bahasa Jawa';

    return 'Bahasa Sunda';
  }
}