import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/learning_models.dart';
import 'database_seed_service.dart';

class LearningService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String normalizeLanguageId(String? value) {
    final raw = (value ?? '').trim().toLowerCase();
    if (raw.contains('batak') || raw.contains('toba')) return 'batak_toba';
    if (raw.contains('jawa')) return 'jawa';
    if (raw.contains('sunda')) return 'sunda';

    return 'sunda';
  }

  Future<void> seedInitialContent() async {
    await DatabaseSeedService.instance.seedSundaDatabase();
  }

  Future<String> getCurrentUserLanguageId() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return 'sunda';
    }

    final userDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();

    final userData = userDoc.data() ?? <String, dynamic>{};

    return normalizeLanguageId(
      userData['selectedLanguageId']?.toString() ??
          userData['selectedLanguage']?.toString() ??
          userData['languageId']?.toString(),
    );
  }

  Future<LessonData> getLesson({
    String? languageId,
    int levelNo = 1,
  }) async {
    final selectedLanguageId = normalizeLanguageId(
      languageId ?? await getCurrentUserLanguageId(),
    );

    final languageRef =
        _firestore.collection('languages').doc(selectedLanguageId);

    final languageSnapshot = await languageRef.get();
    final languageData = languageSnapshot.data() ?? <String, dynamic>{};

    final languageName =
        languageData['name']?.toString() ?? _languageNameFromId(selectedLanguageId);

    final region = languageData['region']?.toString() ?? '';

    final levelId = '${selectedLanguageId}_level_$levelNo';

    final directLevelSnapshot =
        await languageRef.collection('levels').doc(levelId).get();

    Map<String, dynamic>? levelData;

    if (directLevelSnapshot.exists) {
      levelData = directLevelSnapshot.data();
    } else {
      final querySnapshot = await languageRef
          .collection('levels')
          .where('levelNo', isEqualTo: levelNo)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        levelData = querySnapshot.docs.first.data();
      }
    }

    if (levelData == null) {
      throw Exception(
        'Level $levelNo untuk bahasa $selectedLanguageId belum tersedia di Firestore.',
      );
    }

    final vocabularyIds = _stringList(levelData['vocabularyIds']);

    final items = await _getLessonItems(
      languageId: selectedLanguageId,
      vocabularyIds: vocabularyIds,
    );

    return LessonData.fromMap({
      ...levelData,
      'languageId': selectedLanguageId,
      'languageName': languageName,
      'region': region,
      'items': items.map((item) => item.toMap()).toList(),
    });
  }

  Future<List<LessonItem>> _getLessonItems({
    required String languageId,
    required List<String> vocabularyIds,
  }) async {
    if (vocabularyIds.isEmpty) return [];

    final dictionaryRef = _firestore
        .collection('languages')
        .doc(languageId)
        .collection('dictionary');

    final items = <LessonItem>[];

    for (final vocabularyId in vocabularyIds) {
      final snapshot = await dictionaryRef.doc(vocabularyId).get();

      if (!snapshot.exists) continue;

      final data = snapshot.data();

      if (data == null) continue;

      items.add(
        LessonItem.fromDictionaryMap(data),
      );
    }

    return items;
  }

  static const String _backendUrl = 'https://lokago-backend.vercel.app';

  Future<String> _getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User belum login.');
    final token = await user.getIdToken();
    if (token == null) throw Exception('Gagal mengambil token autentikasi.');
    return token;
  }

  Future<Map<String, int>> getUserHearts() async {
    return syncDailyHearts();
  }

  /// Dipanggil setiap kali user menjawab salah di quiz, supaya kerugian
  /// heart langsung tersimpan real-time (tidak hilang kalau user keluar
  /// dari kuis sebelum selesai).
  Future<Map<String, int>> deductHeartForWrongAnswer() async {
    final token = await _getIdToken();

    final response = await http.post(
      Uri.parse('$_backendUrl/api/deduct-heart'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengurangi heart: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {
      'hearts': (data['hearts'] as num).toInt(),
      'maxHearts': (data['maxHearts'] as num).toInt(),
    };
  }

  Future<Map<String, int>> syncDailyHearts() async {
    try {
      final token = await _getIdToken();

      final response = await http.post(
        Uri.parse('$_backendUrl/api/sync-daily-hearts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal sinkronisasi heart: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'hearts': (data['hearts'] as num).toInt(),
        'maxHearts': (data['maxHearts'] as num).toInt(),
      };
    } catch (_) {
      return {'hearts': 5, 'maxHearts': 15};
    }
  }

  Future<LessonCompletionResult> completeLesson({
    required LessonData lesson,
    required int correctCount,
    required int totalQuestions,
    bool? forcePassed,
    int? heartsLostOverride,
    int? heartsLostForDisplayOverride,
    int? scorePctOverride,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User belum login.');
    }

    final uid = currentUser.uid;

    final userRef = _firestore.collection('users').doc(uid);

    final languageProgressRef =
        userRef.collection('languageProgress').doc(lesson.languageId);

    final progressRef =
        _firestore.collection('userProgress').doc('${uid}_${lesson.id}');

    final calculatedScorePct = totalQuestions == 0
        ? 0
        : ((correctCount / totalQuestions) * 100).round();

    final scorePct = scorePctOverride ?? calculatedScorePct;

    final wrongCount = heartsLostOverride ??
        math.max(0, totalQuestions - correctCount);

    final isPassed = forcePassed ?? scorePct >= lesson.requiredScore;

    final baseXp = isPassed
        ? lesson.xpReward
        : math.max(1, (lesson.xpReward / 2).round());

    final earnedBadgeId = isPassed
        ? _badgeIdForCompletedLevel(
            languageId: lesson.languageId,
            levelNo: lesson.levelNo,
          )
        : null;

    return _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final languageProgressSnapshot =
          await transaction.get(languageProgressRef);

      final userData = userSnapshot.data() ?? <String, dynamic>{};
      final languageProgressData =
          languageProgressSnapshot.data() ?? <String, dynamic>{};

      final completedLessonIds = _stringList(
        languageProgressData['completedLessonIds'] ??
            userData['completedLessons'],
      );

      final completedLevels = _intList(
        languageProgressData['completedLevels'],
      );

      final alreadyCompleted = completedLessonIds.contains(lesson.id);

      final xpEarned = alreadyCompleted ? 0 : baseXp;

      final currentLevel = _readInt(
        languageProgressData['currentLevel'],
        0,
      );

      final maxUnlockedLevel = _readInt(
        languageProgressData['maxUnlockedLevel'],
        1,
      );

      final now = DateTime.now();
      final today = _dateKey(now);

      final heartSync = _calculateDailyHeartSync(
        userData: userData,
        now: now,
      );

      final currentHearts = heartSync.hearts;
      final maxHearts = heartSync.maxHearts;

      final heartsLostForDisplay = alreadyCompleted
          ? 0
          : (heartsLostForDisplayOverride ?? heartsLostOverride ?? wrongCount);

      final currentStreak = _readInt(
        userData['streakDays'],
        0,
      );

      final shouldUpdateStreak = isPassed && !alreadyCompleted;

      final newStreak = _calculateNewStreak(
        currentStreak: currentStreak,
        lastStudyDateValue: userData['lastStudyDate'],
        now: now,
        shouldUpdateStreak: shouldUpdateStreak,
      );

      final userUpdate = <String, dynamic>{
        'email': currentUser.email ?? userData['email']?.toString() ?? '',
        'name': userData['name']?.toString() ??
            currentUser.displayName ??
            'Bubi',
        'selectedLanguageId': lesson.languageId,
        'totalXp': FieldValue.increment(xpEarned),
        'streakDays': newStreak,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (heartSync.shouldWriteDailyHeartFields) {
        userUpdate['lastHeartRefillDate'] = heartSync.lastHeartRefillDate;
      }

      if (shouldUpdateStreak) {
        userUpdate['lastStudyDate'] = today;
      }

      if (earnedBadgeId != null) {
        userUpdate['earnedBadgeIds'] = FieldValue.arrayUnion([earnedBadgeId]);

        final currentDisplayBadgeId =
            (userData['displayBadgeId'] ?? '').toString().trim();

        if (currentDisplayBadgeId.isEmpty) {
          userUpdate['displayBadgeId'] = earnedBadgeId;
        }
      }

      final languageProgressUpdate = <String, dynamic>{
        'languageId': lesson.languageId,
        'languageName': lesson.languageName,
        'unitNo': lesson.unitNo,
        'lastOpenedLevel': lesson.levelNo,
        'lastOpenedLessonId': lesson.id,
        'totalXp': FieldValue.increment(xpEarned),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isPassed) {
        final newCurrentLevel = math.max(currentLevel, lesson.levelNo);

        final newMaxUnlockedLevel = math.min(
          30,
          math.max(maxUnlockedLevel, lesson.levelNo + 1),
        );

        final newCompletedLevels = {
          ...completedLevels,
          lesson.levelNo,
        }.toList()
          ..sort();

        userUpdate['completedLessons'] = FieldValue.arrayUnion([lesson.id]);

        languageProgressUpdate.addAll({
          'currentLevel': newCurrentLevel,
          'maxUnlockedLevel': newMaxUnlockedLevel,
          'completedLevels': newCompletedLevels,
          'completedLessonIds': FieldValue.arrayUnion([lesson.id]),
          'lastCompletedLessonId': lesson.id,
          'lastCompletedAt': FieldValue.serverTimestamp(),
        });
      } else {
        languageProgressUpdate.addAll({
          'currentLevel': currentLevel,
          'maxUnlockedLevel': maxUnlockedLevel,
          'completedLevels': completedLevels,
        });
      }

      transaction.set(
        userRef,
        userUpdate,
        SetOptions(merge: true),
      );

      transaction.set(
        languageProgressRef,
        languageProgressUpdate,
        SetOptions(merge: true),
      );

      transaction.set(
        progressRef,
        {
          'uid': uid,
          'lessonId': lesson.id,
          'languageId': lesson.languageId,
          'languageName': lesson.languageName,
          'unitNo': lesson.unitNo,
          'levelNo': lesson.levelNo,
          'scorePct': scorePct,
          'requiredScore': lesson.requiredScore,
          'isPassed': isPassed,
          'correctCount': correctCount,
          'totalQuestions': totalQuestions,
          'xpEarned': xpEarned,
          'alreadyCompleted': alreadyCompleted,
          'heartsLost': heartsLostForDisplay,
          'heartsRemaining': currentHearts,
          'streakDays': newStreak,
          'submittedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return LessonCompletionResult(
        correctCount: correctCount,
        totalQuestions: totalQuestions,
        scorePct: scorePct,
        xpEarned: xpEarned,
        streakDays: newStreak,
        alreadyCompleted: alreadyCompleted,
        isPassed: isPassed,
        heartsRemaining: currentHearts,
        maxHearts: maxHearts,
        heartsLost: heartsLostForDisplay,
      );
    });
  }

  String? _badgeIdForCompletedLevel({
    required String languageId,
    required int levelNo,
  }) {
    if (levelNo == 5 || levelNo == 15 || levelNo == 30) {
      return '${languageId}_level_$levelNo';
    }

    return null;
  }

  _HeartSyncResult _calculateDailyHeartSync({
    required Map<String, dynamic> userData,
    required DateTime now,
  }) {
    const maxHearts = 15;
    const dailyRefillAmount = 5;

    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _dateKey(today);

    final storedMaxHearts = _readInt(userData['maxHearts'], maxHearts);
    final rawHearts = _readInt(userData['hearts'], 5);

    int hearts = rawHearts.clamp(0, maxHearts).toInt();

    final lastRefillDateValue = userData['lastHeartRefillDate'];
    final lastRefillDate = _parseDateKey(lastRefillDateValue);

    bool shouldWrite = storedMaxHearts != maxHearts ||
        lastRefillDateValue == null ||
        lastRefillDateValue.toString().trim().isEmpty;

    if (lastRefillDate == null) {
      return _HeartSyncResult(
        hearts: hearts,
        maxHearts: maxHearts,
        lastHeartRefillDate: todayKey,
        shouldWriteDailyHeartFields: true,
      );
    }

    final lastDateOnly = DateTime(
      lastRefillDate.year,
      lastRefillDate.month,
      lastRefillDate.day,
    );

    final dayDifference = today.difference(lastDateOnly).inDays;

    if (dayDifference > 0) {
      hearts = math.min(
        maxHearts,
        hearts + (dayDifference * dailyRefillAmount),
      );

      shouldWrite = true;
    } else if (dayDifference < 0) {
      shouldWrite = true;
    }

    return _HeartSyncResult(
      hearts: hearts,
      maxHearts: maxHearts,
      lastHeartRefillDate: todayKey,
      shouldWriteDailyHeartFields: shouldWrite,
    );
  }

  int _calculateNewStreak({
    required int currentStreak,
    required dynamic lastStudyDateValue,
    required DateTime now,
    required bool shouldUpdateStreak,
  }) {
    if (!shouldUpdateStreak) {
      return currentStreak;
    }

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastStudyDate = _parseDateKey(lastStudyDateValue);

    if (lastStudyDate == null) {
      return 1;
    }

    final lastDateOnly = DateTime(
      lastStudyDate.year,
      lastStudyDate.month,
      lastStudyDate.day,
    );

    if (lastDateOnly == today) {
      return currentStreak == 0 ? 1 : currentStreak;
    }

    if (lastDateOnly == yesterday) {
      return currentStreak + 1;
    }

    return 1;
  }

  DateTime? _parseDateKey(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      final date = value.toDate();

      return DateTime(date.year, date.month, date.day);
    }

    final text = value.toString().trim();

    final parts = text.split('-');
    if (parts.length != 3) return null;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) return null;

    final parsed = DateTime(year, month, day);

    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }

    return parsed;
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _languageNameFromId(String languageId) {
    if (languageId == 'jawa') return 'Bahasa Jawa';
    if (languageId == 'madura') return 'Bahasa Madura';
    if (languageId == 'bali') return 'Bahasa Bali';

    return 'Bahasa Sunda';
  }

  int _readInt(dynamic value, int fallback) {
    if (value is int) return value;

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return [];

    return value
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toSet()
        .toList();
  }

  List<int> _intList(dynamic value) {
    if (value is! List) return [];

    return value
        .map((item) => int.tryParse(item.toString()))
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();
  }
}

class _HeartSyncResult {
  const _HeartSyncResult({
    required this.hearts,
    required this.maxHearts,
    required this.lastHeartRefillDate,
    required this.shouldWriteDailyHeartFields,
  });

  final int hearts;
  final int maxHearts;
  final String lastHeartRefillDate;
  final bool shouldWriteDailyHeartFields;
}