import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home.dart';
import 'profile.dart';
import 'streak.dart';

const Color _bgColor = Color(0xFFF4F4F4);
const Color _coral = Color(0xFFE2775B);
const Color _green = Color(0xFF69C3A8);
const Color _greenDark = Color(0xFF0F9D6C);
const Color _textDark = Color(0xFF232248);
const Color _muted = Color(0xFF7E7E99);
const Color _danger = Color(0xFFD6372A);
const Color _gold = Color(0xFFF0A615);

class PetaPage extends StatefulWidget {
  const PetaPage({super.key});

  @override
  State<PetaPage> createState() => _PetaPageState();
}

class _PetaPageState extends State<PetaPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ScrollController _mapScrollController = ScrollController();

  _MapPinData? _selectedPin;
  bool _hasJumpedToJavaArea = false;

  final List<_MapPinData> _pins = const [
    _MapPinData(
      id: 'sunda_jawa_barat',
      languageId: 'sunda',
      title: 'Bahasa Sunda',
      subtitle: 'Jawa Barat',
      description:
          'Kelas Bahasa Sunda dari dasar melalui latihan level, streak, heart, dan badge LOKAGO.',
      mapX: 0.25,
      mapY: 0.75,
    ),
    _MapPinData(
      id: 'jawa_jawa_tengah',
      languageId: 'jawa',
      title: 'Bahasa Jawa',
      subtitle: 'Jawa Tengah',
      description:
          'Kelas Bahasa Jawa dari dasar. Marker ini difokuskan pada wilayah Jawa Tengah.',
      mapX: 0.365,
      mapY: 0.8,
    ),
    _MapPinData(
      id: 'batak_toba_sumatra_utara',
      languageId: 'batak_toba',
      title: 'Bahasa Batak Toba',
      subtitle: 'Sumatra Utara',
      description:
          'Kelas Bahasa Batak Toba dari dasar melalui latihan level, matching, review, dan badge LOKAGO.',
      mapX: 0.15,
      mapY: 0.32,
    ),
  ];

  @override
  void dispose() {
    _mapScrollController.dispose();
    super.dispose();
  }

  void _jumpToJavaArea() {
    if (_hasJumpedToJavaArea) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_mapScrollController.hasClients || _hasJumpedToJavaArea) return;

      final maxScroll = _mapScrollController.position.maxScrollExtent;
      final target = math.min(230.0, maxScroll);

      _mapScrollController.jumpTo(target);

      _hasJumpedToJavaArea = true;
    });
  }

  Future<void> _selectLanguageClass(_MapPinData pin) async {
    final user = _auth.currentUser;

    if (user == null) {
      _showSnackBar('User belum login.');
      return;
    }

    try {
      final userRef = _db.collection('users').doc(user.uid);
      final progressRef =
          userRef.collection('languageProgress').doc(pin.languageId);

      await _db.runTransaction((transaction) async {
        final progressSnapshot = await transaction.get(progressRef);

        transaction.set(
          userRef,
          {
            'selectedLanguageId': pin.languageId,
            'selectedLanguage': pin.title,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        if (!progressSnapshot.exists) {
          transaction.set(
            progressRef,
            {
              'languageId': pin.languageId,
              'languageName': pin.title,
              'currentLevel': 0,
              'maxUnlockedLevel': 1,
              'completedLevels': <int>[],
              'completedLessonIds': <String>[],
              'totalXp': 0,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        } else {
          transaction.set(
            progressRef,
            {
              'languageId': pin.languageId,
              'languageName': pin.title,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      });

      if (!mounted) return;

      Navigator.pop(context);

      _showSnackBar('${pin.title} berhasil dipilih.');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar('Gagal memilih kelas bahasa: $e');
    }
  }

  void _openClassSheet(_MapPinData pin) {
    final user = _auth.currentUser;

    if (user == null) {
      _showSnackBar('User belum login.');
      return;
    }

    setState(() {
      _selectedPin = pin;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final progressRef = _db
            .collection('users')
            .doc(user.uid)
            .collection('languageProgress')
            .doc(pin.languageId);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: progressRef.snapshots(),
          builder: (context, snapshot) {
            final progressData = snapshot.data?.data() ?? <String, dynamic>{};

            final completedLevels = _intList(progressData['completedLevels']);
            final maxUnlockedLevel =
                _readInt(progressData['maxUnlockedLevel'], 1);
            final totalXp = _readInt(progressData['totalXp'], 0);

            return _LanguageClassSheet(
              pin: pin,
              completedLevels: completedLevels,
              maxUnlockedLevel: maxUnlockedLevel,
              totalXp: totalXp,
              onSelectClass: () => _selectLanguageClass(pin),
            );
          },
        );
      },
    ).whenComplete(() {
      if (!mounted) return;

      setState(() {
        _selectedPin = null;
      });
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _jumpToJavaArea();

    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: _bgColor,
        bottomNavigationBar: _LokaBottomNav(currentIndex: 2),
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

        final userName = _readString(
          userData['name'],
          fallback: user.displayName ?? 'Bubi',
        );

        final hearts = _readInt(userData['hearts'], 5);
        final streakDays = _readInt(userData['streakDays'], 0);
        final selectedLanguageId = _normalizeLanguageId(
          userData['selectedLanguageId']?.toString() ??
              userData['selectedLanguage']?.toString(),
        );

        return Scaffold(
          backgroundColor: _bgColor,
          bottomNavigationBar: const _LokaBottomNav(currentIndex: 2),
          body: SafeArea(
            child: Column(
              children: [
                _Header(
                  userName: userName,
                  hearts: hearts,
                  streakDays: streakDays,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Peta Indonesia',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: _coral,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22),
                  child: Text(
                    'Jelajahi Indonesia dan Belajar Bahasanya!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _bgColor,
                          _bgColor,
                          Color(0xFFE6F5EF),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Scrollbar(
                          controller: _mapScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _mapScrollController,
                            scrollDirection: Axis.horizontal,
                            child: _IndonesiaMap(
                              pins: _pins,
                              selectedPin: _selectedPin,
                              selectedLanguageId: selectedLanguageId,
                              onTapPin: _openClassSheet,
                            ),
                          ),
                        ),
                      ],
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
    required this.userName,
    required this.hearts,
    required this.streakDays,
  });

  final String userName;
  final int hearts;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _green,
            child: Text(
              _initials(userName),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
          Row(
            children: [
              Text(
                '$hearts',
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
                size: 34,
              ),
            ],
          ),
          const SizedBox(width: 20),
          Row(
            children: [
              Text(
                '$streakDays',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _gold,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.local_fire_department_rounded,
                color: _gold,
                size: 34,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IndonesiaMap extends StatelessWidget {
  const _IndonesiaMap({
    required this.pins,
    required this.selectedPin,
    required this.selectedLanguageId,
    required this.onTapPin,
  });

  final List<_MapPinData> pins;
  final _MapPinData? selectedPin;
  final String selectedLanguageId;
  final ValueChanged<_MapPinData> onTapPin;

  @override
  Widget build(BuildContext context) {
    const mapCanvasWidth = 980.0;
    const mapCanvasHeight = 560.0;

    const mapImageWidth = 980.0;
    const mapImageHeight = mapImageWidth * 419 / 1161;
    const mapTop = 76.0;
    const mapLeft = 0.0;

    return SizedBox(
      width: mapCanvasWidth,
      height: mapCanvasHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: mapLeft,
            top: mapTop,
            width: mapImageWidth,
            height: mapImageHeight,
            child: Image.asset(
              'assets/images/peta/peta.png',
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) {
                return Container(
                  alignment: Alignment.center,
                  child: const Text(
                    'Asset map.png belum ditemukan',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _muted,
                    ),
                  ),
                );
              },
            ),
          ),
          ...pins.map((pin) {
            final isSelected = selectedPin?.id == pin.id;
            final isCurrentLanguage = pin.languageId == selectedLanguageId;

            const pinBoxWidth = 116.0;
            const pinTipOffsetY = 76.0;

            final pinLeft = mapLeft + (mapImageWidth * pin.mapX) - (pinBoxWidth / 2);
            final pinTop = mapTop + (mapImageHeight * pin.mapY) - pinTipOffsetY;

            return Positioned(
              left: pinLeft,
              top: pinTop,
              child: _LanguageMapPin(
                pin: pin,
                isSelected: isSelected,
                isCurrentLanguage: isCurrentLanguage,
                onTap: () => onTapPin(pin),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LanguageMapPin extends StatelessWidget {
  const _LanguageMapPin({
    required this.pin,
    required this.isSelected,
    required this.isCurrentLanguage,
    required this.onTap,
  });

  final _MapPinData pin;
  final bool isSelected;
  final bool isCurrentLanguage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const markerSize = 52.0;
    const pinBoxWidth = 116.0;
    const pinBoxHeight = 126.0;

    return SizedBox(
      width: pinBoxWidth,
      height: pinBoxHeight,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isSelected ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: 0,
                child: SizedBox(
                  height: 24,
                  child: isCurrentLanguage
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Aktif',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: _greenDark,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              Positioned(
                top: 24,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: isCurrentLanguage
                            ? _greenDark
                            : const Color(0xFF0F9D6C),
                        size: markerSize,
                      ),
                    ),
                    Icon(
                      Icons.location_on_rounded,
                      color: isCurrentLanguage
                          ? _green
                          : const Color(0xFF67C2A7),
                      size: markerSize,
                    ),
                    Positioned(
                      top: markerSize * 0.28,
                      child: CircleAvatar(
                        radius: markerSize * 0.16,
                        backgroundColor: _bgColor,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 82,
                child: Column(
                  children: [
                    _OutlinedText(
                      text: pin.title,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isCurrentLanguage ? _greenDark : _coral,
                      strokeColor: Colors.white,
                      strokeWidth: 4,
                    ),
                    _OutlinedText(
                      text: pin.subtitle,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: _muted,
                      strokeColor: Colors.white,
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlinedText extends StatelessWidget {
  const _OutlinedText({
    required this.text,
    required this.fontSize,
    required this.fontWeight,
    required this.color,
    required this.strokeColor,
    required this.strokeWidth,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final Color strokeColor;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = strokeColor,
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _LanguageClassSheet extends StatelessWidget {
  const _LanguageClassSheet({
    required this.pin,
    required this.completedLevels,
    required this.maxUnlockedLevel,
    required this.totalXp,
    required this.onSelectClass,
  });

  final _MapPinData pin;
  final List<int> completedLevels;
  final int maxUnlockedLevel;
  final int totalXp;
  final VoidCallback onSelectClass;

  @override
  Widget build(BuildContext context) {
    final completedCount = completedLevels.length;
    final progressValue = (completedCount / 30).clamp(0.0, 1.0);
    final progressPercent = (progressValue * 100).round();

    return Container(
      decoration: const BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFFFF0EC),
                  child: Icon(
                    _languageIconFromId(pin.languageId),
                    color: _coral,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelas ${pin.title}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pin.subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _coral,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _WhiteCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                pin.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SmallStatCard(
                    icon: Icons.flag_rounded,
                    label: 'Level Terbuka',
                    value: '$maxUnlockedLevel/30',
                    color: _green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SmallStatCard(
                    icon: Icons.check_circle_rounded,
                    label: 'Selesai',
                    value: '$completedCount',
                    color: _coral,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SmallStatCard(
                    icon: Icons.bolt_rounded,
                    label: 'XP',
                    value: '$totalXp',
                    color: _gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _WhiteCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.timeline_rounded,
                        color: _green,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Progress Kelas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _textDark,
                          ),
                        ),
                      ),
                      Text(
                        '$progressPercent%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 11,
                      backgroundColor: const Color(0xFFE3E3E3),
                      valueColor: const AlwaysStoppedAnimation<Color>(_green),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$completedCount dari 30 level selesai',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _MainActionButton(
              text: 'PILIH KELAS INI',
              icon: Icons.play_arrow_rounded,
              onTap: onSelectClass,
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  const _SmallStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 26,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MainActionButton extends StatefulWidget {
  const _MainActionButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_MainActionButton> createState() => _MainActionButtonState();
}

class _MainActionButtonState extends State<_MainActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _pressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _pressed = false;
        });
      },
      onTapCancel: () {
        setState(() {
          _pressed = false;
        });
      },
      onTap: widget.onTap,
      child: SizedBox(
        height: 66,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF6CC1A8),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOut,
              top: _pressed ? 8 : 0,
              left: 0,
              right: 0,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: _greenDark,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPinData {
  const _MapPinData({
    required this.id,
    required this.languageId,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.mapX,
    required this.mapY,
  });

  final String id;
  final String languageId;
  final String title;
  final String subtitle;
  final String description;
  final double mapX;
  final double mapY;
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
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: const Color(0xFFD9D4D6),
              width: 2,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4E4E4E),
            ),
          ),
        ),
        Positioned(
          left: 24,
          bottom: -8,
          child: Transform.rotate(
            angle: 0.78,
            child: Container(
              width: 15,
              height: 15,
              decoration: const BoxDecoration(
                color: _bgColor,
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

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.065),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
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
                  page = const PetaPage();
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

String _normalizeLanguageId(String? value) {
  final raw = (value ?? '').trim().toLowerCase();
  if (raw.contains('batak') || raw.contains('toba')) return 'batak_toba';
  if (raw.contains('jawa')) return 'jawa';
  if (raw.contains('sunda')) return 'sunda';

  return 'sunda';
}

String _languageNameFromId(String languageId) {
  if (languageId == 'jawa') return 'Bahasa Jawa';

  return 'Bahasa Sunda';
}

IconData _languageIconFromId(String languageId) {
  if (languageId == 'jawa') return Icons.record_voice_over_rounded;

  return Icons.translate_rounded;
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

List<int> _intList(dynamic value) {
  if (value is! List) return [];

  return value
      .map((item) => int.tryParse(item.toString()))
      .whereType<int>()
      .toSet()
      .toList()
    ..sort();
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