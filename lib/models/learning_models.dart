class LessonItem {
  const LessonItem({
    required this.localText,
    required this.glossText,
    required this.exampleText,
    required this.topic,
  });

  final String localText;
  final String glossText;
  final String exampleText;
  final String topic;

  factory LessonItem.fromMap(Map<String, dynamic> map) {
    return LessonItem(
      localText: map['localText']?.toString() ?? '',
      glossText: map['glossText']?.toString() ??
          map['primaryMeaningId']?.toString() ??
          '',
      exampleText: map['exampleText']?.toString() ??
          map['exampleId']?.toString() ??
          '',
      topic: map['topic']?.toString() ??
          _firstStringFromList(map['topicTags']) ??
          'Umum',
    );
  }

  factory LessonItem.fromDictionaryMap(Map<String, dynamic> map) {
    return LessonItem(
      localText: map['localText']?.toString() ?? '',
      glossText: map['primaryMeaningId']?.toString() ??
          _firstStringFromList(map['meaningsId']) ??
          '',
      exampleText: map['exampleId']?.toString() ?? '',
      topic: _firstStringFromList(map['topicTags']) ?? 'Umum',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'localText': localText,
      'glossText': glossText,
      'exampleText': exampleText,
      'topic': topic,
    };
  }
}

class MatchingPair {
  const MatchingPair({
    required this.left,
    required this.right,
  });

  final String left;
  final String right;

  factory MatchingPair.fromMap(Map<String, dynamic> map) {
    return MatchingPair(
      left: map['left']?.toString() ?? '',
      right: map['right']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'left': left,
      'right': right,
    };
  }
}

class LessonActivity {
  const LessonActivity({
    required this.id,
    required this.type,
    required this.prompt,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.pairs,
    required this.words,
    required this.translationId,
    required this.sentenceLocal,
    required this.acceptedAnswers,
  });

  final String id;
  final String type;
  final String prompt;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final List<MatchingPair> pairs;
  final List<String> words;
  final String translationId;
  final String sentenceLocal;
  final List<String> acceptedAnswers;

  bool get isMultipleChoice => type == 'multiple_choice';
  bool get isMatching => type == 'matching';
  bool get isArrangeSentence => type == 'arrange_sentence';
  bool get isTranslateSentence => type == 'translate_sentence';

  factory LessonActivity.fromMap(Map<String, dynamic> map) {
    return LessonActivity(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'multiple_choice',
      prompt: map['prompt']?.toString() ?? '',
      options: _stringList(map['options']),
      correctAnswer: map['correctAnswer']?.toString() ?? '',
      explanation: map['explanation']?.toString() ?? '',
      pairs: _pairList(map['pairs']),
      words: _stringList(map['words']),
      translationId: map['translationId']?.toString() ?? '',
      sentenceLocal: map['sentenceLocal']?.toString() ?? '',
      acceptedAnswers: _stringList(map['acceptedAnswers']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'prompt': prompt,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'pairs': pairs.map((pair) => pair.toMap()).toList(),
      'words': words,
      'translationId': translationId,
      'sentenceLocal': sentenceLocal,
      'acceptedAnswers': acceptedAnswers,
    };
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id']?.toString() ?? '',
      prompt: map['prompt']?.toString() ?? '',
      options: _stringList(map['options']),
      correctAnswer: map['correctAnswer']?.toString() ?? '',
      explanation: map['explanation']?.toString() ?? '',
    );
  }

  bool isCorrect(String answer) {
    return answer.trim().toLowerCase() ==
        correctAnswer.trim().toLowerCase();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prompt': prompt,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }
}

class LessonData {
  LessonData({
    required this.id,
    required this.languageId,
    required this.languageName,
    required this.region,
    required this.levelNo,
    required this.unitNo,
    required this.title,
    required this.theme,
    required this.description,
    required this.objective,
    required this.xpReward,
    required this.requiredScore,
    required this.items,
    required this.activities,
    List<QuizQuestion>? questions,
  }) : questions = questions ?? _questionsFromActivities(activities);

  final String id;
  final String languageId;
  final String languageName;
  final String region;
  final int levelNo;
  final int unitNo;
  final String title;
  final String theme;
  final String description;
  final String objective;
  final int xpReward;
  final int requiredScore;
  final List<LessonItem> items;
  final List<LessonActivity> activities;

  /// Untuk sementara ini masih dipakai oleh QuizPage lama.
  /// Nanti setelah QuizPage kita ubah menjadi activity engine,
  /// field ini bisa tidak dipakai lagi.
  final List<QuizQuestion> questions;

  factory LessonData.fromMap(Map<String, dynamic> map) {
    final activities = _activityList(map['activities']);

    final oldQuestions = _questionList(map['questions']);

    return LessonData(
      id: map['id']?.toString() ?? '',
      languageId: map['languageId']?.toString() ?? '',
      languageName: map['languageName']?.toString() ?? '',
      region: map['region']?.toString() ?? '',
      levelNo: _readInt(map['levelNo'], 1),
      unitNo: _readInt(map['unitNo'], 1),
      title: map['title']?.toString() ?? '',
      theme: map['theme']?.toString() ?? '',
      description: map['description']?.toString() ??
          map['objective']?.toString() ??
          '',
      objective: map['objective']?.toString() ??
          map['description']?.toString() ??
          '',
      xpReward: _readInt(map['xpReward'], 20),
      requiredScore: _readInt(map['requiredScore'], 70),
      items: _lessonItemList(map['items']),
      activities: activities,
      questions: oldQuestions.isNotEmpty
          ? oldQuestions
          : _questionsFromActivities(activities),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'languageId': languageId,
      'languageName': languageName,
      'region': region,
      'levelNo': levelNo,
      'unitNo': unitNo,
      'title': title,
      'theme': theme,
      'description': description,
      'objective': objective,
      'xpReward': xpReward,
      'requiredScore': requiredScore,
      'items': items.map((item) => item.toMap()).toList(),
      'activities': activities.map((activity) => activity.toMap()).toList(),
      'questions': questions.map((question) => question.toMap()).toList(),
    };
  }
}

class LessonCompletionResult {
  const LessonCompletionResult({
    required this.correctCount,
    required this.totalQuestions,
    required this.scorePct,
    required this.xpEarned,
    required this.streakDays,
    required this.alreadyCompleted,
    required this.isPassed,
    required this.heartsRemaining,
    required this.maxHearts,
    required this.heartsLost,
  });

  final int correctCount;
  final int totalQuestions;
  final int scorePct;
  final int xpEarned;
  final int streakDays;
  final bool alreadyCompleted;
  final bool isPassed;
  final int heartsRemaining;
  final int maxHearts;
  final int heartsLost;
}

String? _firstStringFromList(dynamic value) {
  if (value is! List || value.isEmpty) return null;
  return value.first?.toString();
}

int _readInt(dynamic value, int fallback) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

List<String> _stringList(dynamic value) {
  if (value is! List) return [];
  return value.map((item) => item.toString()).toList();
}

List<MatchingPair> _pairList(dynamic value) {
  if (value is! List) return [];

  return value
      .whereType<Map>()
      .map(
        (item) => MatchingPair.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList();
}

List<LessonActivity> _activityList(dynamic value) {
  if (value is! List) return [];

  return value
      .whereType<Map>()
      .map(
        (item) => LessonActivity.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList();
}

List<QuizQuestion> _questionList(dynamic value) {
  if (value is! List) return [];

  return value
      .whereType<Map>()
      .map(
        (item) => QuizQuestion.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList();
}

List<LessonItem> _lessonItemList(dynamic value) {
  if (value is! List) return [];

  return value
      .whereType<Map>()
      .map(
        (item) => LessonItem.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList();
}

List<QuizQuestion> _questionsFromActivities(
  List<LessonActivity> activities,
) {
  final questions = <QuizQuestion>[];

  for (final activity in activities) {
    if (activity.isMultipleChoice) {
      questions.add(
        QuizQuestion(
          id: activity.id,
          prompt: activity.prompt,
          options: activity.options,
          correctAnswer: activity.correctAnswer,
          explanation: activity.explanation,
        ),
      );
    }

    if (activity.isMatching) {
      final allAnswers = activity.pairs
          .map((pair) => pair.right)
          .where((answer) => answer.trim().isNotEmpty)
          .toSet()
          .toList();

      for (int i = 0; i < activity.pairs.length; i++) {
        final pair = activity.pairs[i];

        final options = {
          pair.right,
          ...allAnswers,
        }.toList();

        questions.add(
          QuizQuestion(
            id: '${activity.id}_pair_$i',
            prompt: "Apa arti dari '${pair.left}'?",
            options: options,
            correctAnswer: pair.right,
            explanation: "'${pair.left}' berarti '${pair.right}'.",
          ),
        );
      }
    }

    if (activity.isArrangeSentence) {
      final correct = activity.correctAnswer.trim();

      if (correct.isEmpty) continue;

      final reversed = activity.words.reversed.join(' ').trim();
      final alphabetical = [...activity.words]..sort();
      final alphabeticalText = alphabetical.join(' ').trim();

      final options = {
        correct,
        if (reversed.isNotEmpty && reversed != correct) reversed,
        if (alphabeticalText.isNotEmpty && alphabeticalText != correct)
          alphabeticalText,
        if (activity.translationId.isNotEmpty) activity.translationId,
      }.toList();

      questions.add(
        QuizQuestion(
          id: activity.id,
          prompt: activity.prompt,
          options: options,
          correctAnswer: correct,
          explanation: activity.explanation.isNotEmpty
              ? activity.explanation
              : 'Susunan yang benar adalah "$correct".',
        ),
      );
    }
  }

  return questions;
}