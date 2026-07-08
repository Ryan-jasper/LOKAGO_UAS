import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home.dart';
import 'peta.dart';
import 'profile.dart';

const Color _bgColor = Color(0xFFF4F4F4);
const Color _coral = Color(0xFFE2775B);
const Color _green = Color(0xFF69C3A8);
const Color _textDark = Color(0xFF232248);
const Color _muted = Color(0xFF7E7E99);
const Color _danger = Color(0xFFD6372A);
const Color _gold = Color(0xFFF0A615);

class StreakPage extends StatefulWidget {
  const StreakPage({super.key});

  @override
  State<StreakPage> createState() => _StreakPageState();
}

class _StreakPageState extends State<StreakPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: _bgColor,
        bottomNavigationBar: _LokaBottomNav(currentIndex: 1),
        body: Center(
          child: Text(
            'User belum login.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() ?? <String, dynamic>{};

        final streakData = _StreakData.fromFirestore(
          user: user,
          userData: userData,
        );

        return Scaffold(
          backgroundColor: _bgColor,
          bottomNavigationBar: const _LokaBottomNav(currentIndex: 1),
          body: SafeArea(
            child: Column(
              children: [
                _Header(streakData: streakData),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _bgColor,
                          Color(0xFFFCE9E3),
                          Color(0xFFE6F5EF),
                        ],
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        children: [
                          const Text(
                            'Ayo Bantu Loka Netas!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: _coral,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _StreakCounter(streakData: streakData),
                          const SizedBox(height: 28),
                          _HatchingEgg(
                            streakData: streakData,
                            animation: _shakeController,
                          ),
                          const SizedBox(height: 28),
                          _WeekRow(streakData: streakData),
                          const SizedBox(height: 18),
                          _MotivationCard(streakData: streakData),
                        ],
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

class _Header extends StatelessWidget {
  const _Header({
    required this.streakData,
  });

  final _StreakData streakData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
      child: Row(
        children: [
          _ProfileAvatar(name: streakData.name),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              streakData.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _textDark,
              ),
            ),
          ),
          Row(
            children: [
              Text(
                '${streakData.hearts}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _danger,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.favorite_rounded,
                color: _danger,
                size: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakCounter extends StatelessWidget {
  const _StreakCounter({
    required this.streakData,
  });

  final _StreakData streakData;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${streakData.streakDays} Hari',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: _gold,
          ),
        ),
        const SizedBox(width: 12),
        const Icon(
          Icons.local_fire_department_rounded,
          color: _gold,
          size: 56,
        ),
      ],
    );
  }
}

class _HatchingEgg extends StatelessWidget {
  const _HatchingEgg({
    required this.streakData,
    required this.animation,
  });

  final _StreakData streakData;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 330,
      width: double.infinity,
      child: Center(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final shakeValue = math.sin(animation.value * math.pi * 2);
            final rotate = shakeValue * 0.025;
            final translateX = shakeValue * 3;

            return Transform.translate(
              offset: Offset(translateX, 0),
              child: Transform.rotate(
                angle: rotate,
                child: child,
              ),
            );
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            child: Image.asset(
              streakData.eggAsset,
              key: ValueKey(streakData.eggAsset),
              height: streakData.isFullyHatched ? 240 : 310,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return Container(
                  height: 280,
                  width: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(140),
                    border: Border.all(
                      color: const Color(0xFFE1E1E8),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.egg_alt_rounded,
                      size: 90,
                      color: _coral,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.streakData,
  });

  final _StreakData streakData;

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    final todayIndex = DateTime.now().weekday - 1;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(labels.length, (index) {
            final isToday = index == todayIndex;
            final isActive = _isDayActive(
              index: index,
              todayIndex: todayIndex,
              streakDays: streakData.streakDays,
              hasStudiedToday: streakData.hasStudiedToday,
            );

            return SizedBox(
              width: 42,
              child: Text(
                labels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isToday
                      ? const Color(0xFF2FA6F2)
                      : isActive
                          ? _coral
                          : const Color(0xFF93A2B8),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(labels.length, (index) {
            final isToday = index == todayIndex;
            final isActive = _isDayActive(
              index: index,
              todayIndex: todayIndex,
              streakDays: streakData.streakDays,
              hasStudiedToday: streakData.hasStudiedToday,
            );

            if (isToday) {
              return _CurrentDayDot(active: isActive);
            }

            return _DayDot(
              active: isActive,
            );
          }),
        ),
      ],
    );
  }

  bool _isDayActive({
    required int index,
    required int todayIndex,
    required int streakDays,
    required bool hasStudiedToday,
  }) {
    if (streakDays <= 0) return false;

    final effectiveStreak = hasStudiedToday ? streakDays : streakDays - 1;

    if (effectiveStreak <= 0) return false;

    final startIndex = todayIndex - effectiveStreak + 1;

    return index >= math.max(0, startIndex) && index <= todayIndex;
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.active,
  });

  final bool active;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 23,
      backgroundColor: active ? _coral : const Color(0xFF95A4B8),
      child: active
          ? const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 24,
            )
          : null,
    );
  }
}

class _CurrentDayDot extends StatelessWidget {
  const _CurrentDayDot({
    required this.active,
  });

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF2FA6F2) : const Color(0xFF95A4B8);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CircleAvatar(
            radius: 23,
            backgroundColor: color,
            child: Icon(
              active ? Icons.check_rounded : Icons.more_horiz_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MotivationCard extends StatelessWidget {
  const _MotivationCard({
    required this.streakData,
  });

  final _StreakData streakData;

  @override
  Widget build(BuildContext context) {
    final text = streakData.hasStudiedToday
        ? 'Keren! Kamu sudah menjaga streak hari ini.'
        : 'Belajar satu level hari ini agar streak kamu tetap aman.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w800,
          color: _textDark,
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.name,
  });

  final String name;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: _green,
      child: Text(
        _initials(name),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _StreakData {
  const _StreakData({
    required this.name,
    required this.hearts,
    required this.streakDays,
    required this.totalXp,
    required this.lastStudyDate,
  });

  final String name;
  final int hearts;
  final int streakDays;
  final int totalXp;
  final String lastStudyDate;

  bool get hasStudiedToday {
    final today = _todayString();

    return lastStudyDate == today;
  }

  int get eggStage {
    final stage = (streakDays ~/ 5) + 1;

    return stage.clamp(1, 9).toInt();
  }

  int get nextEggStage {
    final nextStage = eggStage + 1;

    return nextStage.clamp(1, 9).toInt();
  }

  bool get isFullyHatched {
    return eggStage >= 9;
  }

  int get stageProgress {
    if (isFullyHatched) return 5;

    return streakDays % 5;
  }

  int get daysToNextStage {
    if (isFullyHatched) return 0;

    final remaining = 5 - stageProgress;

    return remaining == 0 ? 5 : remaining;
  }

  int get nextStageDay {
    if (isFullyHatched) return 40;

    return eggStage * 5;
  }

  String get eggAsset {
    return 'assets/images/streak/egg$eggStage.png';
  }

  factory _StreakData.fromFirestore({
    required User user,
    required Map<String, dynamic> userData,
  }) {
    return _StreakData(
      name: _readString(
        userData['name'],
        fallback: user.displayName ?? 'Bubi',
      ),
      hearts: _readInt(userData['hearts'], 5),
      streakDays: _readInt(userData['streakDays'], 0),
      totalXp: _readInt(userData['totalXp'], 0),
      lastStudyDate: _readDateString(userData['lastStudyDate']),
    );
  }
}

class _LokaBottomNav extends StatelessWidget {
  final int currentIndex;

  const _LokaBottomNav({
    required this.currentIndex,
  });

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
        color: _bgColor,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE3E3E3),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final active = index == currentIndex;
          final color = active ? _green : const Color(0xFF93A2B8);

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
                  page = const StreakPage();
              }

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => page,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: color,
                  size: 30,
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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
  final String label;
  final IconData icon;

  const _NavItemData(
    this.label,
    this.icon,
  );
}

String _todayString() {
  final now = DateTime.now();

  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

String _readDateString(dynamic value) {
  if (value == null) return '';

  if (value is Timestamp) {
    final date = value.toDate();

    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  return value.toString();
}

String _readString(
  dynamic value, {
  required String fallback,
}) {
  final text = value?.toString();

  if (text == null || text.trim().isEmpty) {
    return fallback;
  }

  return text;
}

int _readInt(dynamic value, int fallback) {
  if (value is int) return value;

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) return 'B';

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}