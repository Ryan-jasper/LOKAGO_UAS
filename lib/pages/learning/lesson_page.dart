import 'package:flutter/material.dart';

import '../../models/learning_models.dart';
import '../../services/learning_service.dart';
import 'quiz_page.dart';

class LessonPage extends StatefulWidget {
  const LessonPage({
    super.key,
    required this.levelNo,
  });

  final int levelNo;

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  late Future<LessonData> _lessonFuture;

  static const Color bgColor = Color(0xFFF4F4F4);
  static const Color coral = Color(0xFFE2775B);
  static const Color green = Color(0xFF0F9D6C);
  static const Color textDark = Color(0xFF232248);
  static const Color muted = Color(0xFF7E7E99);

  @override
  void initState() {
    super.initState();
    _lessonFuture = _loadLesson();
  }

  @override
  void didUpdateWidget(covariant LessonPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.levelNo != widget.levelNo) {
      _lessonFuture = _loadLesson();
    }
  }

  Future<LessonData> _loadLesson() async {
    final languageId = await LearningService().getCurrentUserLanguageId();

    debugPrint(
      'LOKAGO LESSON REQUEST -> languageId: $languageId, levelNo: ${widget.levelNo}',
    );

    final lesson = await LearningService().getLesson(
      languageId: languageId,
      levelNo: widget.levelNo,
    );

    debugPrint(
      'LOKAGO LESSON LOADED -> levelNo: ${lesson.levelNo}, title: ${lesson.title}, activities: ${lesson.activities.map((activity) => activity.id).join(', ')}',
    );

    return lesson;
  }

  void _startQuiz(LessonData lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPage(lesson: lesson),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FutureBuilder<LessonData>(
          future: _lessonFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: coral),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Materi gagal dimuat: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }

            final lesson = snapshot.data!;

            return Column(
              children: [
                _Header(
                  lesson: lesson,
                  requestedLevelNo: widget.levelNo,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Materi Singkat',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pelajari kata dan frasa berikut sebelum masuk ke latihan.',
                          style: TextStyle(
                            color: muted,
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (lesson.items.isEmpty)
                          const _EmptyLessonMaterial()
                        else
                          ...lesson.items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;

                            return _LessonItemCard(
                              index: index + 1,
                              item: item,
                            );
                          }),
                        const SizedBox(height: 18),
                        _StartQuizButton(
                          onTap: () => _startQuiz(lesson),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.lesson,
    required this.requestedLevelNo,
  });

  final LessonData lesson;
  final int requestedLevelNo;

  static const Color coral = Color(0xFFE2775B);

  @override
  Widget build(BuildContext context) {
    final isDifferentLevel = lesson.levelNo != requestedLevelNo;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
      decoration: const BoxDecoration(
        color: coral,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(999),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Level ${lesson.levelNo} • ${lesson.languageName}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lesson.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lesson.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isDifferentLevel) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Debug: halaman meminta level $requestedLevelNo, tetapi data yang terbaca adalah level ${lesson.levelNo}.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LessonItemCard extends StatelessWidget {
  const _LessonItemCard({
    required this.index,
    required this.item,
  });

  final int index;
  final LessonItem item;

  static const Color green = Color(0xFF0F9D6C);
  static const Color textDark = Color(0xFF232248);
  static const Color muted = Color(0xFF7E7E99);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE4E4E4),
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: green.withOpacity(0.12),
            child: Text(
              '$index',
              style: const TextStyle(
                color: green,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.localText,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.glossText,
                  style: const TextStyle(
                    color: green,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.exampleText,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLessonMaterial extends StatelessWidget {
  const _EmptyLessonMaterial();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE4E4E4),
          width: 1.4,
        ),
      ),
      child: const Text(
        'Materi singkat belum tersedia untuk level ini, tetapi latihan tetap bisa dimulai.',
        style: TextStyle(
          color: Color(0xFF7E7E99),
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StartQuizButton extends StatelessWidget {
  const _StartQuizButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  static const Color green = Color(0xFF0F9D6C);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text(
          'MULAI LATIHAN',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}