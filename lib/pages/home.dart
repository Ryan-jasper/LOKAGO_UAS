import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/database_seed_service.dart';

import 'learning/lesson_page.dart';
import 'peta.dart';
import 'profile.dart';
import 'streak.dart';

enum PathNodeType { star, level, test }

enum PathNodeStatus { completed, current, locked }

class _HomeProgress {
  const _HomeProgress({
    required this.userName,
    required this.languageId,
    required this.languageName,
    required this.currentLevel,
    required this.maxUnlockedLevel,
    required this.completedLevels,
    required this.totalXp,
    required this.hearts,
    required this.maxHearts,
    required this.streakDays,
  });

  final String userName;
  final String languageId;
  final String languageName;
  final int currentLevel;
  final int maxUnlockedLevel;
  final List<int> completedLevels;
  final int totalXp;
  final int hearts;
  final int maxHearts;
  final int streakDays;

  int get nextLevel {
    if (currentLevel >= 30) return 30;
    return math.min(30, math.max(1, maxUnlockedLevel));
  }

  double get progressValue {
    return (currentLevel / 30).clamp(0.0, 1.0).toDouble();
  }

  int get progressPercent {
    return (progressValue * 100).round();
  }

  bool isLevelCompleted(int levelNo) {
    return completedLevels.contains(levelNo) || levelNo <= currentLevel;
  }

  bool isLevelCurrent(int levelNo) {
    return !isLevelCompleted(levelNo) && levelNo == nextLevel;
  }
}

class _ThemeUnit {
  const _ThemeUnit({
    required this.unitNo,
    required this.title,
    required this.startLevel,
    required this.endLevel,
  });

  final int unitNo;
  final String title;
  final int startLevel;
  final int endLevel;
}

_ThemeUnit _themeForLevel(int levelNo) {
  if (levelNo <= 5) {
    return const _ThemeUnit(
      unitNo: 1,
      title: 'Perkenalan & Sapaan',
      startLevel: 1,
      endLevel: 5,
    );
  }

  if (levelNo <= 10) {
    return const _ThemeUnit(
      unitNo: 2,
      title: 'Keluarga & Orang Sekitar',
      startLevel: 6,
      endLevel: 10,
    );
  }

  if (levelNo <= 15) {
    return const _ThemeUnit(
      unitNo: 3,
      title: 'Angka, Waktu & Hari',
      startLevel: 11,
      endLevel: 15,
    );
  }

  if (levelNo <= 20) {
    return const _ThemeUnit(
      unitNo: 4,
      title: 'Makanan & Belanja',
      startLevel: 16,
      endLevel: 20,
    );
  }

  if (levelNo <= 25) {
    return const _ThemeUnit(
      unitNo: 5,
      title: 'Arah, Tempat & Perjalanan',
      startLevel: 21,
      endLevel: 25,
    );
  }

  return const _ThemeUnit(
    unitNo: 6,
    title: 'Budaya & Percakapan Harian',
    startLevel: 26,
    endLevel: 30,
  );
}

String _normalizeLanguageId(String? value) {
  final raw = (value ?? '').trim().toLowerCase();
  if (raw.contains('batak') || raw.contains('toba')) return 'batak_toba';
  if (raw.contains('jawa')) return 'jawa';
  if (raw.contains('sunda')) return 'sunda';

  return 'sunda';
}

String _languageNameFromId(String languageId) {
  if (languageId == 'batak_toba') return 'Bahasa Batak Toba';
  if (languageId == 'jawa') return 'Bahasa Jawa';
  return 'Bahasa Sunda';
}

int _readInt(dynamic value, int fallback) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

List<int> _readIntList(dynamic value) {
  if (value is! List) return [];

  return value
      .map((item) => int.tryParse(item.toString()))
      .whereType<int>()
      .toSet()
      .toList()
    ..sort();
}

String _resolveUserName(Map<String, dynamic> userData, User user) {
  final possibleNames = [
    userData['name'],
    userData['displayName'],
    userData['fullName'],
    userData['upf_full_name'],
    user.displayName,
  ];

  for (final name in possibleNames) {
    final value = name?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }

  return 'Bubi';
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bubbleController;

  @override
@override
void initState() {
  super.initState();

  debugPrint('LOKAGO HOME -> initState jalan');

  _bubbleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  Future.microtask(() async {
    debugPrint('LOKAGO SEED HOME -> mulai seed');

    try {
      await DatabaseSeedService.instance.seedSundaDatabase();
      debugPrint('LOKAGO SEED HOME -> seed berhasil');
    } catch (e) {
      debugPrint('LOKAGO SEED HOME -> seed gagal: $e');
    }
  });
}

  @override
  void dispose() {
    _bubbleController.dispose();
    super.dispose();
  }

  Future<void> _openLesson(int levelNo) async {
    debugPrint('LOKAGO HOME -> open lesson levelNo: $levelNo');

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonPage(levelNo: levelNo),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  List<_PathNodeData> _buildNodes(_HomeProgress progress) {
  final nodes = <_PathNodeData>[];

  for (int levelNo = 1; levelNo <= 30; levelNo++) {
    PathNodeStatus status;

    if (progress.isLevelCompleted(levelNo)) {
      status = PathNodeStatus.completed;
    } else if (progress.isLevelCurrent(levelNo)) {
      status = PathNodeStatus.current;
    } else {
      status = PathNodeStatus.locked;
    }

    nodes.add(
      _PathNodeData(
        type: levelNo % 5 == 0 ? PathNodeType.test : PathNodeType.level,
        label: '$levelNo',
        status: status,
      ),
    );
  }

  return nodes;
}

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF4F4F4);
    const coral = Color(0xFFE2775B);

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text(
            'User belum login.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userRef.snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: CircularProgressIndicator(color: coral),
            ),
          );
        }

        final userData = userSnapshot.data?.data() ?? <String, dynamic>{};

        final selectedLanguageId = _normalizeLanguageId(
          userData['selectedLanguageId']?.toString() ??
              userData['selectedLanguage']?.toString() ??
              userData['languageId']?.toString(),
        );

        final languageProgressRef =
            userRef.collection('languageProgress').doc(selectedLanguageId);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: languageProgressRef.snapshots(),
          builder: (context, progressSnapshot) {
            final progressData =
                progressSnapshot.data?.data() ?? <String, dynamic>{};

            final progress = _HomeProgress(
              userName: _resolveUserName(userData, user),
              languageId: selectedLanguageId,
              languageName: progressData['languageName']?.toString() ??
                  _languageNameFromId(selectedLanguageId),
              currentLevel: _readInt(progressData['currentLevel'], 0),
              maxUnlockedLevel: _readInt(
                progressData['maxUnlockedLevel'],
                1,
              ),
              completedLevels: _readIntList(
                progressData['completedLevels'],
              ),
              totalXp: _readInt(
                userData['totalXp'],
                _readInt(progressData['totalXp'], 0),
              ),
              hearts: _readInt(userData['hearts'], 5),
              maxHearts: _readInt(userData['maxHearts'], 15),
              streakDays: _readInt(userData['streakDays'], 0),
            );

            final nodes = _buildNodes(progress);

            return Scaffold(
              backgroundColor: bgColor,
              bottomNavigationBar: const _LokaBottomNav(currentIndex: 0),
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
                      child: Column(
                        children: [
                          _HomeHeader(progress: progress),
                          const SizedBox(height: 14),
                          _TopContinueCard(
                            statusText: progress.currentLevel == 0
                                ? 'MULAI BELAJAR'
                                : 'LANJUTKAN',
                            title:
                                '${progress.languageName}:\nUnit ${_themeForLevel(progress.nextLevel).unitNo} - ${_themeForLevel(progress.nextLevel).title}',
                            subtitle:
                                'Level ${progress.nextLevel} dari ${_themeForLevel(progress.nextLevel).startLevel}-${_themeForLevel(progress.nextLevel).endLevel}',
                            progressValue: progress.progressValue,
                            progressLabel: '${progress.progressPercent}%',
                            buttonLabel: progress.currentLevel == 0
                                ? 'Mulai Level 1'
                                : 'Lanjut Level ${progress.nextLevel}',
                            onTap: () => _openLesson(progress.nextLevel),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _LearningPathSection(
                        nodes: nodes,
                        onNodeTap: (node) {
                          if (node.status == PathNodeStatus.locked) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Level ini masih terkunci. Selesaikan level sebelumnya dulu.',
                                ),
                              ),
                            );
                            return;
                          }

                          final levelNo = int.tryParse(node.label) ?? progress.nextLevel;
                          _openLesson(levelNo);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.progress,
  });

  final _HomeProgress progress;

  static const Color red = Color(0xFFD6372A);
  static const Color gold = Color(0xFFF4B11A);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 22,
          backgroundColor: Color(0xFFD9D9D9),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                progress.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${progress.totalXp} XP',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF93A2B8),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Text(
              '${progress.hearts}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: red,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.favorite_border_rounded,
              color: red,
              size: 34,
            ),
          ],
        ),
        const SizedBox(width: 24),
        Row(
          children: [
            Text(
              '${progress.streakDays}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: gold,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.local_fire_department_outlined,
              color: gold,
              size: 34,
            ),
          ],
        ),
      ],
    );
  }
}

class _TopContinueCard extends StatelessWidget {
  const _TopContinueCard({
    required this.onTap,
    required this.statusText,
    required this.title,
    required this.subtitle,
    required this.progressValue,
    required this.progressLabel,
    required this.buttonLabel,
  });

  final VoidCallback onTap;
  final String statusText;
  final String title;
  final String subtitle;
  final double progressValue;
  final String progressLabel;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE2775B),
            Color(0xFFE38A75),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: progressValue,
                        strokeWidth: 7,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      progressLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF2DFD8),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFFE2775B),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE2775B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeLabel extends StatelessWidget {
  const _ThemeLabel({
    required this.theme,
  });

  final _ThemeUnit theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2775B).withOpacity(0.35),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE2775B),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${theme.unitNo}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${theme.title} • Level ${theme.startLevel}-${theme.endLevel}',
              style: const TextStyle(
                color: Color(0xFF232248),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningPathSection extends StatelessWidget {
  const _LearningPathSection({
    required this.nodes,
    required this.onNodeTap,
  });

  final List<_PathNodeData> nodes;
  final ValueChanged<_PathNodeData> onNodeTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        const startY = 80.0;
        const gapY = 135.0;

        final xPattern = List<double>.generate(
          nodes.length,
          (i) {
            const pattern = [
              0.50,
              0.64,
              0.36,
              0.62,
              0.38,
              0.58,
              0.42,
            ];

            return pattern[i % pattern.length];
          },
        );

        final points = List.generate(nodes.length, (i) {
          return Offset(
            w * xPattern[i],
            startY + (i * gapY),
          );
        });

        final canvasHeight = startY + ((nodes.length - 1) * gapY) + 190;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: SizedBox(
            width: double.infinity,
            height: canvasHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LearningPathPainter(points: points),
                  ),
                ),

              

                // Node level
                ...List.generate(nodes.length, (index) {
                  final point = points[index];
                  final node = nodes[index];

                  final bool isCurrent =
                      node.status == PathNodeStatus.current;
                  final bool isSpecial = node.type == PathNodeType.star ||
                      node.type == PathNodeType.test;

                  final double outerSize =
                      isCurrent ? 100 : (isSpecial ? 88 : 84);

                  return Positioned(
                    left: point.dx - (outerSize / 2),
                    top: point.dy - ((outerSize + 12) / 2),
                    child: _PathNodeButton(
                      data: node,
                      onTap: () => onNodeTap(node),
                    ),
                  );
                }),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 180,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.fromRGBO(244, 244, 244, 0),
                            Color(0xFFF4F4F4),
                            Color(0xFFF4F4F4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedNodeWrapper extends StatelessWidget {
  const _AnimatedNodeWrapper({
    required this.showBubble,
    required this.controller,
    required this.child,
  });

  final bool showBubble;
  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!showBubble) return child;

    return SizedBox(
      width: 112,
      height: 132,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, bubble) {
              final offsetY = -2 + (controller.value * 10);

              return Positioned(
                top: offsetY,
                child: bubble!,
              );
            },
            child: const _FloatingBubble(text: 'START'),
          ),
          Positioned(
            top: 40,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _PathNodeButton extends StatefulWidget {
  const _PathNodeButton({
    required this.data,
    required this.onTap,
  });

  final _PathNodeData data;
  final VoidCallback onTap;

  @override
  State<_PathNodeButton> createState() => _PathNodeButtonState();
}

class _PathNodeButtonState extends State<_PathNodeButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors();
    final isCurrent = widget.data.status == PathNodeStatus.current;
    final isSpecial = widget.data.type == PathNodeType.star ||
        widget.data.type == PathNodeType.test;

    final double size = isCurrent ? 88 : (isSpecial ? 80 : 76);
    final double outerSize = isCurrent ? 100 : (isSpecial ? 88 : 84);
    final double faceTop = isPressed ? 9 : 0;
    const double shadowTop = 10;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          isPressed = false;
        });
        widget.onTap();
      },
      onTapCancel: () {
        setState(() {
          isPressed = false;
        });
      },
      child: SizedBox(
        width: outerSize,
        height: outerSize + 12,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: shadowTop,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.shadow,
                  border: Border.all(
                    color: Colors.white,
                    width: 3.4,
                  ),
                ),
              ),
            ),
            if (isCurrent)
              Positioned(
                top: faceTop,
                child: Container(
                  width: outerSize,
                  height: outerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD8D8D8),
                      width: 8,
                    ),
                  ),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOut,
              top: faceTop,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.main,
                  border: Border.all(
                    color: Colors.white,
                    width: 3.4,
                  ),
                ),
                alignment: Alignment.center,
                child: _buildChild(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChild() {
    if (widget.data.type == PathNodeType.star) {
      return Icon(
        Icons.star_rounded,
        size: 30,
        color: widget.data.status == PathNodeStatus.locked
            ? const Color(0xFFB9B9B9)
            : Colors.white,
      );
    }

    if (widget.data.type == PathNodeType.test) {
      return Icon(
        Icons.workspace_premium_rounded,
        size: 28,
        color: widget.data.status == PathNodeStatus.locked
            ? const Color(0xFFB9B9B9)
            : Colors.white,
      );
    }

    return Text(
      widget.data.label,
      style: TextStyle(
        fontSize: widget.data.status == PathNodeStatus.current ? 28 : 25,
        fontWeight: FontWeight.w900,
        color: widget.data.status == PathNodeStatus.locked
            ? const Color(0xFFB9B9B9)
            : Colors.white,
      ),
    );
  }

  _NodeColors _resolveColors() {
    if (widget.data.status == PathNodeStatus.completed) {
      if (widget.data.type == PathNodeType.test ||
          widget.data.type == PathNodeType.star) {
        return const _NodeColors(
          main: Color(0xFFF4B11A),
          shadow: Color(0xFFE09E00),
        );
      }

      return const _NodeColors(
        main: Color(0xFF69C3A8),
        shadow: Color(0xFF0F9D6C),
      );
    }

    if (widget.data.status == PathNodeStatus.current) {
      return const _NodeColors(
        main: Color(0xFFF1B6AA),
        shadow: Color(0xFFFF7154),
      );
    }

    return const _NodeColors(
      main: Color(0xFFE1E1E1),
      shadow: Color(0xFFBEBEBE),
    );
  }
}

class _FloatingBubble extends StatelessWidget {
  const _FloatingBubble({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1D3D25),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF62D77E),
              width: 1.3,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8DFF8D),
            ),
          ),
        ),
        Positioned(
          bottom: -4,
          left: 18,
          child: Transform.rotate(
            angle: 0.8,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF1D3D25),
                border: Border(
                  right: BorderSide(
                    color: Color(0xFF62D77E),
                    width: 1.2,
                  ),
                  bottom: BorderSide(
                    color: Color(0xFF62D77E),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({
    required this.text,
    required this.width,
  });

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD9D4D6),
              width: 2,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4E4E4E),
            ),
          ),
        ),
        Positioned(
          left: 16,
          bottom: -10,
          child: Transform.rotate(
            angle: 0.78,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(
                    color: Color(0xFFD9D4D6),
                    width: 2,
                  ),
                  bottom: BorderSide(
                    color: Color(0xFFD9D4D6),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LearningPathPainter extends CustomPainter {
  const _LearningPathPainter({
    required this.points,
  });

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paintLine = Paint()
      ..color = const Color(0xFFD9D9D9)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlY = (previous.dy + current.dy) / 2;

      path.cubicTo(
        previous.dx,
        controlY,
        current.dx,
        controlY,
        current.dx,
        current.dy,
      );
    }

    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant _LearningPathPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class UnderConstructionPage extends StatelessWidget {
  const UnderConstructionPage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4E4E4E)),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF4E4E4E),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFD9D4D6),
              width: 2,
            ),
          ),
          child: Text(
            '$title\nmasih dalam pengerjaan',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4E4E4E),
            ),
          ),
        ),
      ),
    );
  }
}

class _PathNodeData {
  const _PathNodeData({
    required this.type,
    required this.label,
    required this.status,
  });

  final PathNodeType type;
  final String label;
  final PathNodeStatus status;
}

class _NodeColors {
  const _NodeColors({
    required this.main,
    required this.shadow,
  });

  final Color main;
  final Color shadow;
}

class _LokaBottomNav extends StatelessWidget {
  const _LokaBottomNav({
    required this.currentIndex,
  });

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItemData('Home', Icons.home_outlined),
      _NavItemData('Streak', Icons.local_fire_department_outlined),
      _NavItemData('Peta', Icons.map_outlined),
      _NavItemData('Profile', Icons.person_outline),
    ];

    return Container(
      height: 92,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F4F4),
        border: Border(
          top: BorderSide(color: Color(0xFFE3E3E3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final active = index == currentIndex;
          final color = active
              ? const Color(0xFF69C3A8)
              : const Color(0xFF93A2B8);

          return InkWell(
            onTap: () {
              if (active) return;

              Widget page;

              switch (index) {
                case 0:
                  page = const HomePage();
                  break;
                case 1:
                  page = const StreakPage();
                  break;
                case 2:
                  page = const PetaPage();
                  break;
                case 3:
                  page = const ProfilePage();
                  break;
                default:
                  page = const HomePage();
              }

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => page),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: color, size: 30),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _NavItemData {
  _NavItemData(this.label, this.icon);

  final String label;
  final IconData icon;
}