import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/learning_models.dart';
import '../../services/learning_service.dart';
import '../home.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({
    super.key,
    required this.lesson,
  });

  final LessonData lesson;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  static const Color bgColor = Color(0xFFF4F4F4);
  static const Color coral = Color(0xFFE2775B);
  static const Color green = Color(0xFF0F9D6C);
  static const Color textDark = Color(0xFF232248);
  static const Color muted = Color(0xFF7E7E99);

  late final TextEditingController _translateController;
  late List<LessonActivity> _activities;
  late final int _totalOriginalActivities;

  int _currentIndex = 0;
  int _heartsLostDuringQuiz = 0;
  bool _feedbackVisible = false;
  bool _lastAnswerCorrect = false;
  bool _isSaving = false;

  int _hearts = 5;
  int _maxHearts = 15;
  bool _isLoadingHearts = true;
  bool _cannotStartBecauseNoHearts = false;

  String? _selectedAnswer;

  List<String> _wordBank = [];
  List<String> _selectedWords = [];

  Map<String, String> _matchingAnswers = {};
  List<String> _matchingOptions = [];

  final Map<String, List<String>> _optionCache = {};

  final List<LessonActivity> _wrongActivities = [];

  bool _isReviewingWrongAnswers = false;
  bool _failedOnReview = false;

  int _firstRoundCorrectCount = 0;
  int _reviewCorrectCount = 0;

  LessonActivity get _activity => _activities[_currentIndex];

  bool get _isLastActivity => _currentIndex == _activities.length - 1;

  @override
  void initState() {
    super.initState();

    _translateController = TextEditingController();
    _activities = _prepareActivities();
    _totalOriginalActivities = _activities.length;

    if (_activities.isNotEmpty) {
      _setupCurrentActivity();
    }

    _loadHearts();
  }

  @override
  void dispose() {
    _translateController.dispose();
    super.dispose();
  }

  List<LessonActivity> _prepareActivities() {
    final sourceActivities = widget.lesson.activities;

    if (sourceActivities.isNotEmpty) {
      final activities = [...sourceActivities];
      activities.shuffle(math.Random());
      return activities;
    }

    final fallbackActivities = widget.lesson.questions.map((question) {
      final options = [...question.options];

      if (!options.contains(question.correctAnswer)) {
        options.add(question.correctAnswer);
      }

      return LessonActivity(
        id: question.id,
        type: 'multiple_choice',
        prompt: question.prompt,
        options: options,
        correctAnswer: question.correctAnswer,
        explanation: question.explanation,
        pairs: const [],
        words: const [],
        translationId: '',
        sentenceLocal: '',
        acceptedAnswers: const [],
      );
    }).toList();

    fallbackActivities.shuffle(math.Random());

    return fallbackActivities;
  }

  Future<void> _loadHearts() async {
    try {
      final heartsData = await LearningService().getUserHearts();

      if (!mounted) return;

      final loadedHearts = heartsData['hearts'] ?? 5;
      final loadedMaxHearts = heartsData['maxHearts'] ?? 15;

      setState(() {
        _maxHearts = loadedMaxHearts;
        _hearts = loadedHearts.clamp(0, loadedMaxHearts).toInt();
        _cannotStartBecauseNoHearts = _hearts <= 0;
        _isLoadingHearts = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _hearts = 5;
        _maxHearts = 15;
        _cannotStartBecauseNoHearts = false;
        _isLoadingHearts = false;
      });
    }
  }

  void _setupCurrentActivity() {
    final activity = _activity;

    _selectedAnswer = null;
    _feedbackVisible = false;
    _lastAnswerCorrect = false;
    _translateController.clear();

    _wordBank = [];
    _selectedWords = [];

    _matchingAnswers = {};
    _matchingOptions = [];

    if (activity.isArrangeSentence) {
      final words = activity.words.isNotEmpty
          ? [...activity.words]
          : activity.correctAnswer
              .split(' ')
              .where((word) => word.trim().isNotEmpty)
              .toList();

      words.shuffle(math.Random());

      _wordBank = words;
      _selectedWords = [];
    }

    if (activity.isMatching) {
      final options = activity.pairs
          .map((pair) => pair.right)
          .where((item) => item.trim().isNotEmpty)
          .toSet()
          .toList();

      options.shuffle(math.Random());

      _matchingOptions = options;
      _matchingAnswers = {};
    }
  }

  List<String> _optionsFor(LessonActivity activity) {
    return _optionCache.putIfAbsent(activity.id, () {
      final options = [...activity.options];

      if (activity.correctAnswer.trim().isNotEmpty &&
          !options.contains(activity.correctAnswer)) {
        options.add(activity.correctAnswer);
      }

      options.shuffle(math.Random());
      return options;
    });
  }

  String _activityTypeLabel(LessonActivity activity) {
    if (_isReviewingWrongAnswers) return 'Ulang Soal Salah';
    if (activity.isMultipleChoice) return 'Pilihan Ganda';
    if (activity.isArrangeSentence) return 'Susun Kalimat';
    if (activity.isTranslateSentence) return 'Terjemahkan';
    if (activity.isMatching) return 'Cocokkan';
    return 'Latihan';
  }

  String _correctAnswerText(LessonActivity activity) {
    if (activity.isMatching) {
      return activity.pairs
          .map((pair) => '${pair.left} = ${pair.right}')
          .join('\n');
    }

    return activity.correctAnswer;
  }

  String _normalizeAnswer(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[.!?]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _isTranslateCorrect(LessonActivity activity, String answer) {
    final normalizedAnswer = _normalizeAnswer(answer);

    final accepted = {
      activity.correctAnswer,
      ...activity.acceptedAnswers,
    }.map(_normalizeAnswer).toSet();

    return accepted.contains(normalizedAnswer);
  }

  Future<void> _checkAnswer() async {
    if (_hearts <= 0) {
      setState(() {
        _cannotStartBecauseNoHearts = true;
      });
      return;
    }

    final activity = _activity;

    bool isCorrect = false;

    if (activity.isMultipleChoice) {
      if (_selectedAnswer == null) {
        _showMessage('Pilih salah satu jawaban dulu.');
        return;
      }

      isCorrect = _normalizeAnswer(_selectedAnswer!) ==
          _normalizeAnswer(activity.correctAnswer);
    } else if (activity.isArrangeSentence) {
      if (_selectedWords.isEmpty) {
        _showMessage('Susun kata terlebih dahulu.');
        return;
      }

      final answer = _selectedWords.join(' ');
      isCorrect =
          _normalizeAnswer(answer) == _normalizeAnswer(activity.correctAnswer);
    } else if (activity.isTranslateSentence) {
      final answer = _translateController.text;

      if (answer.trim().isEmpty) {
        _showMessage('Tulis arti kalimat terlebih dahulu.');
        return;
      }

      isCorrect = _isTranslateCorrect(activity, answer);
    } else if (activity.isMatching) {
      if (_matchingAnswers.length < activity.pairs.length) {
        _showMessage('Lengkapi semua pasangan jawaban dulu.');
        return;
      }

      isCorrect = activity.pairs.every((pair) {
        return _matchingAnswers[pair.left] == pair.right;
      });
    } else {
      _showMessage('Tipe latihan ini belum didukung.');
      return;
    }

    setState(() {
      _lastAnswerCorrect = isCorrect;
      _feedbackVisible = true;

      if (isCorrect) {
        if (_isReviewingWrongAnswers) {
          _reviewCorrectCount++;
        } else {
          _firstRoundCorrectCount++;
        }
            } else {
        if (_isReviewingWrongAnswers) {
          _failedOnReview = true;
        } else {
          final alreadyStored =
              _wrongActivities.any((item) => item.id == activity.id);

          if (!alreadyStored) {
            _wrongActivities.add(activity);
          }
        }

        _heartsLostDuringQuiz++;
        _hearts = math.max(0, _hearts - 1); // update UI dulu, biar instan
      }
    });

    if (!isCorrect) {
      try {
        final result = await LearningService().deductHeartForWrongAnswer();
        if (!mounted) return;
        setState(() {
          _hearts = result['hearts'] ?? _hearts;
          _maxHearts = result['maxHearts'] ?? _maxHearts;
        });
      } catch (_) {
      }
    }
  }

  void _continue() {
    if (_isLoadingHearts) return;

    if (_cannotStartBecauseNoHearts) return;

    if (_hearts <= 0 && !_feedbackVisible) {
      setState(() {
        _cannotStartBecauseNoHearts = true;
      });
      return;
    }

    if (!_feedbackVisible) {
      _checkAnswer();
      return;
    }

    if (_isReviewingWrongAnswers && _failedOnReview && !_lastAnswerCorrect) {
      _finishQuiz();
      return;
    }

    if (_hearts <= 0 && !_lastAnswerCorrect) {
      _finishQuiz();
      return;
    }

    if (_isLastActivity) {
      if (!_isReviewingWrongAnswers && _wrongActivities.isNotEmpty) {
        _startWrongAnswerReview();
        return;
      }

      _finishQuiz();
      return;
    }

    setState(() {
      _currentIndex++;
      _setupCurrentActivity();
    });
  }

  void _startWrongAnswerReview() {
    setState(() {
      _activities = List<LessonActivity>.from(_wrongActivities);
      _currentIndex = 0;
      _isReviewingWrongAnswers = true;
      _feedbackVisible = false;
      _selectedAnswer = null;
      _selectedWords.clear();
      _wrongActivities.clear();
    });

    _setupCurrentActivity();

    _showMessage('Sekarang ulang soal yang masih salah.');
    return;
  }

  Future<void> _finishQuiz() async {
  if (_isSaving) return;

  setState(() {
    _isSaving = true;
  });

  try {
    final finishedReviewSuccessfully =
        _isReviewingWrongAnswers && !_failedOnReview;

    final perfectFirstRound =
        !_isReviewingWrongAnswers &&
        _wrongActivities.isEmpty &&
        !_failedOnReview;

    final finalPassed = perfectFirstRound || finishedReviewSuccessfully;

    final safeTotalQuestions = math.max(1, _totalOriginalActivities);

    final finalCorrectCount = finalPassed
        ? safeTotalQuestions
        : (_firstRoundCorrectCount + _reviewCorrectCount)
            .clamp(0, safeTotalQuestions)
            .toInt();

    final finalScorePct = finalPassed
        ? 100
        : ((finalCorrectCount / safeTotalQuestions) * 100).round();

    final result = await LearningService().completeLesson(
      lesson: widget.lesson,
      correctCount: finalCorrectCount,
      totalQuestions: safeTotalQuestions,
      forcePassed: finalPassed,
      heartsLostOverride: _heartsLostDuringQuiz,
      scorePctOverride: finalScorePct,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultPage(
          lesson: widget.lesson,
          result: result,
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    _showMessage('Gagal menyimpan hasil: $e');
  }
}

  int _serviceTotalQuestionsForPassed() {
    if (_heartsLostDuringQuiz <= 0) {
      return _totalOriginalActivities;
    }

    final requiredScore = widget.lesson.requiredScore.clamp(1, 100);

    final allowedWrongRatio = (100 - requiredScore) / 100;

    if (allowedWrongRatio <= 0) {
      return _totalOriginalActivities + _heartsLostDuringQuiz;
    }

    final minimumTotal = _totalOriginalActivities + _heartsLostDuringQuiz;
    final neededTotal = (_heartsLostDuringQuiz / allowedWrongRatio).ceil();

    return math.max(minimumTotal, neededTotal);
  }

  int _serviceCorrectCountForFailed() {
    if (_totalOriginalActivities <= 0) return 0;

    final maxCorrectBelowPassing =
        (((widget.lesson.requiredScore - 1) / 100) * _totalOriginalActivities)
            .floor();

    final actualCorrect = _firstRoundCorrectCount + _reviewCorrectCount;

    return math.min(
      actualCorrect,
      math.max(0, maxCorrectBelowPassing),
    );
  }

  String _buttonLabel() {
    if (!_feedbackVisible) return 'CEK';

    if (_isReviewingWrongAnswers && _failedOnReview && !_lastAnswerCorrect) {
      return 'LIHAT HASIL';
    }

    if (_isLastActivity && !_isReviewingWrongAnswers && _wrongActivities.isNotEmpty) {
      return 'ULANG SOAL SALAH';
    }

    if (_isLastActivity) return 'SELESAI';

    return 'LANJUT';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget _buildNoHeartsPage() {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: muted,
                    size: 30,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.favorite_border_rounded,
                size: 96,
                color: Color(0xFFD6372A),
              ),
              const SizedBox(height: 22),
              const Text(
                'Heart Kamu Habis',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Kamu belum bisa mengerjakan level ini karena heart kamu sudah 0.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: muted,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: coral,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                child: const Text(
                  'KEMBALI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyActivitiesPage() {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
      ),
      body: const Center(
        child: Text(
          'Latihan belum tersedia untuk level ini.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoadingHearts && _cannotStartBecauseNoHearts) {
      return _buildNoHeartsPage();
    }

    if (_activities.isEmpty) {
      return _buildEmptyActivitiesPage();
    }

    final progressValue = (_currentIndex + 1) / _activities.length;
    final activity = _activity;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: muted,
                      size: 30,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 12,
                        backgroundColor: const Color(0xFFE3E3E3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          green,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8E4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFFD6372A),
                          size: 22,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isLoadingHearts ? '-' : '$_hearts/$_maxHearts',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD6372A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isReviewingWrongAnswers) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0EC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: coral.withOpacity(0.25),
                            width: 1.4,
                          ),
                        ),
                        child: const Text(
                          'Review ulang soal yang belum tepat.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: coral,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _QuizMetaHeader(
                      lesson: widget.lesson,
                      activityNo: _currentIndex + 1,
                      totalActivities: _activities.length,
                      activityType: _activityTypeLabel(activity),
                    ),
                    const SizedBox(height: 22),
                    _ActivityCard(
                      activity: activity,
                      selectedAnswer: _selectedAnswer,
                      options: _optionsFor(activity),
                      feedbackVisible: _feedbackVisible,
                      wordBank: _wordBank,
                      selectedWords: _selectedWords,
                      translateController: _translateController,
                      matchingOptions: _matchingOptions,
                      matchingAnswers: _matchingAnswers,
                      onSelectAnswer: (answer) {
                        if (_feedbackVisible) return;

                        setState(() {
                          _selectedAnswer = answer;
                        });
                      },
                      onPickWord: (wordIndex) {
                        if (_feedbackVisible) return;

                        setState(() {
                          final word = _wordBank.removeAt(wordIndex);
                          _selectedWords.add(word);
                        });
                      },
                      onRemoveWord: (wordIndex) {
                        if (_feedbackVisible) return;

                        setState(() {
                          final word = _selectedWords.removeAt(wordIndex);
                          _wordBank.add(word);
                        });
                      },
                      onSelectMatching: (left, right) {
                        if (_feedbackVisible) return;

                        setState(() {
                          _matchingAnswers[left] = right;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    if (_feedbackVisible)
                      _FeedbackCard(
                        isCorrect: _lastAnswerCorrect,
                        explanation: activity.explanation,
                        correctAnswer: _correctAnswerText(activity),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
              child: _QuizButton(
                isLoading: _isSaving || _isLoadingHearts,
                label: _buttonLabel(),
                onPressed: (_isSaving || _isLoadingHearts) ? null : _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizMetaHeader extends StatelessWidget {
  const _QuizMetaHeader({
    required this.lesson,
    required this.activityNo,
    required this.totalActivities,
    required this.activityType,
  });

  final LessonData lesson;
  final int activityNo;
  final int totalActivities;
  final String activityType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Level ${lesson.levelNo} • $activityType',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE2775B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          lesson.title,
          style: const TextStyle(
            fontSize: 25,
            height: 1.15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF232248),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Soal $activityNo dari $totalActivities',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF7E7E99),
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.selectedAnswer,
    required this.options,
    required this.feedbackVisible,
    required this.wordBank,
    required this.selectedWords,
    required this.translateController,
    required this.matchingOptions,
    required this.matchingAnswers,
    required this.onSelectAnswer,
    required this.onPickWord,
    required this.onRemoveWord,
    required this.onSelectMatching,
  });

  final LessonActivity activity;
  final String? selectedAnswer;
  final List<String> options;
  final bool feedbackVisible;
  final List<String> wordBank;
  final List<String> selectedWords;
  final TextEditingController translateController;
  final List<String> matchingOptions;
  final Map<String, String> matchingAnswers;
  final ValueChanged<String> onSelectAnswer;
  final ValueChanged<int> onPickWord;
  final ValueChanged<int> onRemoveWord;
  final void Function(String left, String right) onSelectMatching;

  @override
  Widget build(BuildContext context) {
    if (activity.isArrangeSentence) {
      return _ArrangeSentenceCard(
        activity: activity,
        wordBank: wordBank,
        selectedWords: selectedWords,
        feedbackVisible: feedbackVisible,
        onPickWord: onPickWord,
        onRemoveWord: onRemoveWord,
      );
    }

    if (activity.isTranslateSentence) {
      return _TranslateSentenceCard(
        activity: activity,
        controller: translateController,
        feedbackVisible: feedbackVisible,
      );
    }

    if (activity.isMatching) {
      return _MatchingCard(
        activity: activity,
        matchingOptions: matchingOptions,
        matchingAnswers: matchingAnswers,
        feedbackVisible: feedbackVisible,
        onSelectMatching: onSelectMatching,
      );
    }

    return _MultipleChoiceCard(
      activity: activity,
      selectedAnswer: selectedAnswer,
      options: options,
      feedbackVisible: feedbackVisible,
      onSelectAnswer: onSelectAnswer,
    );
  }
}

class _MultipleChoiceCard extends StatelessWidget {
  const _MultipleChoiceCard({
    required this.activity,
    required this.selectedAnswer,
    required this.options,
    required this.feedbackVisible,
    required this.onSelectAnswer,
  });

  final LessonActivity activity;
  final String? selectedAnswer;
  final List<String> options;
  final bool feedbackVisible;
  final ValueChanged<String> onSelectAnswer;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PromptText(activity.prompt),
          const SizedBox(height: 20),
          ...options.map((option) {
            final selected = selectedAnswer == option;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AnswerOption(
                text: option,
                selected: selected,
                disabled: feedbackVisible,
                onTap: () => onSelectAnswer(option),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ArrangeSentenceCard extends StatelessWidget {
  const _ArrangeSentenceCard({
    required this.activity,
    required this.wordBank,
    required this.selectedWords,
    required this.feedbackVisible,
    required this.onPickWord,
    required this.onRemoveWord,
  });

  final LessonActivity activity;
  final List<String> wordBank;
  final List<String> selectedWords;
  final bool feedbackVisible;
  final ValueChanged<int> onPickWord;
  final ValueChanged<int> onRemoveWord;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PromptText(activity.prompt),
          if (activity.translationId.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Arti: ${activity.translationId}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7E7E99),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            child: selectedWords.isEmpty
                ? const Text(
                    'Tap kata di bawah untuk menyusun kalimat.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9B9B9B),
                    ),
                  )
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(selectedWords.length, (index) {
                      return _WordChip(
                        text: selectedWords[index],
                        filled: true,
                        disabled: feedbackVisible,
                        onTap: () => onRemoveWord(index),
                      );
                    }),
                  ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(wordBank.length, (index) {
              return _WordChip(
                text: wordBank[index],
                filled: false,
                disabled: feedbackVisible,
                onTap: () => onPickWord(index),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TranslateSentenceCard extends StatelessWidget {
  const _TranslateSentenceCard({
    required this.activity,
    required this.controller,
    required this.feedbackVisible,
  });

  final LessonActivity activity;
  final TextEditingController controller;
  final bool feedbackVisible;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PromptText(activity.prompt),
          if (activity.sentenceLocal.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                activity.sentenceLocal,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF232248),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            enabled: !feedbackVisible,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Tulis arti kalimat di sini...',
              filled: true,
              fillColor: const Color(0xFFF4F4F4),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFFE2775B),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchingCard extends StatelessWidget {
  const _MatchingCard({
    required this.activity,
    required this.matchingOptions,
    required this.matchingAnswers,
    required this.feedbackVisible,
    required this.onSelectMatching,
  });

  final LessonActivity activity;
  final List<String> matchingOptions;
  final Map<String, String> matchingAnswers;
  final bool feedbackVisible;
  final void Function(String left, String right) onSelectMatching;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PromptText(activity.prompt),
          const SizedBox(height: 18),
          ...activity.pairs.map((pair) {
            final selectedAnswer = matchingAnswers[pair.left];

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE5E5E5),
                  width: 1.4,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE2775B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.translate_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pair.left,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF232248),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: matchingOptions.map((option) {
                      final isSelected = selectedAnswer == option;
                      final isCorrectAnswer = pair.right == option;
                      final isWrongSelected =
                          feedbackVisible && isSelected && !isCorrectAnswer;
                      final isCorrectSelected =
                          feedbackVisible && isSelected && isCorrectAnswer;

                      return _MatchingChoiceChip(
                        text: option,
                        selected: isSelected,
                        correct: isCorrectSelected,
                        wrong: isWrongSelected,
                        disabled: feedbackVisible,
                        onTap: () => onSelectMatching(pair.left, option),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MatchingChoiceChip extends StatelessWidget {
  const _MatchingChoiceChip({
    required this.text,
    required this.selected,
    required this.correct,
    required this.wrong,
    required this.disabled,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool correct;
  final bool wrong;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFE0E0E0);
    Color textColor = const Color(0xFF232248);
    IconData? icon;

    if (selected) {
      bgColor = const Color(0xFFFFF0EC);
      borderColor = const Color(0xFFE2775B);
      textColor = const Color(0xFFE2775B);
    }

    if (correct) {
      bgColor = const Color(0xFFE7F7F1);
      borderColor = const Color(0xFF0F9D6C);
      textColor = const Color(0xFF0F9D6C);
      icon = Icons.check_circle_rounded;
    }

    if (wrong) {
      bgColor = const Color(0xFFFFE8E4);
      borderColor = const Color(0xFFD6372A);
      textColor = const Color(0xFFD6372A);
      icon = Icons.cancel_rounded;
    }

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: selected || correct || wrong ? 2 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: textColor,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptText extends StatelessWidget {
  const _PromptText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 21,
        height: 1.22,
        fontWeight: FontWeight.w900,
        color: Color(0xFF232248),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.text,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? const Color(0xFFE2775B) : const Color(0xFFE0E0E0);
    final bgColor = selected ? const Color(0xFFFFF0EC) : Colors.white;

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: selected
                ? const Color(0xFFE2775B)
                : const Color(0xFF232248),
          ),
        ),
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({
    required this.text,
    required this.filled,
    required this.disabled,
    required this.onTap,
  });

  final String text;
  final bool filled;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFE2775B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: filled ? const Color(0xFFE2775B) : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
          boxShadow: filled
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: filled ? Colors.white : const Color(0xFF232248),
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.isCorrect,
    required this.explanation,
    required this.correctAnswer,
  });

  final bool isCorrect;
  final String explanation;
  final String correctAnswer;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? const Color(0xFF0F9D6C) : const Color(0xFFE2775B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFE7F7F1) : const Color(0xFFFFF0EC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? 'Benar!' : 'Belum tepat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCorrect
                ? (explanation.isNotEmpty ? explanation : 'Jawaban kamu sudah tepat.')
                : 'Jawaban yang benar:\n$correctAnswer',
            style: const TextStyle(
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: Color(0xFF232248),
            ),
          ),
          if (!isCorrect && explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              explanation,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7E7E99),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuizButton extends StatelessWidget {
  const _QuizButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFFE2775B),
        disabledBackgroundColor: const Color(0xFFE7B8AA),
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(27),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class QuizResultPage extends StatelessWidget {
  const QuizResultPage({
    super.key,
    required this.lesson,
    required this.result,
  });

  final LessonData lesson;
  final LessonCompletionResult result;

  @override
  Widget build(BuildContext context) {
    final passed = result.isPassed;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                passed
                    ? Icons.emoji_events_rounded
                    : Icons.refresh_rounded,
                size: 96,
                color: passed
                    ? const Color(0xFFF4B11A)
                    : const Color(0xFFE2775B),
              ),
              const SizedBox(height: 22),
              Text(
                passed ? 'Level Selesai!' : 'Coba Lagi, Yuk!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF232248),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                passed
                    ? 'Kamu berhasil menyelesaikan Level ${lesson.levelNo}.'
                    : 'Skor kamu belum mencapai batas minimal ${lesson.requiredScore}%.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7E7E99),
                ),
              ),
              const SizedBox(height: 26),
              _ResultStat(
                label: 'Skor',
                value: '${result.scorePct}%',
              ),
              _ResultStat(
                label: 'Benar',
                value: '${result.correctCount}/${result.totalQuestions}',
              ),
              _ResultStat(
                label: 'XP Didapat',
                value: '+${result.xpEarned}',
              ),
              _ResultStat(
                label: 'Streak',
                value: '${result.streakDays} hari',
              ),
              _ResultStat(
                label: 'Heart Tersisa',
                value: '${result.heartsRemaining}/${result.maxHearts}',
              ),
              _ResultStat(
                label: 'Heart Hilang',
                value: '-${result.heartsLost}',
              ),
              if (result.alreadyCompleted) ...[
                const SizedBox(height: 10),
                const Text(
                  'Level ini sudah pernah diselesaikan, jadi XP tidak ditambahkan lagi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7E7E99),
                  ),
                ),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomePage(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFE2775B),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                child: const Text(
                  'KEMBALI KE HOME',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF7E7E99),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF232248),
            ),
          ),
        ],
      ),
    );
  }
}