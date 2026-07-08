import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseSeedService {
  DatabaseSeedService._();

  static final DatabaseSeedService instance = DatabaseSeedService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedSundaDatabase() async {
    await _seedLanguage(_sundaSeed());
  }

  Future<void> seedJawaDatabase() async {
    await _seedLanguage(_jawaSeed());
  }

  Future<void> seedBatakTobaDatabase() async {
    await _seedLanguage(_batakTobaSeed());
  }

  Future<void> seedAllDatabases() async {
    await seedSundaDatabase();
    await seedJawaDatabase();
    await seedBatakTobaDatabase();
  }

  Future<void> _seedLanguage(_LanguageSeed language) async {
    final batch = _db.batch();
    final languageRef = _db.collection('languages').doc(language.id);

    batch.set(
      languageRef,
      {
        'id': language.id,
        'name': language.name,
        'nativeName': language.nativeName,
        'region': language.region,
        'country': 'Indonesia',
        'totalLevels': 30,
        'totalUnits': 6,
        'isActive': true,
        'writingSystem': 'Latin',
        'sourceName': language.sourceName,
        'sourceUrl': language.sourceUrl,
        'license': language.license,
        'seedVersion': language.seedVersion,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    for (final unit in language.units) {
      final unitId = '${language.id}_unit_${unit.unitNo}';

      batch.set(
        languageRef.collection('units').doc(unitId),
        {
          'id': unitId,
          'languageId': language.id,
          'unitNo': unit.unitNo,
          'title': unit.title,
          'description': unit.description,
          'startLevel': unit.startLevel,
          'endLevel': unit.endLevel,
          'isActive': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    final dictionaryById = <String, _WordSeed>{};

    for (final unit in language.units) {
      for (final word in unit.allWords) {
        dictionaryById[word.id] = word;
      }
    }

    for (final word in dictionaryById.values) {
      batch.set(
        languageRef.collection('dictionary').doc('${language.id}_${word.id}'),
        word.toDictionaryMap(language),
        SetOptions(merge: true),
      );
    }

    final levels = _buildLevels(language);

    for (final level in levels) {
      final levelId = level['id'].toString();

      batch.set(
        languageRef.collection('levels').doc(levelId),
        {
          ...level,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  List<Map<String, dynamic>> _buildLevels(_LanguageSeed language) {
    final levels = <Map<String, dynamic>>[];

    for (final unit in language.units) {
      final base = unit.startLevel;
      final allWords = unit.allWords;
      final sentenceWords = unit.sentenceVocabularyIds(language.id);

      levels.add(
        _levelMap(
          language: language,
          unit: unit,
          levelNo: base,
          title: unit.level1Title,
          objective:
              'Pengguna mampu mengenali kosakata dasar pada tema ${unit.title}.',
          xpReward: 20,
          vocabularyIds: unit.level1Words.map((w) => '${language.id}_${w.id}').toList(),
          activities: _buildMultipleChoiceActivities(
            language: language,
            unit: unit,
            levelNo: base,
            words: unit.level1Words,
            pool: allWords,
            maxQuestions: 4,
          ),
        ),
      );

      levels.add(
        _levelMap(
          language: language,
          unit: unit,
          levelNo: base + 1,
          title: unit.level2Title,
          objective:
              'Pengguna mampu mencocokkan kosakata ${unit.title} dengan artinya.',
          xpReward: 20,
          vocabularyIds: unit.matchingWords.map((w) => '${language.id}_${w.id}').toList(),
          activities: [
            _buildMatchingActivity(
              language: language,
              unit: unit,
              levelNo: base + 1,
              activityNo: 1,
              words: unit.matchingWords,
            ),
            ..._buildMultipleChoiceActivities(
              language: language,
              unit: unit,
              levelNo: base + 1,
              words: unit.matchingWords,
              pool: allWords,
              maxQuestions: 2,
              startNo: 2,
            ),
          ],
        ),
      );

      levels.add(
        _levelMap(
          language: language,
          unit: unit,
          levelNo: base + 2,
          title: unit.level3Title,
          objective:
              'Pengguna mampu menyusun kalimat sederhana pada tema ${unit.title}.',
          xpReward: 25,
          vocabularyIds: sentenceWords,
          activities: _buildArrangeActivities(
            language: language,
            unit: unit,
            levelNo: base + 2,
            sentences: unit.sentences,
          ),
        ),
      );

      levels.add(
        _levelMap(
          language: language,
          unit: unit,
          levelNo: base + 3,
          title: unit.level4Title,
          objective:
              'Pengguna mampu mengartikan kalimat sederhana pada tema ${unit.title}.',
          xpReward: 25,
          vocabularyIds: sentenceWords,
          activities: _buildTranslateActivities(
            language: language,
            unit: unit,
            levelNo: base + 3,
            sentences: unit.sentences,
          ),
        ),
      );

      levels.add(
        _levelMap(
          language: language,
          unit: unit,
          levelNo: base + 4,
          title: unit.level5Title,
          objective:
              'Pengguna mengulang kosakata, matching, susun kalimat, dan terjemahan pada tema ${unit.title}.',
          xpReward: unit.unitNo == 6 ? 40 : 30,
          vocabularyIds: allWords.map((w) => '${language.id}_${w.id}').toSet().take(12).toList(),
          activities: _buildReviewActivities(
            language: language,
            unit: unit,
            levelNo: base + 4,
          ),
        ),
      );
    }

    return levels;
  }

  Map<String, dynamic> _levelMap({
    required _LanguageSeed language,
    required _UnitSeed unit,
    required int levelNo,
    required String title,
    required String objective,
    required int xpReward,
    required List<String> vocabularyIds,
    required List<Map<String, dynamic>> activities,
  }) {
    final activityTypes = activities
        .map((activity) => activity['type'].toString())
        .toSet()
        .toList();

    return {
      'id': '${language.id}_level_$levelNo',
      'languageId': language.id,
      'unitId': '${language.id}_unit_${unit.unitNo}',
      'unitNo': unit.unitNo,
      'levelNo': levelNo,
      'title': title,
      'theme': unit.title,
      'objective': objective,
      'xpReward': xpReward,
      'requiredScore': 70,
      'vocabularyIds': vocabularyIds,
      'activityTypes': activityTypes,
      'activities': activities,
      'isActive': true,
    };
  }

  List<Map<String, dynamic>> _buildMultipleChoiceActivities({
    required _LanguageSeed language,
    required _UnitSeed unit,
    required int levelNo,
    required List<_WordSeed> words,
    required List<_WordSeed> pool,
    required int maxQuestions,
    int startNo = 1,
  }) {
    final activities = <Map<String, dynamic>>[];
    final selected = words.take(maxQuestions).toList();

    for (int i = 0; i < selected.length; i++) {
      final word = selected[i];
      final activityNo = startNo + i;

      activities.add({
        'id': '${language.id}_l${levelNo}_a$activityNo',
        'type': 'multiple_choice',
        'prompt': "Apa arti dari '${word.local}'?",
        'options': _optionsFor(word, pool),
        'correctAnswer': word.meaning,
        'explanation': '${word.local} berarti ${word.meaning}.',
      });
    }

    return activities;
  }

  Map<String, dynamic> _buildMatchingActivity({
    required _LanguageSeed language,
    required _UnitSeed unit,
    required int levelNo,
    required int activityNo,
    required List<_WordSeed> words,
  }) {
    return {
      'id': '${language.id}_l${levelNo}_a$activityNo',
      'type': 'matching',
      'prompt': 'Cocokkan kata ${language.shortName} dengan artinya.',
      'pairs': words.take(5).map((word) {
        return {
          'left': word.local,
          'right': word.meaning,
        };
      }).toList(),
      'explanation':
          'Matching membantu mengingat hubungan antara kata lokal dan arti Bahasa Indonesia.',
    };
  }

  List<Map<String, dynamic>> _buildArrangeActivities({
    required _LanguageSeed language,
    required _UnitSeed unit,
    required int levelNo,
    required List<_SentenceSeed> sentences,
    int startNo = 1,
  }) {
    final activities = <Map<String, dynamic>>[];

    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i];
      final activityNo = startNo + i;

      activities.add({
        'id': '${language.id}_l${levelNo}_a$activityNo',
        'type': 'arrange_sentence',
        'prompt': 'Susun kata berikut menjadi kalimat yang benar.',
        'words': sentence.words,
        'correctAnswer': sentence.local,
        'translationId': sentence.translation,
        'explanation': '${sentence.local} berarti ${sentence.translation}',
      });
    }

    return activities;
  }

  List<Map<String, dynamic>> _buildTranslateActivities({
    required _LanguageSeed language,
    required _UnitSeed unit,
    required int levelNo,
    required List<_SentenceSeed> sentences,
    int startNo = 1,
  }) {
    final activities = <Map<String, dynamic>>[];

    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i];
      final activityNo = startNo + i;

      activities.add({
        'id': '${language.id}_l${levelNo}_a$activityNo',
        'type': 'translate_sentence',
        'prompt': 'Artikan kalimat berikut ke Bahasa Indonesia.',
        'sentenceLocal': sentence.displayLocal,
        'correctAnswer': sentence.translation,
        'acceptedAnswers': sentence.acceptedAnswers,
        'explanation': '${sentence.displayLocal} berarti ${sentence.translation}',
      });
    }

    return activities;
  }

  List<Map<String, dynamic>> _buildReviewActivities({
    required _LanguageSeed language,
    required _UnitSeed unit,
    required int levelNo,
  }) {
    final allWords = unit.allWords;
    final activities = <Map<String, dynamic>>[];

    activities.add(
      _buildMatchingActivity(
        language: language,
        unit: unit,
        levelNo: levelNo,
        activityNo: 1,
        words: [
          ...unit.level1Words.take(2),
          ...unit.matchingWords.take(3),
        ],
      ),
    );

    activities.addAll(
      _buildMultipleChoiceActivities(
        language: language,
        unit: unit,
        levelNo: levelNo,
        words: [
          ...unit.level1Words.take(1),
          ...unit.matchingWords.take(1),
        ],
        pool: allWords,
        maxQuestions: 2,
        startNo: 2,
      ),
    );

    activities.addAll(
      _buildArrangeActivities(
        language: language,
        unit: unit,
        levelNo: levelNo,
        sentences: unit.sentences.take(2).toList(),
        startNo: 4,
      ),
    );

    activities.addAll(
      _buildTranslateActivities(
        language: language,
        unit: unit,
        levelNo: levelNo,
        sentences: unit.sentences.take(2).toList(),
        startNo: 6,
      ),
    );

    return activities;
  }

  List<String> _optionsFor(_WordSeed correct, List<_WordSeed> pool) {
    final options = <String>[correct.meaning];

    for (final word in pool) {
      if (!options.contains(word.meaning)) {
        options.add(word.meaning);
      }

      if (options.length >= 4) break;
    }

    for (final fallback in _fallbackOptions) {
      if (options.length >= 4) break;
      if (!options.contains(fallback)) {
        options.add(fallback);
      }
    }

    return options.take(4).toList();
  }
}

const _fallbackOptions = [
  'saya',
  'kamu',
  'rumah',
  'makan',
  'sekolah',
  'teman',
  'hari',
  'air',
  'benar',
  'maaf',
];

class _LanguageSeed {
  const _LanguageSeed({
    required this.id,
    required this.name,
    required this.nativeName,
    required this.shortName,
    required this.region,
    required this.sourceName,
    required this.sourceUrl,
    required this.license,
    required this.seedVersion,
    required this.units,
  });

  final String id;
  final String name;
  final String nativeName;
  final String shortName;
  final String region;
  final String sourceName;
  final String sourceUrl;
  final String license;
  final int seedVersion;
  final List<_UnitSeed> units;
}

class _UnitSeed {
  const _UnitSeed({
    required this.unitNo,
    required this.title,
    required this.description,
    required this.level1Title,
    required this.level2Title,
    required this.level3Title,
    required this.level4Title,
    required this.level5Title,
    required this.level1Words,
    required this.matchingWords,
    required this.extraWords,
    required this.sentences,
  });

  final int unitNo;
  final String title;
  final String description;
  final String level1Title;
  final String level2Title;
  final String level3Title;
  final String level4Title;
  final String level5Title;
  final List<_WordSeed> level1Words;
  final List<_WordSeed> matchingWords;
  final List<_WordSeed> extraWords;
  final List<_SentenceSeed> sentences;

  int get startLevel => ((unitNo - 1) * 5) + 1;

  int get endLevel => unitNo * 5;

  List<_WordSeed> get allWords {
    final byId = <String, _WordSeed>{};

    for (final word in [
      ...level1Words,
      ...matchingWords,
      ...extraWords,
    ]) {
      byId[word.id] = word;
    }

    return byId.values.toList();
  }

  List<String> sentenceVocabularyIds(String languageId) {
    final ids = <String>{
      ...level1Words.map((word) => '${languageId}_${word.id}'),
      ...matchingWords.map((word) => '${languageId}_${word.id}'),
      ...extraWords.map((word) => '${languageId}_${word.id}'),
    };

    return ids.take(12).toList();
  }
}

class _WordSeed {
  const _WordSeed({
    required this.id,
    required this.local,
    required this.meaning,
    required this.partOfSpeech,
    required this.topicTags,
    this.type = 'word',
    this.difficulty = 1,
    this.exampleLocal,
    this.exampleId,
  });

  final String id;
  final String local;
  final String meaning;
  final String type;
  final String partOfSpeech;
  final List<String> topicTags;
  final int difficulty;
  final String? exampleLocal;
  final String? exampleId;

  String get normalizedText {
    return local
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('?', '')
        .replaceAll('.', '')
        .trim();
  }

  Map<String, dynamic> toDictionaryMap(_LanguageSeed language) {
    return {
      'id': '${language.id}_$id',
      'languageId': language.id,
      'localText': local,
      'normalizedText': normalizedText,
      'meaningsId': [meaning],
      'primaryMeaningId': meaning,
      'type': type,
      'partOfSpeech': partOfSpeech,
      'topicTags': topicTags,
      'difficulty': difficulty,
      'isCoreVocabulary': true,
      'isLessonEligible': true,
      'exampleLocal': exampleLocal ?? local,
      'exampleId': exampleId ?? meaning,
      'sourceName': language.sourceName,
      'sourceUrl': language.sourceUrl,
      'license': language.license,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class _SentenceSeed {
  const _SentenceSeed({
    required this.words,
    required this.local,
    required this.translation,
    this.displayLocal,
    this.extraAcceptedAnswers = const [],
  });

  final List<String> words;
  final String local;
  final String translation;
  final String? displayLocal;
  final List<String> extraAcceptedAnswers;

  List<String> get acceptedAnswers {
    final withoutPeriod = translation.endsWith('.')
        ? translation.substring(0, translation.length - 1)
        : translation;

    return {
      translation,
      withoutPeriod,
      withoutPeriod.toLowerCase(),
      ...extraAcceptedAnswers,
    }.toList();
  }
}

_LanguageSeed _sundaSeed() {
  return const _LanguageSeed(
    id: 'sunda',
    name: 'Bahasa Sunda',
    nativeName: 'Basa Sunda',
    shortName: 'Sunda',
    region: 'Jawa Barat dan Banten',
    sourceName: 'Wikikamus bahasa Indonesia',
    sourceUrl:
        'https://id.wiktionary.org/wiki/Lampiran:Kamus_bahasa_Sunda_%E2%80%93_bahasa_Indonesia',
    license: 'CC BY-SA / GFDL',
    seedVersion: 4,
    units: [
      _UnitSeed(
        unitNo: 1,
        title: 'Perkenalan & Sapaan',
        description:
            'Unit ini mengenalkan sapaan, ungkapan sopan, dan perkenalan diri sederhana.',
        level1Title: 'Sapaan Dasar',
        level2Title: 'Cocokkan Kata Ganti',
        level3Title: 'Susun Kalimat Perkenalan',
        level4Title: 'Terjemahkan Sapaan',
        level5Title: 'Review Perkenalan',
        level1Words: [
          _WordSeed(
            id: 'sampurasun',
            local: 'sampurasun',
            meaning: 'salam',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['sapaan', 'kesopanan'],
            exampleLocal: 'Sampurasun, wilujeng sumping.',
            exampleId: 'Salam, selamat datang.',
          ),
          _WordSeed(
            id: 'rampes',
            local: 'rampés',
            meaning: 'jawaban salam',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['sapaan', 'kesopanan'],
            exampleLocal: 'Rampés, wilujeng sumping.',
            exampleId: 'Baik, selamat datang.',
          ),
          _WordSeed(
            id: 'wilujeng_enjing',
            local: 'wilujeng enjing',
            meaning: 'selamat pagi',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['sapaan', 'waktu'],
          ),
          _WordSeed(
            id: 'hatur_nuhun',
            local: 'hatur nuhun',
            meaning: 'terima kasih',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['sapaan', 'kesopanan'],
          ),
          _WordSeed(
            id: 'punten',
            local: 'punten',
            meaning: 'permisi',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['sapaan', 'kesopanan'],
          ),
        ],
        matchingWords: [
          _WordSeed(
            id: 'abdi',
            local: 'abdi',
            meaning: 'saya',
            partOfSpeech: 'pronoun',
            topicTags: ['perkenalan', 'kata_ganti'],
          ),
          _WordSeed(
            id: 'anjeun',
            local: 'anjeun',
            meaning: 'anda',
            partOfSpeech: 'pronoun',
            topicTags: ['perkenalan', 'kata_ganti'],
          ),
          _WordSeed(
            id: 'nami',
            local: 'nami',
            meaning: 'nama',
            partOfSpeech: 'noun',
            topicTags: ['perkenalan'],
          ),
          _WordSeed(
            id: 'ti',
            local: 'ti',
            meaning: 'dari',
            partOfSpeech: 'preposition',
            topicTags: ['perkenalan', 'kalimat_dasar'],
          ),
        ],
        extraWords: [
          _WordSeed(
            id: 'kumaha_damang',
            local: 'kumaha damang?',
            meaning: 'apa kabar',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['sapaan', 'kabar'],
          ),
          _WordSeed(
            id: 'damang',
            local: 'damang',
            meaning: 'sehat',
            partOfSpeech: 'adjective',
            topicTags: ['kabar', 'kondisi'],
          ),
          _WordSeed(
            id: 'muhun',
            local: 'muhun',
            meaning: 'iya',
            partOfSpeech: 'adverb',
            topicTags: ['percakapan', 'jawaban'],
          ),
          _WordSeed(
            id: 'henteu',
            local: 'henteu',
            meaning: 'tidak',
            partOfSpeech: 'adverb',
            topicTags: ['percakapan', 'jawaban'],
          ),
        ],
        sentences: [
          _SentenceSeed(
            words: ['abdi', 'ti', 'Bandung'],
            local: 'abdi ti Bandung',
            displayLocal: 'Abdi ti Bandung.',
            translation: 'Saya dari Bandung.',
          ),
          _SentenceSeed(
            words: ['nami', 'abdi', 'Loka'],
            local: 'nami abdi Loka',
            displayLocal: 'Nami abdi Loka.',
            translation: 'Nama saya Loka.',
          ),
          _SentenceSeed(
            words: ['kumaha', 'damang'],
            local: 'kumaha damang',
            displayLocal: 'Kumaha damang?',
            translation: 'Apa kabar?',
          ),
        ],
      ),
      _UnitSeed(
        unitNo: 2,
        title: 'Keluarga & Orang Sekitar',
        description:
            'Unit ini mengenalkan kosakata keluarga, orang sekitar, dan sifat sederhana.',
        level1Title: 'Anggota Keluarga',
        level2Title: 'Cocokkan Orang Sekitar',
        level3Title: 'Susun Kalimat Keluarga',
        level4Title: 'Terjemahkan Kalimat Keluarga',
        level5Title: 'Ujian Keluarga & Orang Sekitar',
        level1Words: [
          _WordSeed(
            id: 'bapa',
            local: 'bapa',
            meaning: 'ayah',
            partOfSpeech: 'noun',
            topicTags: ['keluarga'],
          ),
          _WordSeed(
            id: 'indung',
            local: 'indung',
            meaning: 'ibu',
            partOfSpeech: 'noun',
            topicTags: ['keluarga'],
          ),
          _WordSeed(
            id: 'lanceuk',
            local: 'lanceuk',
            meaning: 'kakak',
            partOfSpeech: 'noun',
            topicTags: ['keluarga'],
          ),
          _WordSeed(
            id: 'adi',
            local: 'adi',
            meaning: 'adik',
            partOfSpeech: 'noun',
            topicTags: ['keluarga'],
          ),
          _WordSeed(
            id: 'kulawarga',
            local: 'kulawarga',
            meaning: 'keluarga',
            partOfSpeech: 'noun',
            topicTags: ['keluarga'],
          ),
        ],
        matchingWords: [
          _WordSeed(
            id: 'rencang',
            local: 'rencang',
            meaning: 'teman',
            partOfSpeech: 'noun',
            topicTags: ['orang_sekitar'],
          ),
          _WordSeed(
            id: 'guru',
            local: 'guru',
            meaning: 'guru',
            partOfSpeech: 'noun',
            topicTags: ['orang_sekitar'],
          ),
          _WordSeed(
            id: 'murid',
            local: 'murid',
            meaning: 'murid',
            partOfSpeech: 'noun',
            topicTags: ['orang_sekitar'],
          ),
          _WordSeed(
            id: 'bageur',
            local: 'bageur',
            meaning: 'baik',
            partOfSpeech: 'adjective',
            topicTags: ['sifat'],
          ),
          _WordSeed(
            id: 'pinter',
            local: 'pinter',
            meaning: 'pintar',
            partOfSpeech: 'adjective',
            topicTags: ['sifat'],
          ),
        ],
        extraWords: [
          _WordSeed(
            id: 'ieu',
            local: 'ieu',
            meaning: 'ini',
            partOfSpeech: 'demonstrative',
            topicTags: ['kalimat_dasar'],
          ),
          _WordSeed(
            id: 'pisan',
            local: 'pisan',
            meaning: 'sangat',
            partOfSpeech: 'adverb',
            topicTags: ['sifat'],
          ),
        ],
        sentences: [
          _SentenceSeed(
            words: ['ieu', 'bapa', 'abdi'],
            local: 'ieu bapa abdi',
            displayLocal: 'Ieu bapa abdi.',
            translation: 'Ini ayah saya.',
            extraAcceptedAnswers: ['Ini bapak saya.', 'ini bapak saya'],
          ),
          _SentenceSeed(
            words: ['ieu', 'rencang', 'abdi'],
            local: 'ieu rencang abdi',
            displayLocal: 'Ieu rencang abdi.',
            translation: 'Ini teman saya.',
          ),
          _SentenceSeed(
            words: ['anjeun', 'bageur', 'pisan'],
            local: 'anjeun bageur pisan',
            displayLocal: 'Anjeun bageur pisan.',
            translation: 'Anda sangat baik.',
            extraAcceptedAnswers: ['Kamu sangat baik.', 'kamu sangat baik'],
          ),
        ],
      ),
      _UnitSeed(
        unitNo: 3,
        title: 'Angka, Waktu & Hari',
        description:
            'Unit ini mengenalkan angka, jumlah, hari, dan waktu sederhana.',
        level1Title: 'Angka Dasar',
        level2Title: 'Cocokkan Waktu Sederhana',
        level3Title: 'Susun Kalimat Waktu',
        level4Title: 'Terjemahkan Kalimat Waktu',
        level5Title: 'Ujian Angka, Waktu & Hari',
        level1Words: [
          _WordSeed(
            id: 'hiji',
            local: 'hiji',
            meaning: 'satu',
            partOfSpeech: 'number',
            topicTags: ['angka'],
          ),
          _WordSeed(
            id: 'dua',
            local: 'dua',
            meaning: 'dua',
            partOfSpeech: 'number',
            topicTags: ['angka'],
          ),
          _WordSeed(
            id: 'tilu',
            local: 'tilu',
            meaning: 'tiga',
            partOfSpeech: 'number',
            topicTags: ['angka'],
          ),
          _WordSeed(
            id: 'opat',
            local: 'opat',
            meaning: 'empat',
            partOfSpeech: 'number',
            topicTags: ['angka'],
          ),
          _WordSeed(
            id: 'lima',
            local: 'lima',
            meaning: 'lima',
            partOfSpeech: 'number',
            topicTags: ['angka'],
          ),
        ],
        matchingWords: [
          _WordSeed(
            id: 'ayeuna',
            local: 'ayeuna',
            meaning: 'sekarang',
            partOfSpeech: 'adverb',
            topicTags: ['waktu'],
          ),
          _WordSeed(
            id: 'isukan',
            local: 'isukan',
            meaning: 'besok',
            partOfSpeech: 'adverb',
            topicTags: ['waktu'],
          ),
          _WordSeed(
            id: 'kamari',
            local: 'kamari',
            meaning: 'kemarin',
            partOfSpeech: 'adverb',
            topicTags: ['waktu'],
          ),
          _WordSeed(
            id: 'dinten',
            local: 'dinten',
            meaning: 'hari',
            partOfSpeech: 'noun',
            topicTags: ['waktu'],
          ),
          _WordSeed(
            id: 'peuting',
            local: 'peuting',
            meaning: 'malam',
            partOfSpeech: 'noun',
            topicTags: ['waktu'],
          ),
          _WordSeed(
            id: 'beurang',
            local: 'beurang',
            meaning: 'siang',
            partOfSpeech: 'noun',
            topicTags: ['waktu'],
          ),
        ],
        extraWords: [
          _WordSeed(
            id: 'diajar',
            local: 'diajar',
            meaning: 'belajar',
            partOfSpeech: 'verb',
            topicTags: ['aktivitas'],
          ),
          _WordSeed(
            id: 'sakola',
            local: 'sakola',
            meaning: 'sekolah',
            partOfSpeech: 'noun',
            topicTags: ['tempat'],
          ),
          _WordSeed(
            id: 'pasar',
            local: 'pasar',
            meaning: 'pasar',
            partOfSpeech: 'noun',
            topicTags: ['tempat'],
          ),
          _WordSeed(
            id: 'ka',
            local: 'ka',
            meaning: 'ke',
            partOfSpeech: 'preposition',
            topicTags: ['arah'],
          ),
        ],
        sentences: [
          _SentenceSeed(
            words: ['ayeuna', 'abdi', 'diajar'],
            local: 'ayeuna abdi diajar',
            displayLocal: 'Ayeuna abdi diajar.',
            translation: 'Sekarang saya belajar.',
          ),
          _SentenceSeed(
            words: ['isukan', 'abdi', 'ka', 'sakola'],
            local: 'isukan abdi ka sakola',
            displayLocal: 'Isukan abdi ka sakola.',
            translation: 'Besok saya ke sekolah.',
          ),
          _SentenceSeed(
            words: ['kamari', 'abdi', 'ka', 'pasar'],
            local: 'kamari abdi ka pasar',
            displayLocal: 'Kamari abdi ka pasar.',
            translation: 'Kemarin saya ke pasar.',
          ),
        ],
      ),
      _UnitSeed(
        unitNo: 4,
        title: 'Makanan & Belanja',
        description:
            'Unit ini mengenalkan kosakata makanan, rasa, dan percakapan belanja sederhana.',
        level1Title: 'Makanan Dasar',
        level2Title: 'Cocokkan Rasa & Belanja',
        level3Title: 'Susun Kalimat Makanan',
        level4Title: 'Terjemahkan Kalimat Makanan',
        level5Title: 'Ujian Makanan & Belanja',
        level1Words: [
          _WordSeed(
            id: 'sangu',
            local: 'sangu',
            meaning: 'nasi',
            partOfSpeech: 'noun',
            topicTags: ['makanan'],
          ),
          _WordSeed(
            id: 'cai',
            local: 'cai',
            meaning: 'air',
            partOfSpeech: 'noun',
            topicTags: ['minuman'],
          ),
          _WordSeed(
            id: 'dahar',
            local: 'dahar',
            meaning: 'makan',
            partOfSpeech: 'verb',
            topicTags: ['makanan'],
          ),
          _WordSeed(
            id: 'nginum',
            local: 'nginum',
            meaning: 'minum',
            partOfSpeech: 'verb',
            topicTags: ['minuman'],
          ),
          _WordSeed(
            id: 'kadaharan',
            local: 'kadaharan',
            meaning: 'makanan',
            partOfSpeech: 'noun',
            topicTags: ['makanan'],
          ),
        ],
        matchingWords: [
          _WordSeed(
            id: 'amis',
            local: 'amis',
            meaning: 'manis',
            partOfSpeech: 'adjective',
            topicTags: ['rasa'],
          ),
          _WordSeed(
            id: 'asin',
            local: 'asin',
            meaning: 'asin',
            partOfSpeech: 'adjective',
            topicTags: ['rasa'],
          ),
          _WordSeed(
            id: 'lada',
            local: 'lada',
            meaning: 'pedas',
            partOfSpeech: 'adjective',
            topicTags: ['rasa'],
          ),
          _WordSeed(
            id: 'mirah',
            local: 'mirah',
            meaning: 'murah',
            partOfSpeech: 'adjective',
            topicTags: ['belanja'],
          ),
          _WordSeed(
            id: 'mahal',
            local: 'mahal',
            meaning: 'mahal',
            partOfSpeech: 'adjective',
            topicTags: ['belanja'],
          ),
          _WordSeed(
            id: 'meser',
            local: 'mésér',
            meaning: 'membeli',
            partOfSpeech: 'verb',
            topicTags: ['belanja'],
          ),
          _WordSeed(
            id: 'hoyong',
            local: 'hoyong',
            meaning: 'ingin',
            partOfSpeech: 'verb',
            topicTags: ['belanja'],
          ),
          _WordSeed(
            id: 'harga',
            local: 'harga',
            meaning: 'harga',
            partOfSpeech: 'noun',
            topicTags: ['belanja'],
          ),
          _WordSeed(
            id: 'sabaraha',
            local: 'sabaraha',
            meaning: 'berapa',
            partOfSpeech: 'question',
            topicTags: ['belanja'],
          ),
        ],
        extraWords: [
          _WordSeed(
            id: 'ieu',
            local: 'ieu',
            meaning: 'ini',
            partOfSpeech: 'demonstrative',
            topicTags: ['kalimat_dasar'],
          ),
        ],
        sentences: [
          _SentenceSeed(
            words: ['abdi', 'dahar', 'sangu'],
            local: 'abdi dahar sangu',
            displayLocal: 'Abdi dahar sangu.',
            translation: 'Saya makan nasi.',
          ),
          _SentenceSeed(
            words: ['abdi', 'nginum', 'cai'],
            local: 'abdi nginum cai',
            displayLocal: 'Abdi nginum cai.',
            translation: 'Saya minum air.',
          ),
          _SentenceSeed(
            words: ['sabaraha', 'harga', 'ieu'],
            local: 'sabaraha harga ieu',
            displayLocal: 'Sabaraha harga ieu?',
            translation: 'Berapa harga ini?',
          ),
        ],
      ),
      _UnitSeed(
        unitNo: 5,
        title: 'Arah, Tempat & Perjalanan',
        description:
            'Unit ini mengenalkan tempat, arah, dan kalimat perjalanan sederhana.',
        level1Title: 'Tempat Dasar',
        level2Title: 'Cocokkan Arah & Perjalanan',
        level3Title: 'Susun Kalimat Perjalanan',
        level4Title: 'Terjemahkan Kalimat Perjalanan',
        level5Title: 'Ujian Arah, Tempat & Perjalanan',
        level1Words: [
          _WordSeed(
            id: 'bumi',
            local: 'bumi',
            meaning: 'rumah',
            partOfSpeech: 'noun',
            topicTags: ['tempat'],
          ),
          _WordSeed(
            id: 'sakola',
            local: 'sakola',
            meaning: 'sekolah',
            partOfSpeech: 'noun',
            topicTags: ['tempat'],
          ),
          _WordSeed(
            id: 'pasar',
            local: 'pasar',
            meaning: 'pasar',
            partOfSpeech: 'noun',
            topicTags: ['tempat'],
          ),
          _WordSeed(
            id: 'jalan',
            local: 'jalan',
            meaning: 'jalan',
            partOfSpeech: 'noun',
            topicTags: ['tempat'],
          ),
          _WordSeed(
            id: 'ka',
            local: 'ka',
            meaning: 'ke',
            partOfSpeech: 'preposition',
            topicTags: ['arah'],
          ),
        ],
        matchingWords: [
          _WordSeed(
            id: 'kenca',
            local: 'kénca',
            meaning: 'kiri',
            partOfSpeech: 'direction',
            topicTags: ['arah'],
          ),
          _WordSeed(
            id: 'katuhu',
            local: 'katuhu',
            meaning: 'kanan',
            partOfSpeech: 'direction',
            topicTags: ['arah'],
          ),
          _WordSeed(
            id: 'payun',
            local: 'payun',
            meaning: 'depan',
            partOfSpeech: 'direction',
            topicTags: ['arah'],
          ),
          _WordSeed(
            id: 'tukang',
            local: 'tukang',
            meaning: 'belakang',
            partOfSpeech: 'direction',
            topicTags: ['arah'],
          ),
          _WordSeed(
            id: 'angkat',
            local: 'angkat',
            meaning: 'pergi',
            partOfSpeech: 'verb',
            topicTags: ['perjalanan'],
          ),
          _WordSeed(
            id: 'sumping',
            local: 'sumping',
            meaning: 'datang',
            partOfSpeech: 'verb',
            topicTags: ['perjalanan'],
          ),
          _WordSeed(
            id: 'leumpang',
            local: 'leumpang',
            meaning: 'berjalan',
            partOfSpeech: 'verb',
            topicTags: ['perjalanan'],
          ),
        ],
        extraWords: [
          _WordSeed(
            id: 'indung',
            local: 'indung',
            meaning: 'ibu',
            partOfSpeech: 'noun',
            topicTags: ['keluarga'],
          ),
          _WordSeed(
            id: 'rencang',
            local: 'rencang',
            meaning: 'teman',
            partOfSpeech: 'noun',
            topicTags: ['orang_sekitar'],
          ),
        ],
        sentences: [
          _SentenceSeed(
            words: ['abdi', 'ka', 'sakola'],
            local: 'abdi ka sakola',
            displayLocal: 'Abdi ka sakola.',
            translation: 'Saya ke sekolah.',
          ),
          _SentenceSeed(
            words: ['indung', 'ka', 'pasar'],
            local: 'indung ka pasar',
            displayLocal: 'Indung ka pasar.',
            translation: 'Ibu ke pasar.',
          ),
          _SentenceSeed(
            words: ['rencang', 'abdi', 'sumping'],
            local: 'rencang abdi sumping',
            displayLocal: 'Rencang abdi sumping.',
            translation: 'Teman saya datang.',
          ),
        ],
      ),
      _UnitSeed(
        unitNo: 6,
        title: 'Budaya & Percakapan Harian',
        description:
            'Unit ini berisi ungkapan sehari-hari, budaya lokal, dan review percakapan.',
        level1Title: 'Ungkapan Sopan Harian',
        level2Title: 'Cocokkan Percakapan & Budaya',
        level3Title: 'Susun Kalimat Percakapan',
        level4Title: 'Terjemahkan Kalimat Percakapan',
        level5Title: 'Ujian Akhir Bahasa Sunda',
        level1Words: [
          _WordSeed(
            id: 'mangga',
            local: 'mangga',
            meaning: 'silakan',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['kesopanan'],
          ),
          _WordSeed(
            id: 'hapunten',
            local: 'hapunten',
            meaning: 'maaf',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['kesopanan'],
          ),
          _WordSeed(
            id: 'wilujeng_sumping',
            local: 'wilujeng sumping',
            meaning: 'selamat datang',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['sapaan'],
          ),
          _WordSeed(
            id: 'sing_ati_ati',
            local: 'sing ati-ati',
            meaning: 'hati-hati',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['percakapan'],
          ),
          _WordSeed(
            id: 'mugia',
            local: 'mugia',
            meaning: 'semoga',
            partOfSpeech: 'expression',
            topicTags: ['percakapan'],
          ),
        ],
        matchingWords: [
          _WordSeed(
            id: 'leres',
            local: 'leres',
            meaning: 'benar',
            partOfSpeech: 'adjective',
            topicTags: ['percakapan'],
          ),
          _WordSeed(
            id: 'sadayana',
            local: 'sadayana',
            meaning: 'semuanya',
            partOfSpeech: 'pronoun',
            topicTags: ['percakapan'],
          ),
          _WordSeed(
            id: 'ngobrol',
            local: 'ngobrol',
            meaning: 'mengobrol',
            partOfSpeech: 'verb',
            topicTags: ['percakapan'],
          ),
          _WordSeed(
            id: 'carita',
            local: 'carita',
            meaning: 'cerita',
            partOfSpeech: 'noun',
            topicTags: ['budaya'],
          ),
          _WordSeed(
            id: 'adat',
            local: 'adat',
            meaning: 'adat',
            partOfSpeech: 'noun',
            topicTags: ['budaya'],
          ),
          _WordSeed(
            id: 'sopan',
            local: 'sopan',
            meaning: 'sopan',
            partOfSpeech: 'adjective',
            topicTags: ['budaya'],
          ),
        ],
        extraWords: [
          _WordSeed(
            id: 'lebet',
            local: 'lebet',
            meaning: 'masuk',
            partOfSpeech: 'verb',
            topicTags: ['percakapan'],
          ),
          _WordSeed(
            id: 'sareng',
            local: 'sareng',
            meaning: 'dengan',
            partOfSpeech: 'preposition',
            topicTags: ['percakapan'],
          ),
          _WordSeed(
            id: 'kedah',
            local: 'kedah',
            meaning: 'harus',
            partOfSpeech: 'modal',
            topicTags: ['percakapan'],
          ),
          _WordSeed(
            id: 'rencang',
            local: 'rencang',
            meaning: 'teman',
            partOfSpeech: 'noun',
            topicTags: ['orang_sekitar'],
          ),
          _WordSeed(
            id: 'damang',
            local: 'damang',
            meaning: 'sehat',
            partOfSpeech: 'adjective',
            topicTags: ['kabar'],
          ),
        ],
        sentences: [
          _SentenceSeed(
            words: ['mangga', 'lebet'],
            local: 'mangga lebet',
            displayLocal: 'Mangga, lebet.',
            translation: 'Silakan masuk.',
          ),
          _SentenceSeed(
            words: ['mugia', 'damang'],
            local: 'mugia damang',
            displayLocal: 'Mugia damang.',
            translation: 'Semoga sehat.',
            extraAcceptedAnswers: ['Semoga baik.', 'semoga baik'],
          ),
          _SentenceSeed(
            words: ['anjeun', 'kedah', 'sopan'],
            local: 'anjeun kedah sopan',
            displayLocal: 'Anjeun kedah sopan.',
            translation: 'Anda harus sopan.',
            extraAcceptedAnswers: ['Kamu harus sopan.', 'kamu harus sopan'],
          ),
        ],
      ),
    ],
  );
}

_LanguageSeed _jawaSeed() {
  return const _LanguageSeed(
    id: 'jawa',
    name: 'Bahasa Jawa',
    nativeName: 'Basa Jawa',
    shortName: 'Jawa',
    region: 'Jawa Tengah, Yogyakarta, Jawa Timur',
    sourceName: 'Wikikamus bahasa Indonesia',
    sourceUrl:
        'https://id.wiktionary.org/wiki/Lampiran:Kamus_bahasa_Jawa_%E2%80%93_bahasa_Indonesia',
    license: 'CC BY-SA / GFDL',
    seedVersion: 1,
    units: [
      _UnitSeed(
        unitNo: 1,
        title: 'Perkenalan & Sapaan',
        description:
            'Unit ini mengenalkan sapaan, ungkapan sopan, dan perkenalan diri sederhana dalam Bahasa Jawa.',
        level1Title: 'Sapaan Dasar',
        level2Title: 'Cocokkan Kata Ganti',
        level3Title: 'Susun Kalimat Perkenalan',
        level4Title: 'Terjemahkan Sapaan',
        level5Title: 'Review Perkenalan',
        level1Words: [
          _WordSeed(
            id: 'kulonuwun',
            local: 'kulonuwun',
            meaning: 'permisi',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['sapaan', 'kesopanan'],
          ),
          _WordSeed(
            id: 'sugeng_enjing',
            local: 'sugeng enjing',
            meaning: 'selamat pagi',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['sapaan', 'waktu'],
          ),
          _WordSeed(
            id: 'matur_nuwun',
            local: 'matur nuwun',
            meaning: 'terima kasih',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['sapaan', 'kesopanan'],
          ),
          _WordSeed(
            id: 'nyuwun_sewu',
            local: 'nyuwun sewu',
            meaning: 'maaf',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['sapaan', 'kesopanan'],
          ),
          _WordSeed(
            id: 'sugeng_rawuh',
            local: 'sugeng rawuh',
            meaning: 'selamat datang',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['sapaan'],
          ),
        ],
        matchingWords: [
          _WordSeed(
            id: 'aku',
            local: 'aku',
            meaning: 'saya',
            partOfSpeech: 'pronoun',
            topicTags: ['perkenalan', 'kata_ganti'],
          ),
          _WordSeed(
            id: 'kowe',
            local: 'kowe',
            meaning: 'kamu',
            partOfSpeech: 'pronoun',
            topicTags: ['perkenalan', 'kata_ganti'],
          ),
          _WordSeed(
            id: 'jeneng',
            local: 'jeneng',
            meaning: 'nama',
            partOfSpeech: 'noun',
            topicTags: ['perkenalan'],
          ),
          _WordSeed(
            id: 'saka',
            local: 'saka',
            meaning: 'dari',
            partOfSpeech: 'preposition',
            topicTags: ['perkenalan'],
          ),
        ],
        extraWords: [
          _WordSeed(
            id: 'piye_kabare',
            local: 'piye kabare?',
            meaning: 'apa kabar',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['sapaan', 'kabar'],
          ),
          _WordSeed(
            id: 'apik',
            local: 'apik',
            meaning: 'baik',
            partOfSpeech: 'adjective',
            topicTags: ['kabar'],
          ),
          _WordSeed(
            id: 'iya',
            local: 'iya',
            meaning: 'iya',
            partOfSpeech: 'adverb',
            topicTags: ['jawaban'],
          ),
          _WordSeed(
            id: 'ora',
            local: 'ora',
            meaning: 'tidak',
            partOfSpeech: 'adverb',
            topicTags: ['jawaban'],
          ),
        ],
        sentences: [
          _SentenceSeed(
            words: ['aku', 'saka', 'Yogyakarta'],
            local: 'aku saka Yogyakarta',
            displayLocal: 'Aku saka Yogyakarta.',
            translation: 'Saya dari Yogyakarta.',
          ),
          _SentenceSeed(
            words: ['jenengku', 'Loka'],
            local: 'jenengku Loka',
            displayLocal: 'Jenengku Loka.',
            translation: 'Nama saya Loka.',
          ),
          _SentenceSeed(
            words: ['piye', 'kabare'],
            local: 'piye kabare',
            displayLocal: 'Piye kabare?',
            translation: 'Apa kabar?',
          ),
        ],
      ),
      _UnitSeed(
        unitNo: 2,
        title: 'Keluarga & Orang Sekitar',
        description:
            'Unit ini mengenalkan kosakata keluarga, orang sekitar, dan sifat sederhana dalam Bahasa Jawa.',
        level1Title: 'Anggota Keluarga',
        level2Title: 'Cocokkan Orang Sekitar',
        level3Title: 'Susun Kalimat Keluarga',
        level4Title: 'Terjemahkan Kalimat Keluarga',
        level5Title: 'Ujian Keluarga & Orang Sekitar',
        level1Words: [
          _WordSeed(
            id: 'bapak',
            local: 'bapak',
            meaning: 'ayah',
            partOfSpeech: 'noun',
            topicTags: ['keluarga'],
          ),
          _WordSeed(
            id: 'ibu',
            local: 'ibu',
            meaning: 'ibu',
            partOfSpeech: 'noun',
            topicTags: ['keluarga'],
          ),
          _WordSeed(
            id: 'kakang',
            local: 'kakang',
            meaning: 'kakak',
            partOfSpeech: 'noun',
            topicTags: ['keluarga'],
          ),
          _WordSeed(
            id: 'adhi',
            local: 'adhi',
            meaning: 'adik',
            partOfSpeech: 'noun',
            topicTags: ['keluarga'],
          ),
          _WordSeed(
            id: 'kulawarga',
            local: 'kulawarga',
            meaning: 'keluarga',
            partOfSpeech: 'noun',
            topicTags: ['keluarga'],
          ),
        ],
        matchingWords: [
          _WordSeed(
            id: 'kanca',
            local: 'kanca',
            meaning: 'teman',
            partOfSpeech: 'noun',
            topicTags: ['orang_sekitar'],
          ),
          _WordSeed(
            id: 'guru',
            local: 'guru',
            meaning: 'guru',
            partOfSpeech: 'noun',
            topicTags: ['orang_sekitar'],
          ),
          _WordSeed(
            id: 'murid',
            local: 'murid',
            meaning: 'murid',
            partOfSpeech: 'noun',
            topicTags: ['orang_sekitar'],
          ),
          _WordSeed(
            id: 'apik',
            local: 'apik',
            meaning: 'baik',
            partOfSpeech: 'adjective',
            topicTags: ['sifat'],
          ),
          _WordSeed(
            id: 'pinter',
            local: 'pinter',
            meaning: 'pintar',
            partOfSpeech: 'adjective',
            topicTags: ['sifat'],
          ),
        ],
        extraWords: [
          _WordSeed(
            id: 'iki',
            local: 'iki',
            meaning: 'ini',
            partOfSpeech: 'demonstrative',
            topicTags: ['kalimat_dasar'],
          ),
          _WordSeed(
            id: 'banget',
            local: 'banget',
            meaning: 'sangat',
            partOfSpeech: 'adverb',
            topicTags: ['sifat'],
          ),
        ],
        sentences: [
          _SentenceSeed(
            words: ['iki', 'bapak', 'aku'],
            local: 'iki bapak aku',
            displayLocal: 'Iki bapak aku.',
            translation: 'Ini ayah saya.',
            extraAcceptedAnswers: ['Ini bapak saya.', 'ini bapak saya'],
          ),
          _SentenceSeed(
            words: ['iki', 'kanca', 'aku'],
            local: 'iki kanca aku',
            displayLocal: 'Iki kanca aku.',
            translation: 'Ini teman saya.',
          ),
          _SentenceSeed(
            words: ['adhi', 'aku', 'pinter'],
            local: 'adhi aku pinter',
            displayLocal: 'Adhi aku pinter.',
            translation: 'Adik saya pintar.',
          ),
        ],
      ),
      _UnitSeed(
        unitNo: 3,
        title: 'Angka, Waktu & Hari',
        description:
            'Unit ini mengenalkan angka, jumlah, hari, dan waktu sederhana dalam Bahasa Jawa.',
        level1Title: 'Angka Dasar',
        level2Title: 'Cocokkan Waktu Sederhana',
        level3Title: 'Susun Kalimat Waktu',
        level4Title: 'Terjemahkan Kalimat Waktu',
        level5Title: 'Ujian Angka, Waktu & Hari',
        level1Words: [
          _WordSeed(
            id: 'siji',
            local: 'siji',
            meaning: 'satu',
            partOfSpeech: 'number',
            topicTags: ['angka'],
          ),
          _WordSeed(
            id: 'loro',
            local: 'loro',
            meaning: 'dua',
            partOfSpeech: 'number',
            topicTags: ['angka'],
          ),
          _WordSeed(
            id: 'telu',
            local: 'telu',
            meaning: 'tiga',
            partOfSpeech: 'number',
            topicTags: ['angka'],
          ),
          _WordSeed(
            id: 'papat',
            local: 'papat',
            meaning: 'empat',
            partOfSpeech: 'number',
            topicTags: ['angka'],
          ),
          _WordSeed(
            id: 'lima',
            local: 'lima',
            meaning: 'lima',
            partOfSpeech: 'number',
            topicTags: ['angka'],
          ),
        ],
        matchingWords: [
          _WordSeed(
            id: 'saiki',
            local: 'saiki',
            meaning: 'sekarang',
            partOfSpeech: 'adverb',
            topicTags: ['waktu'],
          ),
          _WordSeed(
            id: 'sesuk',
            local: 'sesuk',
            meaning: 'besok',
            partOfSpeech: 'adverb',
            topicTags: ['waktu'],
          ),
          _WordSeed(
            id: 'wingi',
            local: 'wingi',
            meaning: 'kemarin',
            partOfSpeech: 'adverb',
            topicTags: ['waktu'],
          ),
          _WordSeed(
            id: 'dina',
            local: 'dina',
            meaning: 'hari',
            partOfSpeech: 'noun',
            topicTags: ['waktu'],
          ),
          _WordSeed(
            id: 'wengi',
            local: 'wengi',
            meaning: 'malam',
            partOfSpeech: 'noun',
            topicTags: ['waktu'],
          ),
          _WordSeed(
            id: 'awan',
            local: 'awan',
            meaning: 'siang',
            partOfSpeech: 'noun',
            topicTags: ['waktu'],
          ),
        ],
        extraWords: [
          _WordSeed(
            id: 'sinau',
            local: 'sinau',
            meaning: 'belajar',
            partOfSpeech: 'verb',
            topicTags: ['aktivitas'],
          ),
          _WordSeed(
            id: 'sekolah',
            local: 'sekolah',
            meaning: 'sekolah',
            partOfSpeech: 'noun',
            topicTags: ['tempat'],
          ),
          _WordSeed(
            id: 'pasar',
            local: 'pasar',
            meaning: 'pasar',
            partOfSpeech: 'noun',
            topicTags: ['tempat'],
          ),
          _WordSeed(
            id: 'menyang',
            local: 'menyang',
            meaning: 'ke',
            partOfSpeech: 'preposition',
            topicTags: ['arah'],
          ),
        ],
        sentences: [
          _SentenceSeed(
            words: ['saiki', 'aku', 'sinau'],
            local: 'saiki aku sinau',
            displayLocal: 'Saiki aku sinau.',
            translation: 'Sekarang saya belajar.',
          ),
          _SentenceSeed(
            words: ['sesuk', 'aku', 'menyang', 'sekolah'],
            local: 'sesuk aku menyang sekolah',
            displayLocal: 'Sesuk aku menyang sekolah.',
            translation: 'Besok saya ke sekolah.',
          ),
          _SentenceSeed(
            words: ['wingi', 'aku', 'menyang', 'pasar'],
            local: 'wingi aku menyang pasar',
            displayLocal: 'Wingi aku menyang pasar.',
            translation: 'Kemarin saya ke pasar.',
          ),
        ],
      ),
      _UnitSeed(
        unitNo: 4,
        title: 'Makanan & Belanja',
        description:
            'Unit ini mengenalkan kosakata makanan, rasa, dan percakapan belanja sederhana dalam Bahasa Jawa.',
        level1Title: 'Makanan Dasar',
        level2Title: 'Cocokkan Rasa & Belanja',
        level3Title: 'Susun Kalimat Makanan',
        level4Title: 'Terjemahkan Kalimat Makanan',
        level5Title: 'Ujian Makanan & Belanja',
        level1Words: [
          _WordSeed(
            id: 'sega',
            local: 'sega',
            meaning: 'nasi',
            partOfSpeech: 'noun',
            topicTags: ['makanan'],
          ),
          _WordSeed(
            id: 'banyu',
            local: 'banyu',
            meaning: 'air',
            partOfSpeech: 'noun',
            topicTags: ['minuman'],
          ),
          _WordSeed(
            id: 'mangan',
            local: 'mangan',
            meaning: 'makan',
            partOfSpeech: 'verb',
            topicTags: ['makanan'],
          ),
          _WordSeed(
            id: 'ngombe',
            local: 'ngombe',
            meaning: 'minum',
            partOfSpeech: 'verb',
            topicTags: ['minuman'],
          ),
          _WordSeed(
            id: 'panganan',
            local: 'panganan',
            meaning: 'makanan',
            partOfSpeech: 'noun',
            topicTags: ['makanan'],
          ),
        ],
        matchingWords: [
          _WordSeed(
            id: 'legi',
            local: 'legi',
            meaning: 'manis',
            partOfSpeech: 'adjective',
            topicTags: ['rasa'],
          ),
          _WordSeed(
            id: 'asin',
            local: 'asin',
            meaning: 'asin',
            partOfSpeech: 'adjective',
            topicTags: ['rasa'],
          ),
          _WordSeed(
            id: 'pedhes',
            local: 'pedhes',
            meaning: 'pedas',
            partOfSpeech: 'adjective',
            topicTags: ['rasa'],
          ),
          _WordSeed(
            id: 'murah',
            local: 'murah',
            meaning: 'murah',
            partOfSpeech: 'adjective',
            topicTags: ['belanja'],
          ),
          _WordSeed(
            id: 'larang',
            local: 'larang',
            meaning: 'mahal',
            partOfSpeech: 'adjective',
            topicTags: ['belanja'],
          ),
          _WordSeed(
            id: 'tuku',
            local: 'tuku',
            meaning: 'membeli',
            partOfSpeech: 'verb',
            topicTags: ['belanja'],
          ),
          _WordSeed(
            id: 'pengin',
            local: 'pengin',
            meaning: 'ingin',
            partOfSpeech: 'verb',
            topicTags: ['belanja'],
          ),
          _WordSeed(
            id: 'rega',
            local: 'rega',
            meaning: 'harga',
            partOfSpeech: 'noun',
            topicTags: ['belanja'],
          ),
          _WordSeed(
            id: 'pira',
            local: 'pira',
            meaning: 'berapa',
            partOfSpeech: 'question',
            topicTags: ['belanja'],
          ),
        ],
        extraWords: [
          _WordSeed(
            id: 'iki',
            local: 'iki',
            meaning: 'ini',
            partOfSpeech: 'demonstrative',
            topicTags: ['kalimat_dasar'],
          ),
        ],
        sentences: [
          _SentenceSeed(
            words: ['aku', 'mangan', 'sega'],
            local: 'aku mangan sega',
            displayLocal: 'Aku mangan sega.',
            translation: 'Saya makan nasi.',
          ),
          _SentenceSeed(
            words: ['aku', 'ngombe', 'banyu'],
            local: 'aku ngombe banyu',
            displayLocal: 'Aku ngombe banyu.',
            translation: 'Saya minum air.',
          ),
          _SentenceSeed(
            words: ['pira', 'rega', 'iki'],
            local: 'pira rega iki',
            displayLocal: 'Pira rega iki?',
            translation: 'Berapa harga ini?',
          ),
        ],
      ),
      _UnitSeed(
        unitNo: 5,
        title: 'Arah, Tempat & Perjalanan',
        description:
            'Unit ini mengenalkan tempat, arah, dan kalimat perjalanan sederhana dalam Bahasa Jawa.',
        level1Title: 'Tempat Dasar',
        level2Title: 'Cocokkan Arah & Perjalanan',
        level3Title: 'Susun Kalimat Perjalanan',
        level4Title: 'Terjemahkan Kalimat Perjalanan',
        level5Title: 'Ujian Arah, Tempat & Perjalanan',
        level1Words: [
          _WordSeed(
            id: 'omah',
            local: 'omah',
            meaning: 'rumah',
            partOfSpeech: 'noun',
            topicTags: ['tempat'],
          ),
          _WordSeed(
            id: 'sekolah',
            local: 'sekolah',
            meaning: 'sekolah',
            partOfSpeech: 'noun',
            topicTags: ['tempat'],
          ),
          _WordSeed(
            id: 'pasar',
            local: 'pasar',
            meaning: 'pasar',
            partOfSpeech: 'noun',
            topicTags: ['tempat'],
          ),
          _WordSeed(
            id: 'dalan',
            local: 'dalan',
            meaning: 'jalan',
            partOfSpeech: 'noun',
            topicTags: ['tempat'],
          ),
          _WordSeed(
            id: 'menyang',
            local: 'menyang',
            meaning: 'ke',
            partOfSpeech: 'preposition',
            topicTags: ['arah'],
          ),
        ],
        matchingWords: [
          _WordSeed(
            id: 'kiwa',
            local: 'kiwa',
            meaning: 'kiri',
            partOfSpeech: 'direction',
            topicTags: ['arah'],
          ),
          _WordSeed(
            id: 'tengen',
            local: 'tengen',
            meaning: 'kanan',
            partOfSpeech: 'direction',
            topicTags: ['arah'],
          ),
          _WordSeed(
            id: 'ngarep',
            local: 'ngarep',
            meaning: 'depan',
            partOfSpeech: 'direction',
            topicTags: ['arah'],
          ),
          _WordSeed(
            id: 'mburi',
            local: 'mburi',
            meaning: 'belakang',
            partOfSpeech: 'direction',
            topicTags: ['arah'],
          ),
          _WordSeed(
            id: 'lunga',
            local: 'lunga',
            meaning: 'pergi',
            partOfSpeech: 'verb',
            topicTags: ['perjalanan'],
          ),
          _WordSeed(
            id: 'teka',
            local: 'teka',
            meaning: 'datang',
            partOfSpeech: 'verb',
            topicTags: ['perjalanan'],
          ),
          _WordSeed(
            id: 'mlaku',
            local: 'mlaku',
            meaning: 'berjalan',
            partOfSpeech: 'verb',
            topicTags: ['perjalanan'],
          ),
        ],
        extraWords: [
          _WordSeed(
            id: 'ibu',
            local: 'ibu',
            meaning: 'ibu',
            partOfSpeech: 'noun',
            topicTags: ['keluarga'],
          ),
          _WordSeed(
            id: 'kanca',
            local: 'kanca',
            meaning: 'teman',
            partOfSpeech: 'noun',
            topicTags: ['orang_sekitar'],
          ),
        ],
        sentences: [
          _SentenceSeed(
            words: ['aku', 'menyang', 'sekolah'],
            local: 'aku menyang sekolah',
            displayLocal: 'Aku menyang sekolah.',
            translation: 'Saya ke sekolah.',
          ),
          _SentenceSeed(
            words: ['ibu', 'menyang', 'pasar'],
            local: 'ibu menyang pasar',
            displayLocal: 'Ibu menyang pasar.',
            translation: 'Ibu ke pasar.',
          ),
          _SentenceSeed(
            words: ['kanca', 'aku', 'teka'],
            local: 'kanca aku teka',
            displayLocal: 'Kanca aku teka.',
            translation: 'Teman saya datang.',
          ),
        ],
      ),
      _UnitSeed(
        unitNo: 6,
        title: 'Budaya & Percakapan Harian',
        description:
            'Unit ini berisi ungkapan sehari-hari, budaya lokal, dan review percakapan Bahasa Jawa.',
        level1Title: 'Ungkapan Sopan Harian',
        level2Title: 'Cocokkan Percakapan & Budaya',
        level3Title: 'Susun Kalimat Percakapan',
        level4Title: 'Terjemahkan Kalimat Percakapan',
        level5Title: 'Ujian Akhir Bahasa Jawa',
        level1Words: [
          _WordSeed(
            id: 'monggo',
            local: 'monggo',
            meaning: 'silakan',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['kesopanan'],
          ),
          _WordSeed(
            id: 'ngapura',
            local: 'ngapura',
            meaning: 'maaf',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['kesopanan'],
          ),
          _WordSeed(
            id: 'sugeng_rawuh',
            local: 'sugeng rawuh',
            meaning: 'selamat datang',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['sapaan'],
          ),
          _WordSeed(
            id: 'ati_ati',
            local: 'ati-ati',
            meaning: 'hati-hati',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['percakapan'],
          ),
          _WordSeed(
            id: 'mugi',
            local: 'mugi',
            meaning: 'semoga',
            partOfSpeech: 'expression',
            topicTags: ['percakapan'],
          ),
        ],
        matchingWords: [
          _WordSeed(
            id: 'bener',
            local: 'bener',
            meaning: 'benar',
            partOfSpeech: 'adjective',
            topicTags: ['percakapan'],
          ),
          _WordSeed(
            id: 'kabeh',
            local: 'kabeh',
            meaning: 'semuanya',
            partOfSpeech: 'pronoun',
            topicTags: ['percakapan'],
          ),
          _WordSeed(
            id: 'ngobrol',
            local: 'ngobrol',
            meaning: 'mengobrol',
            partOfSpeech: 'verb',
            topicTags: ['percakapan'],
          ),
          _WordSeed(
            id: 'crita',
            local: 'crita',
            meaning: 'cerita',
            partOfSpeech: 'noun',
            topicTags: ['budaya'],
          ),
          _WordSeed(
            id: 'adat',
            local: 'adat',
            meaning: 'adat',
            partOfSpeech: 'noun',
            topicTags: ['budaya'],
          ),
          _WordSeed(
            id: 'sopan',
            local: 'sopan',
            meaning: 'sopan',
            partOfSpeech: 'adjective',
            topicTags: ['budaya'],
          ),
        ],
        extraWords: [
          _WordSeed(
            id: 'mlebu',
            local: 'mlebu',
            meaning: 'masuk',
            partOfSpeech: 'verb',
            topicTags: ['percakapan'],
          ),
          _WordSeed(
            id: 'karo',
            local: 'karo',
            meaning: 'dengan',
            partOfSpeech: 'preposition',
            topicTags: ['percakapan'],
          ),
          _WordSeed(
            id: 'kudu',
            local: 'kudu',
            meaning: 'harus',
            partOfSpeech: 'modal',
            topicTags: ['percakapan'],
          ),
          _WordSeed(
            id: 'sehat',
            local: 'sehat',
            meaning: 'sehat',
            partOfSpeech: 'adjective',
            topicTags: ['kabar'],
          ),
          _WordSeed(
            id: 'kanca',
            local: 'kanca',
            meaning: 'teman',
            partOfSpeech: 'noun',
            topicTags: ['orang_sekitar'],
          ),
        ],
        sentences: [
          _SentenceSeed(
            words: ['monggo', 'mlebu'],
            local: 'monggo mlebu',
            displayLocal: 'Monggo mlebu.',
            translation: 'Silakan masuk.',
          ),
          _SentenceSeed(
            words: ['mugi', 'sehat'],
            local: 'mugi sehat',
            displayLocal: 'Mugi sehat.',
            translation: 'Semoga sehat.',
            extraAcceptedAnswers: ['Semoga baik.', 'semoga baik'],
          ),
          _SentenceSeed(
            words: ['kowe', 'kudu', 'sopan'],
            local: 'kowe kudu sopan',
            displayLocal: 'Kowe kudu sopan.',
            translation: 'Kamu harus sopan.',
            extraAcceptedAnswers: ['Anda harus sopan.', 'anda harus sopan'],
          ),
        ],
      ),
    ],
  );
}

_LanguageSeed _batakTobaSeed() {
  return const _LanguageSeed(
    id: 'batak_toba',
    name: 'Bahasa Batak Toba',
    nativeName: 'Hata Batak Toba',
    shortName: 'Batak Toba',
    region: 'Sumatra Utara',
    sourceName: 'Kamus Bahasa Batak Toba - Op Faustin Panjaitan',
    sourceUrl: 'PDF lokal: kamus-bahasa-batak (1).pdf',
    license: 'Terbatas - subset kurasi pembelajaran internal',
    seedVersion: 1,
    units: [
      _UnitSeed(
        unitNo: 1,
        title: 'Sapaan & Perkenalan',
        description:
            'Unit ini mengenalkan sapaan, kata ganti, dan perkenalan dasar dalam Bahasa Batak Toba.',
        level1Title: 'Sapaan Dasar',
        level2Title: 'Cocokkan Kata Ganti',
        level3Title: 'Susun Kalimat Perkenalan',
        level4Title: 'Terjemahkan Sapaan',
        level5Title: 'Review Sapaan & Perkenalan',
        level1Words: [
          _WordSeed(
            id: 'horas',
            local: 'horas',
            meaning: 'salam',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['sapaan', 'kesopanan'],
            exampleLocal: 'Horas, ale.',
            exampleId: 'Salam, teman.',
          ),
          _WordSeed(
            id: 'tabe',
            local: 'tabe',
            meaning: 'salam',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['sapaan', 'kesopanan'],
          ),
          _WordSeed(
            id: 'ampu',
            local: 'ampu',
            meaning: 'terima kasih',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['sapaan', 'kesopanan'],
          ),
          _WordSeed(
            id: 'anju',
            local: 'anju',
            meaning: 'maaf',
            type: 'expression',
            partOfSpeech: 'expression',
            topicTags: ['sapaan', 'kesopanan'],
          ),
          _WordSeed(
            id: 'ale',
            local: 'ale',
            meaning: 'teman',
            partOfSpeech: 'noun',
            topicTags: ['sapaan', 'orang_sekitar'],
          ),
        ],
        matchingWords: [
          _WordSeed(
            id: 'ahu',
            local: 'ahu',
            meaning: 'saya',
            partOfSpeech: 'pronoun',
            topicTags: ['perkenalan', 'kata_ganti'],
          ),
          _WordSeed(
            id: 'ho',
            local: 'ho',
            meaning: 'kamu',
            partOfSpeech: 'pronoun',
            topicTags: ['perkenalan', 'kata_ganti'],
          ),
          _WordSeed(
            id: 'hami',
            local: 'hami',
            meaning: 'kami',
            partOfSpeech: 'pronoun',
            topicTags: ['perkenalan', 'kata_ganti'],
          ),
          _WordSeed(
            id: 'goar',
            local: 'goar',
            meaning: 'nama',
            partOfSpeech: 'noun',
            topicTags: ['perkenalan'],
          ),
          _WordSeed(
            id: 'sian',
            local: 'sian',
            meaning: 'dari',
            partOfSpeech: 'preposition',
            topicTags: ['perkenalan', 'arah'],
          ),
        ],
        extraWords: [
          _WordSeed(
            id: 'aha',
            local: 'aha',
            meaning: 'apa',
            partOfSpeech: 'question',
            topicTags: ['percakapan'],
          ),
          _WordSeed(
            id: 'ise',
            local: 'ise',
            meaning: 'siapa',
            partOfSpeech: 'question',
            topicTags: ['percakapan'],
          ),
          _WordSeed(
            id: 'didia',
            local: 'didia',
            meaning: 'di mana',
            partOfSpeech: 'question',
            topicTags: ['percakapan', 'tempat'],
          ),
          _WordSeed(
            id: 'toba',
            local: 'Toba',
            meaning: 'Toba',
            partOfSpeech: 'noun',
            topicTags: ['tempat', 'identitas'],
          ),
        ],
        sentences: [
          _SentenceSeed(
            words: ['ahu', 'sian', 'Toba'],
            local: 'ahu sian Toba',
            displayLocal: 'Ahu sian Toba.',
            translation: 'Saya dari Toba.',
          ),
          _SentenceSeed(
            words: ['goar', 'ahu', 'Loka'],
            local: 'goar ahu Loka',
            displayLocal: 'Goar ahu Loka.',
            translation: 'Nama saya Loka.',
          ),
          _SentenceSeed(
            words: ['horas', 'ale'],
            local: 'horas ale',
            displayLocal: 'Horas, ale.',
            translation: 'Salam, teman.',
          ),
        ],
      ),
      _UnitSeed(
        unitNo: 2,
        title: 'Keluarga & Orang Sekitar',
        description:
            'Unit ini mengenalkan kosakata keluarga, orang sekitar, dan sifat sederhana dalam Bahasa Batak Toba.',
        level1Title: 'Anggota Keluarga',
        level2Title: 'Cocokkan Orang Sekitar',
        level3Title: 'Susun Kalimat Keluarga',
        level4Title: 'Terjemahkan Kalimat Keluarga',
        level5Title: 'Ujian Keluarga & Orang Sekitar',
        level1Words: [
          _WordSeed(
            id: 'amang',
            local: 'amang',
            meaning: 'ayah',
            partOfSpeech: 'noun',
            topicTags: ['keluarga'],
          ),
          _WordSeed(
            id: 'inang',
            local: 'inang',
            meaning: 'ibu',
            partOfSpeech: 'noun',
            topicTags: ['keluarga'],
          ),
          _WordSeed(
            id: 'angkang',
            local: 'angkang',
            meaning: 'kakak',
            partOfSpeech: 'noun',
            topicTags: ['keluarga'],
          ),
          _WordSeed(
            id: 'anggi',
            local: 'anggi',
            meaning: 'adik',
            partOfSpeech: 'noun',
            topicTags: ['keluarga'],
          ),
          _WordSeed(
            id: 'boru',
            local: 'boru',
            meaning: 'putri',
            partOfSpeech: 'noun',
            topicTags: ['keluarga'],
          ),
        ],
        matchingWords: [
          _WordSeed(
            id: 'dongan',
            local: 'dongan',
            meaning: 'teman',
            partOfSpeech: 'noun',
            topicTags: ['orang_sekitar'],
          ),
          _WordSeed(
            id: 'halak',
            local: 'halak',
            meaning: 'orang',
            partOfSpeech: 'noun',
            topicTags: ['orang_sekitar'],
          ),
          _WordSeed(
            id: 'guru',
            local: 'guru',
            meaning: 'guru',
            partOfSpeech: 'noun',
            topicTags: ['orang_sekitar'],
          ),
          _WordSeed(
            id: 'burju',
            local: 'burju',
            meaning: 'baik',
            partOfSpeech: 'adjective',
            topicTags: ['sifat'],
          ),
          _WordSeed(
            id: 'pistar',
            local: 'pistar',
            meaning: 'pintar',
            partOfSpeech: 'adjective',
            topicTags: ['sifat'],
          ),
        ],
        extraWords: [
          _WordSeed(
            id: 'on',
            local: 'on',
            meaning: 'ini',
            partOfSpeech: 'demonstrative',
            topicTags: ['kalimat_dasar'],
          ),
          _WordSeed(
            id: 'nasa',
            local: 'nasa',
            meaning: 'semua',
            partOfSpeech: 'pronoun',
            topicTags: ['kalimat_dasar'],
          ),
        ],
        sentences: [
          _SentenceSeed(
            words: ['on', 'amang', 'ahu'],
            local: 'on amang ahu',
            displayLocal: 'On amang ahu.',
            translation: 'Ini ayah saya.',
          ),
          _SentenceSeed(
            words: ['on', 'dongan', 'ahu'],
            local: 'on dongan ahu',
            displayLocal: 'On dongan ahu.',
            translation: 'Ini teman saya.',
          ),
          _SentenceSeed(
            words: ['dongan', 'ahu', 'burju'],
            local: 'dongan ahu burju',
            displayLocal: 'Dongan ahu burju.',
            translation: 'Teman saya baik.',
          ),
        ],
      ),
      _UnitSeed(
        unitNo: 3,
        title: 'Angka, Waktu & Hari',
        description:
            'Unit ini mengenalkan angka, hari, dan waktu sederhana dalam Bahasa Batak Toba.',
        level1Title: 'Angka Dasar',
        level2Title: 'Cocokkan Waktu Sederhana',
        level3Title: 'Susun Kalimat Waktu',
        level4Title: 'Terjemahkan Kalimat Waktu',
        level5Title: 'Ujian Angka, Waktu & Hari',
        level1Words: [
          _WordSeed(
            id: 'sada',
            local: 'sada',
            meaning: 'satu',
            partOfSpeech: 'number',
            topicTags: ['angka'],
          ),
          _WordSeed(
            id: 'dua',
            local: 'dua',
            meaning: 'dua',
            partOfSpeech: 'number',
            topicTags: ['angka'],
          ),
          _WordSeed(
            id: 'tolu',
            local: 'tolu',
            meaning: 'tiga',
            partOfSpeech: 'number',
            topicTags: ['angka'],
          ),
          _WordSeed(
            id: 'onom',
            local: 'onom',
            meaning: 'enam',
            partOfSpeech: 'number',
            topicTags: ['angka'],
          ),
          _WordSeed(
            id: 'pitu',
            local: 'pitu',
            meaning: 'tujuh',
            partOfSpeech: 'number',
            topicTags: ['angka'],
          ),
          _WordSeed(
            id: 'sampulu',
            local: 'sampulu',
            meaning: 'sepuluh',
            partOfSpeech: 'number',
            topicTags: ['angka'],
          ),
        ],
        matchingWords: [
          _WordSeed(
            id: 'ari',
            local: 'ari',
            meaning: 'hari',
            partOfSpeech: 'noun',
            topicTags: ['waktu'],
          ),
          _WordSeed(
            id: 'sadari',
            local: 'sadari',
            meaning: 'sehari',
            partOfSpeech: 'noun',
            topicTags: ['waktu'],
          ),
          _WordSeed(
            id: 'borngin',
            local: 'borngin',
            meaning: 'malam',
            partOfSpeech: 'noun',
            topicTags: ['waktu'],
          ),
          _WordSeed(
            id: 'nangkin',
            local: 'nangkin',
            meaning: 'tadi',
            partOfSpeech: 'adverb',
            topicTags: ['waktu'],
          ),
          _WordSeed(
            id: 'annon',
            local: 'annon',
            meaning: 'nanti',
            partOfSpeech: 'adverb',
            topicTags: ['waktu'],
          ),
          _WordSeed(
            id: 'taon',
            local: 'taon',
            meaning: 'tahun',
            partOfSpeech: 'noun',
            topicTags: ['waktu'],
          ),
        ],
        extraWords: [
          _WordSeed(
            id: 'jaha',
            local: 'jaha',
            meaning: 'baca',
            partOfSpeech: 'verb',
            topicTags: ['aktivitas'],
          ),
          _WordSeed(
            id: 'dalan',
            local: 'dalan',
            meaning: 'jalan',
            partOfSpeech: 'noun',
            topicTags: ['tempat'],
          ),
          _WordSeed(
            id: 'huta',
            local: 'huta',
            meaning: 'kampung',
            partOfSpeech: 'noun',
            topicTags: ['tempat'],
          ),
        ],
        sentences: [
          _SentenceSeed(
            words: ['sada', 'ari'],
            local: 'sada ari',
            displayLocal: 'Sada ari.',
            translation: 'Satu hari.',
          ),
          _SentenceSeed(
            words: ['borngin', 'ahu', 'jaha'],
            local: 'borngin ahu jaha',
            displayLocal: 'Borngin ahu jaha.',
            translation: 'Malam saya membaca.',
          ),
          _SentenceSeed(
            words: ['annon', 'ahu', 'tu', 'huta'],
            local: 'annon ahu tu huta',
            displayLocal: 'Annon ahu tu huta.',
            translation: 'Nanti saya ke kampung.',
          ),
        ],
      ),
      _UnitSeed(
        unitNo: 4,
        title: 'Makanan & Belanja',
        description:
            'Unit ini mengenalkan kosakata makanan, minuman, dan belanja sederhana dalam Bahasa Batak Toba.',
        level1Title: 'Makanan Dasar',
        level2Title: 'Cocokkan Belanja Sederhana',
        level3Title: 'Susun Kalimat Makanan',
        level4Title: 'Terjemahkan Kalimat Makanan',
        level5Title: 'Ujian Makanan & Belanja',
        level1Words: [
          _WordSeed(
            id: 'mangan',
            local: 'mangan',
            meaning: 'makan',
            partOfSpeech: 'verb',
            topicTags: ['makanan'],
          ),
          _WordSeed(
            id: 'minum',
            local: 'minum',
            meaning: 'minum',
            partOfSpeech: 'verb',
            topicTags: ['minuman'],
          ),
          _WordSeed(
            id: 'aek',
            local: 'aek',
            meaning: 'air',
            partOfSpeech: 'noun',
            topicTags: ['minuman'],
          ),
          _WordSeed(
            id: 'boras',
            local: 'boras',
            meaning: 'beras',
            partOfSpeech: 'noun',
            topicTags: ['makanan'],
          ),
          _WordSeed(
            id: 'dengke',
            local: 'dengke',
            meaning: 'ikan',
            partOfSpeech: 'noun',
            topicTags: ['makanan'],
          ),
        ],
        matchingWords: [
          _WordSeed(
            id: 'tuhor',
            local: 'tuhor',
            meaning: 'beli',
            partOfSpeech: 'verb',
            topicTags: ['belanja'],
          ),
          _WordSeed(
            id: 'onan',
            local: 'onan',
            meaning: 'pasar',
            partOfSpeech: 'noun',
            topicTags: ['belanja', 'tempat'],
          ),
          _WordSeed(
            id: 'hepeng',
            local: 'hepeng',
            meaning: 'uang',
            partOfSpeech: 'noun',
            topicTags: ['belanja'],
          ),
          _WordSeed(
            id: 'arga',
            local: 'arga',
            meaning: 'harga',
            partOfSpeech: 'noun',
            topicTags: ['belanja'],
          ),
          _WordSeed(
            id: 'lapat',
            local: 'lapat',
            meaning: 'arti',
            partOfSpeech: 'noun',
            topicTags: ['percakapan'],
          ),
          _WordSeed(
            id: 'tabo',
            local: 'tabo',
            meaning: 'enak',
            partOfSpeech: 'adjective',
            topicTags: ['rasa'],
          ),
        ],
        extraWords: [
          _WordSeed(
            id: 'lapo',
            local: 'lapo',
            meaning: 'warung',
            partOfSpeech: 'noun',
            topicTags: ['belanja', 'tempat'],
          ),
          _WordSeed(
            id: 'pira',
            local: 'pira',
            meaning: 'telur',
            partOfSpeech: 'noun',
            topicTags: ['makanan'],
          ),
        ],
        sentences: [
          _SentenceSeed(
            words: ['ahu', 'mangan', 'dengke'],
            local: 'ahu mangan dengke',
            displayLocal: 'Ahu mangan dengke.',
            translation: 'Saya makan ikan.',
          ),
          _SentenceSeed(
            words: ['ahu', 'minum', 'aek'],
            local: 'ahu minum aek',
            displayLocal: 'Ahu minum aek.',
            translation: 'Saya minum air.',
          ),
          _SentenceSeed(
            words: ['ahu', 'tuhor', 'boras'],
            local: 'ahu tuhor boras',
            displayLocal: 'Ahu tuhor boras.',
            translation: 'Saya membeli beras.',
          ),
        ],
      ),
      _UnitSeed(
        unitNo: 5,
        title: 'Arah, Tempat & Perjalanan',
        description:
            'Unit ini mengenalkan kosakata tempat, arah, dan perjalanan sederhana dalam Bahasa Batak Toba.',
        level1Title: 'Tempat Dasar',
        level2Title: 'Cocokkan Arah & Perjalanan',
        level3Title: 'Susun Kalimat Perjalanan',
        level4Title: 'Terjemahkan Kalimat Perjalanan',
        level5Title: 'Ujian Arah, Tempat & Perjalanan',
        level1Words: [
          _WordSeed(
            id: 'bagas',
            local: 'bagas',
            meaning: 'rumah',
            partOfSpeech: 'noun',
            topicTags: ['tempat'],
          ),
          _WordSeed(
            id: 'ruma',
            local: 'ruma',
            meaning: 'rumah Batak',
            partOfSpeech: 'noun',
            topicTags: ['tempat', 'budaya'],
          ),
          _WordSeed(
            id: 'huta',
            local: 'huta',
            meaning: 'kampung',
            partOfSpeech: 'noun',
            topicTags: ['tempat'],
          ),
          _WordSeed(
            id: 'dalan',
            local: 'dalan',
            meaning: 'jalan',
            partOfSpeech: 'noun',
            topicTags: ['tempat'],
          ),
          _WordSeed(
            id: 'tao',
            local: 'tao',
            meaning: 'danau',
            partOfSpeech: 'noun',
            topicTags: ['tempat'],
          ),
        ],
        matchingWords: [
          _WordSeed(
            id: 'hambirang',
            local: 'hambirang',
            meaning: 'kiri',
            partOfSpeech: 'direction',
            topicTags: ['arah'],
          ),
          _WordSeed(
            id: 'siamun',
            local: 'siamun',
            meaning: 'kanan',
            partOfSpeech: 'direction',
            topicTags: ['arah'],
          ),
          _WordSeed(
            id: 'jolo',
            local: 'jolo',
            meaning: 'depan',
            partOfSpeech: 'direction',
            topicTags: ['arah'],
          ),
          _WordSeed(
            id: 'pudi',
            local: 'pudi',
            meaning: 'belakang',
            partOfSpeech: 'direction',
            topicTags: ['arah'],
          ),
          _WordSeed(
            id: 'laho',
            local: 'laho',
            meaning: 'pergi',
            partOfSpeech: 'verb',
            topicTags: ['perjalanan'],
          ),
          _WordSeed(
            id: 'mulak',
            local: 'mulak',
            meaning: 'pulang',
            partOfSpeech: 'verb',
            topicTags: ['perjalanan'],
          ),
          _WordSeed(
            id: 'jumpang',
            local: 'jumpang',
            meaning: 'ketemu',
            partOfSpeech: 'verb',
            topicTags: ['perjalanan'],
          ),
        ],
        extraWords: [
          _WordSeed(
            id: 'tu',
            local: 'tu',
            meaning: 'ke',
            partOfSpeech: 'preposition',
            topicTags: ['arah'],
          ),
          _WordSeed(
            id: 'sian',
            local: 'sian',
            meaning: 'dari',
            partOfSpeech: 'preposition',
            topicTags: ['arah'],
          ),
        ],
        sentences: [
          _SentenceSeed(
            words: ['ahu', 'laho', 'tu', 'huta'],
            local: 'ahu laho tu huta',
            displayLocal: 'Ahu laho tu huta.',
            translation: 'Saya pergi ke kampung.',
          ),
          _SentenceSeed(
            words: ['bagas', 'di', 'jolo'],
            local: 'bagas di jolo',
            displayLocal: 'Bagas di jolo.',
            translation: 'Rumah di depan.',
          ),
          _SentenceSeed(
            words: ['ahu', 'mulak', 'sian', 'onan'],
            local: 'ahu mulak sian onan',
            displayLocal: 'Ahu mulak sian onan.',
            translation: 'Saya pulang dari pasar.',
          ),
        ],
      ),
      _UnitSeed(
        unitNo: 6,
        title: 'Budaya & Percakapan Harian',
        description:
            'Unit ini mengenalkan kosakata budaya Batak Toba, adat, dan percakapan harian.',
        level1Title: 'Budaya Dasar',
        level2Title: 'Cocokkan Adat & Percakapan',
        level3Title: 'Susun Kalimat Budaya',
        level4Title: 'Terjemahkan Kalimat Budaya',
        level5Title: 'Ujian Akhir Bahasa Batak Toba',
        level1Words: [
          _WordSeed(
            id: 'hata',
            local: 'hata',
            meaning: 'bahasa',
            partOfSpeech: 'noun',
            topicTags: ['budaya', 'percakapan'],
          ),
          _WordSeed(
            id: 'adat',
            local: 'adat',
            meaning: 'adat',
            partOfSpeech: 'noun',
            topicTags: ['budaya'],
          ),
          _WordSeed(
            id: 'ulos',
            local: 'ulos',
            meaning: 'kain tenun Batak',
            partOfSpeech: 'noun',
            topicTags: ['budaya'],
          ),
          _WordSeed(
            id: 'tortor',
            local: 'tortor',
            meaning: 'tarian Batak',
            partOfSpeech: 'noun',
            topicTags: ['budaya'],
          ),
          _WordSeed(
            id: 'gondang',
            local: 'gondang',
            meaning: 'musik tradisional Batak',
            partOfSpeech: 'noun',
            topicTags: ['budaya'],
          ),
        ],
        matchingWords: [
          _WordSeed(
            id: 'poda',
            local: 'poda',
            meaning: 'nasehat',
            partOfSpeech: 'noun',
            topicTags: ['percakapan', 'budaya'],
          ),
          _WordSeed(
            id: 'tangiang',
            local: 'tangiang',
            meaning: 'doa',
            partOfSpeech: 'noun',
            topicTags: ['percakapan', 'budaya'],
          ),
          _WordSeed(
            id: 'umpasa',
            local: 'umpasa',
            meaning: 'pantun',
            partOfSpeech: 'noun',
            topicTags: ['budaya'],
          ),
          _WordSeed(
            id: 'ugari',
            local: 'ugari',
            meaning: 'budaya',
            partOfSpeech: 'noun',
            topicTags: ['budaya'],
          ),
          _WordSeed(
            id: 'tutu',
            local: 'tutu',
            meaning: 'benar',
            partOfSpeech: 'adjective',
            topicTags: ['percakapan'],
          ),
          _WordSeed(
            id: 'uli',
            local: 'uli',
            meaning: 'bagus',
            partOfSpeech: 'adjective',
            topicTags: ['percakapan', 'budaya'],
          ),
        ],
        extraWords: [
          _WordSeed(
            id: 'batak',
            local: 'Batak',
            meaning: 'Batak',
            partOfSpeech: 'noun',
            topicTags: ['identitas', 'budaya'],
          ),
          _WordSeed(
            id: 'somba',
            local: 'somba',
            meaning: 'sembah',
            partOfSpeech: 'verb',
            topicTags: ['budaya'],
          ),
          _WordSeed(
            id: 'asa',
            local: 'asa',
            meaning: 'supaya',
            partOfSpeech: 'conjunction',
            topicTags: ['kalimat_dasar'],
          ),
        ],
        sentences: [
          _SentenceSeed(
            words: ['hata', 'Batak', 'uli'],
            local: 'hata Batak uli',
            displayLocal: 'Hata Batak uli.',
            translation: 'Bahasa Batak bagus.',
          ),
          _SentenceSeed(
            words: ['ulos', 'Batak', 'uli'],
            local: 'ulos Batak uli',
            displayLocal: 'Ulos Batak uli.',
            translation: 'Ulos Batak bagus.',
          ),
          _SentenceSeed(
            words: ['poda', 'i', 'tutu'],
            local: 'poda i tutu',
            displayLocal: 'Poda i tutu.',
            translation: 'Nasehat itu benar.',
          ),
        ],
      ),
    ],
  );
}

