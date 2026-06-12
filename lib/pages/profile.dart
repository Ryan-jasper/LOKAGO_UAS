import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/button.dart';
import 'home.dart';
import 'peta.dart';
import 'streak.dart';
import 'splash.dart';
import 'dart:async';

const Color _bgColor = Color(0xFFF4F4F4);
const Color _coral = Color(0xFFE2775B);
const Color _green = Color(0xFF69C3A8);
const Color _textDark = Color(0xFF232248);
const Color _muted = Color(0xFF7E7E99);
const Color _danger = Color(0xFFD6372A);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isRefillingHeart = false;

  Future<void> _refillHeart(_ProfileData profile) async {
    final user = _auth.currentUser;

    if (user == null) {
      _showSnackBar('User belum login.');
      return;
    }

    setState(() {
      _isRefillingHeart = true;
    });

    try {
      await _db.collection('users').doc(user.uid).set(
        {
          'hearts': profile.maxHearts,
          'maxHearts': profile.maxHearts,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      _showSnackBar('Heart berhasil diisi ulang.');
    } catch (e) {
      if (!mounted) return;

      _showSnackBar('Gagal mengisi ulang heart: $e');
    } finally {
      if (!mounted) return;

      setState(() {
        _isRefillingHeart = false;
      });
    }
  }

  Future<void> _confirmSignOut() async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text(
          'Keluar dari akun?',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _textDark,
          ),
        ),
        content: const Text(
          'Kamu bisa masuk kembali menggunakan email dan sandi yang sama.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Keluar',
              style: TextStyle(
                color: _danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (shouldLogout != true) return;

  await _auth.signOut();

  if (!mounted) return;

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => const SplashPage(),
    ),
    (route) => false,
  );
}

  void _openLanguagePage() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const _LanguageMenuPage(),
        ),
      );
    }

  void _openProfileSettings(_ProfileData profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProfileSettingsPage(profile: profile),
      ),
    );
  }

  void _openNotificationSettings(_ProfileData profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _NotificationSettingsPage(profile: profile),
      ),
    );
  }

  void _openBadgePage(_ProfileData profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _BadgePage(profile: profile),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget _buildLoggedOutState() {
  return const SplashPage();
  }

  Widget _buildLoadingState() {
    return const Scaffold(
      backgroundColor: _bgColor,
      bottomNavigationBar: _LokaBottomNav(currentIndex: 3),
      body: Center(
        child: CircularProgressIndicator(
          color: _coral,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return _buildLoggedOutState();
    }

    final userRef = _db.collection('users').doc(user.uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userRef.snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final userData = userSnapshot.data?.data() ?? <String, dynamic>{};

        final selectedLanguageId = _normalizeLanguageId(
          userData['selectedLanguageId']?.toString() ??
              userData['selectedLanguage']?.toString(),
        );

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userRef
              .collection('languageProgress')
              .doc(selectedLanguageId)
              .snapshots(),
          builder: (context, progressSnapshot) {
            final progressData =
                progressSnapshot.data?.data() ?? <String, dynamic>{};

            final profile = _ProfileData.fromFirestore(
              user: user,
              userData: userData,
              progressData: progressData,
              selectedLanguageId: selectedLanguageId,
            );

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: _bgColor,
              endDrawer: _ProfileDrawer(
                profile: profile,
                onOpenProfileSettings: () => _openProfileSettings(profile),
                onOpenNotification: () => _openNotificationSettings(profile),
                onOpenLanguage: _openLanguagePage,
                onOpenBadge: () => _openBadgePage(profile),
                onLogout: _confirmSignOut,
              ),
              bottomNavigationBar: const _LokaBottomNav(currentIndex: 3),
              body: SafeArea(
                child: Container(
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileHeader(
                          onBack: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HomePage(),
                              ),
                            );
                          },
                          onOpenDrawer: () {
                            _scaffoldKey.currentState?.openEndDrawer();
                          },
                        ),
                        const SizedBox(height: 18),
                        _ProfileHeroCard(profile: profile),
                        const SizedBox(height: 18),
                        _ProfileDashboardSection(
                          profile: profile,
                          isRefillingHeart: _isRefillingHeart,
                          onRefillHeart: profile.hearts >= profile.maxHearts
                              ? null
                              : () => _refillHeart(profile),
                          onOpenLanguage: _openLanguagePage,
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.onBack,
    required this.onOpenDrawer,
  });

  final VoidCallback onBack;
  final VoidCallback onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack,
        ),
        const Spacer(),
        const Text(
          'Profil',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: _textDark,
          ),
        ),
        const Spacer(),
        _CircleIconButton(
          icon: Icons.menu_rounded,
          onTap: onOpenDrawer,
        ),
      ],
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.profile,
  });

  final _ProfileData profile;

  @override
  Widget build(BuildContext context) {
    final displayBadge = _badgeById(profile.displayBadgeId);

    return _WhiteCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          _ProfileAvatar(name: profile.name),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: _textDark,
                        ),
                      ),
                    ),
                    if (displayBadge != null) ...[
                      const SizedBox(width: 8),
                      _MiniBadge(badge: displayBadge),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 12),
                _LanguagePill(languageName: profile.languageName),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDashboardSection extends StatelessWidget {
  const _ProfileDashboardSection({
    required this.profile,
    required this.isRefillingHeart,
    required this.onRefillHeart,
    required this.onOpenLanguage,
  });

  final _ProfileData profile;
  final bool isRefillingHeart;
  final VoidCallback? onRefillHeart;
  final VoidCallback onOpenLanguage;

  @override
  Widget build(BuildContext context) {
    final refillDisabled = onRefillHeart == null || isRefillingHeart;

    return Column(
      children: [
        _BigStreakCard(profile: profile),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _XpLevelCard(profile: profile),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HeartStatusCard(profile: profile),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _LearningProgressChartCard(profile: profile),
        const SizedBox(height: 12),
        Button(
          text: 'ATUR BAHASA',
          onTap: onOpenLanguage,
          buttonColor: const Color(0xFF0F9D6C),
          shadowColor: const Color(0xFF6CC1A8),
          leading: const Icon(
            Icons.translate_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _BigStreakCard extends StatelessWidget {
  const _BigStreakCard({
    required this.profile,
  });

  final _ProfileData profile;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: _coral,
              size: 42,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Streak Belajar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${profile.streakDays} Hari',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Pertahankan ritme belajar kamu setiap hari.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: _muted,
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

class _XpLevelCard extends StatelessWidget {
  const _XpLevelCard({
    required this.profile,
  });

  final _ProfileData profile;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFFFF6DA),
            child: Icon(
              Icons.bolt_rounded,
              color: Color(0xFFF4B11A),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${profile.totalXp} XP',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Level terbuka ${profile.maxUnlockedLevel}/30',
            style: const TextStyle(
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w800,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartStatusCard extends StatelessWidget {
  const _HeartStatusCard({
    required this.profile,
  });

  final _ProfileData profile;

  @override
  Widget build(BuildContext context) {
    final isEmpty = profile.hearts <= 0;

    return _WhiteCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                isEmpty ? const Color(0xFFFFE8E4) : const Color(0xFFFFF0EC),
            child: Icon(
              isEmpty ? Icons.favorite_border_rounded : Icons.favorite_rounded,
              color: _danger,
              size: 27,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${profile.hearts}/${profile.maxHearts}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEmpty ? 'Heart habis' : 'Heart tersedia',
            style: const TextStyle(
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w800,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningProgressChartCard extends StatelessWidget {
  const _LearningProgressChartCard({
    required this.profile,
  });

  final _ProfileData profile;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFE7F7F1),
                child: Icon(
                  Icons.show_chart_rounded,
                  color: _green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Progress ${profile.languageName}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                  ),
                ),
              ),
              Text(
                '${profile.progressPercent}%',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(
              painter: _ProgressLinePainter(
                completedLevels: profile.completedLevels,
                maxLevel: 30,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${profile.completedLevelCount} dari 30 level selesai',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _muted,
                  ),
                ),
              ),
              Text(
                'Aktif: ${profile.languageName}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: _coral,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressLinePainter extends CustomPainter {
  const _ProgressLinePainter({
    required this.completedLevels,
    required this.maxLevel,
  });

  final List<int> completedLevels;
  final int maxLevel;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE7E7E7)
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = const Color(0xFFD8D8D8)
      ..strokeWidth = 1.4;

    final linePaint = Paint()
      ..color = _green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = _green.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = _green
      ..style = PaintingStyle.fill;

    final emptyDotPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.fill;

    const leftPadding = 10.0;
    const rightPadding = 10.0;
    const topPadding = 10.0;
    const bottomPadding = 24.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    for (int i = 0; i <= 4; i++) {
      final y = topPadding + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + chartHeight),
      axisPaint,
    );

    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(size.width - rightPadding, topPadding + chartHeight),
      axisPaint,
    );

    final completedSet = completedLevels.toSet();
    final points = <Offset>[];

    int cumulativeCompleted = 0;

    for (int level = 1; level <= maxLevel; level++) {
      if (completedSet.contains(level)) {
        cumulativeCompleted++;
      }

      final x = leftPadding + ((level - 1) / (maxLevel - 1)) * chartWidth;
      final progress = cumulativeCompleted / maxLevel;
      final y = topPadding + chartHeight - (progress * chartHeight);

      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, topPadding + chartHeight)
      ..lineTo(points.first.dx, topPadding + chartHeight)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (final level in [1, 5, 10, 15, 20, 25, 30]) {
      final point = points[level - 1];
      final completed = completedSet.contains(level);

      canvas.drawCircle(
        point,
        completed ? 5.5 : 4.5,
        completed ? dotPaint : emptyDotPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$level',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: _muted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          point.dx - textPainter.width / 2,
          size.height - 16,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressLinePainter oldDelegate) {
    return oldDelegate.completedLevels != completedLevels ||
        oldDelegate.maxLevel != maxLevel;
  }
}

class _ProfileDrawer extends StatelessWidget {
  const _ProfileDrawer({
    required this.profile,
    required this.onOpenProfileSettings,
    required this.onOpenNotification,
    required this.onOpenLanguage,
    required this.onOpenBadge,
    required this.onLogout,
  });

  final _ProfileData profile;
  final VoidCallback onOpenProfileSettings;
  final VoidCallback onOpenNotification;
  final VoidCallback onOpenLanguage;
  final VoidCallback onOpenBadge;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.86,
      backgroundColor: _bgColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  _ProfileAvatar(
                    name: profile.name,
                    radius: 25,
                    fontSize: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _textDark,
                      ),
                    ),
                  ),
                  _CircleIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
              child: _DrawerProgressCard(profile: profile),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  _DrawerTile(
                    icon: Icons.manage_accounts_rounded,
                    title: 'Pengaturan Profil',
                    subtitle: 'Edit nama dan data akun',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenProfileSettings();
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notifikasi',
                    subtitle: 'Atur pengingat belajar',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenNotification();
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.translate_rounded,
                    title: 'Bahasa',
                    subtitle: profile.languageName,
                    onTap: () {
                      Navigator.pop(context);
                      onOpenLanguage();
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.emoji_events_outlined,
                    title: 'Badge',
                    subtitle: 'Pilih badge yang ingin dipajang',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenBadge();
                    },
                  ),
                  const SizedBox(height: 12),
                  Button(
                    text: 'KELUAR',
                    onTap: () {
                      Navigator.pop(context);
                      onLogout();
                    },
                    buttonColor: _danger,
                    shadowColor: const Color(0xFFF0B2AA),
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerProgressCard extends StatelessWidget {
  const _DrawerProgressCard({
    required this.profile,
  });

  final _ProfileData profile;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.languageName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 10),
          _ProgressBar(value: profile.progressValue),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${profile.completedLevelCount}/30 level',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                  ),
                ),
              ),
              const Icon(
                Icons.favorite_rounded,
                color: _danger,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '${profile.hearts}/${profile.maxHearts}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: _danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: const Color(0xFFFFF0EC),
                  child: Icon(
                    icon,
                    color: _coral,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: _muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageMenuPage extends StatefulWidget {
  const _LanguageMenuPage();

  @override
  State<_LanguageMenuPage> createState() => _LanguageMenuPageState();
}

class _LanguageMenuPageState extends State<_LanguageMenuPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isSaving = false;

  final List<_LanguageOption> _languages = const [
    _LanguageOption(
      id: 'sunda',
      name: 'Bahasa Sunda',
      nativeName: 'Basa Sunda',
      region: 'Jawa Barat dan Banten',
      isAvailable: true,
    ),
    _LanguageOption(
      id: 'jawa',
      name: 'Bahasa Jawa',
      nativeName: 'Basa Jawa',
      region: 'Jawa Tengah, Yogyakarta, Jawa Timur',
      isAvailable: true,
    ),
    _LanguageOption(
      id: 'batak_toba',
      name: 'Bahasa Batak Toba',
      nativeName: 'Hata Batak Toba',
      region: 'Sumatra Utara',
      isAvailable: true,
    ),
  ];

  Future<void> _selectLanguage(_LanguageOption option) async {
    if (!option.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${option.name} belum tersedia.'),
        ),
      );
      return;
    }

    final user = _auth.currentUser;

    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final userRef = _db.collection('users').doc(user.uid);

      await userRef.set(
        {
          'selectedLanguageId': option.id,
          'selectedLanguage': option.name,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await userRef.collection('languageProgress').doc(option.id).set(
        {
          'languageId': option.id,
          'languageName': option.name,
          'currentLevel': 0,
          'maxUnlockedLevel': 1,
          'completedLevels': <int>[],
          'totalXp': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${option.name} berhasil dipilih.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih bahasa: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: Text('User belum login.'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final activeLanguage = _normalizeLanguageId(
          data['selectedLanguageId']?.toString() ??
              data['selectedLanguage']?.toString(),
        );

        return Scaffold(
          backgroundColor: _bgColor,
          bottomNavigationBar: const _LokaBottomNav(currentIndex: 3),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        'Bahasa',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _textDark,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 46),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Pilih bahasa daerah yang ingin kamu pelajari.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ..._languages.map((language) {
                    final active = language.id == activeLanguage;

                    return _LanguageOptionCard(
                      language: language,
                      active: active,
                      loading: _isSaving,
                      onTap: () => _selectLanguage(language),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  const _LanguageOptionCard({
    required this.language,
    required this.active,
    required this.loading,
    required this.onTap,
  });

  final _LanguageOption language;
  final bool active;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = !language.isAvailable;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: disabled ? const Color(0xFFEDEDED) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: active ? _green : const Color(0xFFE1E1E8),
                width: active ? 2 : 1.4,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor:
                      active ? const Color(0xFFE7F7F1) : const Color(0xFFFFF0EC),
                  child: Icon(
                    active ? Icons.check_rounded : Icons.translate_rounded,
                    color: active ? _green : _coral,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: disabled ? Colors.grey : _textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${language.nativeName} • ${language.region}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (active)
                  const Text(
                    'Aktif',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: _green,
                    ),
                  )
                else if (!language.isAvailable)
                  const Text(
                    'Segera',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: _muted,
                    ),
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: _muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSettingsPage extends StatefulWidget {
  const _ProfileSettingsPage({
    required this.profile,
  });

  final _ProfileData profile;

  @override
  State<_ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<_ProfileSettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late final TextEditingController _nameController;
  late final TextEditingController _birthController;

  DateTime? _selectedBirthDate;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.profile.name);
    _birthController = TextEditingController(text: widget.profile.birthDate);
    _selectedBirthDate = _parseBirthDate(widget.profile.birthDate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthController.dispose();
    super.dispose();
  }

  DateTime? _parseBirthDate(String value) {
    final parts = value.split('/');

    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return null;

    final parsed = DateTime(year, month, day);

    if (parsed.day != day || parsed.month != month || parsed.year != year) {
      return null;
    }

    return parsed;
  }

  String _formatBirthDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _openBirthDatePicker() {
    DateTime tempDate = _selectedBirthDate ?? DateTime(2005, 1, 1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF9A9A9A),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedBirthDate = tempDate;
                          _birthController.text = _formatBirthDate(tempDate);
                        });

                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Pilih',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempDate,
                  minimumYear: 1950,
                  maximumYear: DateTime.now().year,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (DateTime newDate) {
                    tempDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;

    if (user == null) return;

    final name = _nameController.text.trim().isEmpty
        ? 'Bubi'
        : _nameController.text.trim();

    final birthDate = _birthController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      await user.updateDisplayName(name);

      await _db.collection('users').doc(user.uid).set(
        {
          'name': name,
          'birthDate': birthDate,
          'email': user.email ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil disimpan.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan profil: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _openDeleteAccountDialog() async {
  final confirmController = TextEditingController();
  bool isMatched = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text(
              'Hapus Akun?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: _textDark,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tindakan ini akan menghapus akun dan data belajar kamu. Untuk melanjutkan, ketik nama profil kamu:',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.profile.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _danger,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: confirmController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Ketik nama di sini',
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onChanged: (value) {
                    final inputName = value.trim().toLowerCase();
                    final realName = widget.profile.name.trim().toLowerCase();

                    setDialogState(() {
                      isMatched = inputName == realName;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: isMatched
                    ? () {
                        Navigator.pop(dialogContext);

                        Future.delayed(const Duration(milliseconds: 250), () {
                          if (!mounted) return;
                          _deleteAccount();
                        });
                      }
                    : null,
                child: Text(
                  'Hapus Akun',
                  style: TextStyle(
                    color: isMatched ? _danger : Colors.grey,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  confirmController.dispose();
}

Future<void> _deleteAccount() async {
  final user = _auth.currentUser;

  if (user == null) {
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const SplashPage(),
      ),
      (route) => false,
    );
    return;
  }

  setState(() {
    _isDeleting = true;
  });

  bool loadingDialogOpen = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      loadingDialogOpen = true;

      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: _coral,
              ),
              SizedBox(height: 18),
              Text(
                'Menghapus akun...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _textDark,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Mohon tunggu sebentar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  try {
    final uid = user.uid;

    debugPrint('LOKAGO DELETE -> mulai hapus Firestore');

    await _deleteUserFirestoreData(uid).timeout(
      const Duration(seconds: 12),
    );

    debugPrint('LOKAGO DELETE -> Firestore selesai');
    debugPrint('LOKAGO DELETE -> mulai hapus Firebase Auth');

    await user.delete().timeout(
      const Duration(seconds: 12),
    );

    debugPrint('LOKAGO DELETE -> Firebase Auth selesai');

    if (!mounted) return;

    if (loadingDialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      loadingDialogOpen = false;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const SplashPage(),
      ),
      (route) => false,
    );
  } on FirebaseAuthException catch (e) {
    debugPrint('LOKAGO DELETE -> FirebaseAuthException: ${e.code}');

    if (!mounted) return;

    if (loadingDialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      loadingDialogOpen = false;
    }

    String message = 'Gagal menghapus akun: ${e.message ?? e.code}';

    if (e.code == 'requires-recent-login') {
      message =
          'Untuk menghapus akun, Firebase meminta login ulang. Silakan logout, login lagi, lalu coba hapus akun.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  } on TimeoutException catch (_) {
    debugPrint('LOKAGO DELETE -> timeout');

    if (!mounted) return;

    if (loadingDialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      loadingDialogOpen = false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Proses hapus akun terlalu lama. Periksa koneksi internet, lalu coba lagi.',
        ),
      ),
    );
  } catch (e) {
    debugPrint('LOKAGO DELETE -> error: $e');

    if (!mounted) return;

    if (loadingDialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      loadingDialogOpen = false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal menghapus akun: $e'),
      ),
    );
  } finally {
    if (!mounted) return;

    setState(() {
      _isDeleting = false;
    });
  }
}

Future<void> _deleteUserFirestoreData(String uid) async {
  final userRef = _db.collection('users').doc(uid);

  final languageProgressSnapshot =
      await userRef.collection('languageProgress').get();

  final progressStart = '${uid}_';
  final progressEnd = '${uid}_\uf8ff';

  final userProgressSnapshot = await _db
      .collection('userProgress')
      .where(
        FieldPath.documentId,
        isGreaterThanOrEqualTo: progressStart,
      )
      .where(
        FieldPath.documentId,
        isLessThanOrEqualTo: progressEnd,
      )
      .get();

  final refsToDelete = [
    ...languageProgressSnapshot.docs.map((doc) => doc.reference),
    ...userProgressSnapshot.docs.map((doc) => doc.reference),
    userRef,
  ];

  for (int i = 0; i < refsToDelete.length; i += 400) {
    final batch = _db.batch();
    final end = (i + 400 > refsToDelete.length)
        ? refsToDelete.length
        : i + 400;

    for (final ref in refsToDelete.sublist(i, end)) {
      batch.delete(ref);
    }

    await batch.commit();
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      bottomNavigationBar: const _LokaBottomNav(currentIndex: 3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubPageHeader(
                title: 'Pengaturan Profil',
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 22),
              _WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _InputLabel('Nama'),
                    _ProfileInput(
                      controller: _nameController,
                      hintText: 'Masukkan nama',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    const _InputLabel('Tanggal Lahir'),
                    _ProfileInput(
                      controller: _birthController,
                      hintText: 'Pilih tanggal lahir',
                      icon: Icons.cake_outlined,
                      readOnly: true,
                      onTap: _openBirthDatePicker,
                      suffixIcon: const Icon(
                        Icons.calendar_today_rounded,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _InputLabel('Email'),
                    _ReadonlyField(
                      text: widget.profile.email,
                      icon: Icons.mail_outline_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Button(
                text: _isSaving ? 'MENYIMPAN...' : 'SIMPAN PROFIL',
                onTap: _isSaving ? () {} : _saveProfile,
                buttonColor: _coral,
                shadowColor: const Color(0xFFF0B2AA),
                leading: const Icon(
                  Icons.save_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(height: 14),
              Button(
                text: _isDeleting ? 'MENGHAPUS AKUN...' : 'HAPUS AKUN',
                onTap: (_isSaving || _isDeleting) ? () {} : _openDeleteAccountDialog,
                buttonColor: _danger,
                shadowColor: const Color(0xFFF0B2AA),
                leading: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationSettingsPage extends StatefulWidget {
  const _NotificationSettingsPage({
    required this.profile,
  });

  final _ProfileData profile;

  @override
  State<_NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<_NotificationSettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late Map<String, bool> _settings;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _settings = {...widget.profile.notificationSettings};
  }

  Future<void> _saveSettings() async {
    final user = _auth.currentUser;

    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _db.collection('users').doc(user.uid).set(
        {
          'notificationSettings': _settings,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan notifikasi berhasil disimpan.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan notifikasi: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  void _setValue(String key, bool value) {
    setState(() {
      _settings[key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      bottomNavigationBar: const _LokaBottomNav(currentIndex: 3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubPageHeader(
                title: 'Notifikasi',
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 14),
              const Text(
                'Atur jenis notifikasi yang ingin kamu terima. Untuk tahap ini pengaturan akan disimpan dulu di Firestore.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 18),
              _NotificationTile(
                icon: Icons.school_rounded,
                title: 'Pengingat Belajar',
                subtitle: 'Mengingatkan kamu untuk belajar setiap hari.',
                value: _settings['studyReminder'] ?? true,
                onChanged: (value) => _setValue('studyReminder', value),
              ),
              _NotificationTile(
                icon: Icons.local_fire_department_rounded,
                title: 'Pengingat Streak',
                subtitle: 'Mengingatkan jika streak harian belum dijaga.',
                value: _settings['streakReminder'] ?? true,
                onChanged: (value) => _setValue('streakReminder', value),
              ),
              _NotificationTile(
                icon: Icons.favorite_rounded,
                title: 'Heart Penuh',
                subtitle: 'Memberi tahu ketika heart sudah terisi penuh.',
                value: _settings['heartReminder'] ?? true,
                onChanged: (value) => _setValue('heartReminder', value),
              ),
              _NotificationTile(
                icon: Icons.emoji_events_rounded,
                title: 'Badge Baru',
                subtitle: 'Memberi tahu ketika kamu mendapatkan badge baru.',
                value: _settings['badgeNotification'] ?? true,
                onChanged: (value) => _setValue('badgeNotification', value),
              ),
              const SizedBox(height: 18),
              Button(
                text: _isSaving ? 'MENYIMPAN...' : 'SIMPAN NOTIFIKASI',
                onTap: _isSaving ? () {} : _saveSettings,
                buttonColor: _coral,
                shadowColor: const Color(0xFFF0B2AA),
                leading: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgePage extends StatelessWidget {
  const _BadgePage({
    required this.profile,
  });

  final _ProfileData profile;

  Future<void> _selectBadge(BuildContext context, String badgeId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'displayBadgeId': badgeId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Badge berhasil dipajang di profil.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih badge: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final earnedBadges = profile.earnedBadgeIds
        .map(_badgeById)
        .whereType<_BadgeInfo>()
        .toList();

    return Scaffold(
      backgroundColor: _bgColor,
      bottomNavigationBar: const _LokaBottomNav(currentIndex: 3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubPageHeader(
                title: 'Badge',
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 14),
              const Text(
                'Pilih salah satu badge yang sudah kamu kumpulkan untuk dipajang di sebelah nama profil.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 18),
              if (earnedBadges.isEmpty)
                const _EmptyBadgeCard()
              else
                ...earnedBadges.map((badge) {
                  final selected = badge.id == profile.displayBadgeId;

                  return _BadgeSelectCard(
                    badge: badge,
                    selected: selected,
                    onTap: () => _selectBadge(context, badge.id),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubPageHeader extends StatelessWidget {
  const _SubPageHeader({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack,
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: _textDark,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 46),
      ],
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: _muted,
        ),
      ),
    );
  }
}

class _ProfileInput extends StatelessWidget {
  const _ProfileInput({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: _textDark,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(
          icon,
          color: _muted,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Color(0xFFE1E1E8),
            width: 1.4,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Color(0xFFE1E1E8),
            width: 1.4,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: _coral,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE1E1E8),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: _muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFFFF0EC),
            child: Icon(
              icon,
              color: _coral,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: _green,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _BadgeSelectCard extends StatelessWidget {
  const _BadgeSelectCard({
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  final _BadgeInfo badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected ? _green : const Color(0xFFE1E1E8),
                width: selected ? 2 : 1.4,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: badge.color.withOpacity(0.14),
                  child: Icon(
                    badge.icon,
                    color: badge.color,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        badge.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        badge.description,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: _green,
                    size: 26,
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: _muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyBadgeCard extends StatelessWidget {
  const _EmptyBadgeCard();

  @override
  Widget build(BuildContext context) {
    return const _WhiteCard(
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 70,
            color: _muted,
          ),
          SizedBox(height: 14),
          Text(
            'Belum ada badge',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _textDark,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Selesaikan level dan pertahankan streak untuk mendapatkan badge.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.badge,
  });

  final _BadgeInfo badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: badge.title,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: badge.color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          badge.icon,
          color: badge.color,
          size: 18,
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      bottomNavigationBar: const _LokaBottomNav(currentIndex: 3),
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textDark),
        title: Text(
          title,
          style: const TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _WhiteCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.construction_rounded,
                  size: 72,
                  color: _coral,
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fitur ini masih dalam tahap pengembangan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.name,
    this.radius = 34,
    this.fontSize = 22,
  });

  final String name;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _green,
      child: Text(
        _initials(name),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({
    required this.languageName,
  });

  final String languageName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        languageName,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: _coral,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
  });

  final double value;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0).toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: safeValue,
        minHeight: 11,
        backgroundColor: const Color(0xFFE3E3E3),
        valueColor: const AlwaysStoppedAnimation<Color>(_green),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: _textDark,
            size: 23,
          ),
        ),
      ),
    );
  }
}

class _ProfileNote extends StatelessWidget {
  const _ProfileNote({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          height: 1.35,
          fontWeight: FontWeight.w700,
          color: _textDark,
        ),
      ),
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
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.065),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.name,
    required this.email,
    required this.birthDate,
    required this.languageName,
    required this.selectedLanguageId,
    required this.totalXp,
    required this.streakDays,
    required this.hearts,
    required this.maxHearts,
    required this.maxUnlockedLevel,
    required this.completedLevelCount,
    required this.completedLevels,
    required this.earnedBadgeIds,
    required this.displayBadgeId,
    required this.notificationSettings,
  });

  final String name;
  final String email;
  final String birthDate;
  final String languageName;
  final String selectedLanguageId;
  final int totalXp;
  final int streakDays;
  final int hearts;
  final int maxHearts;
  final int maxUnlockedLevel;
  final int completedLevelCount;
  final List<int> completedLevels;
  final List<String> earnedBadgeIds;
  final String displayBadgeId;
  final Map<String, bool> notificationSettings;

  double get progressValue => completedLevelCount / 30;

  int get progressPercent => (progressValue * 100).round();

  factory _ProfileData.fromFirestore({
    required User user,
    required Map<String, dynamic> userData,
    required Map<String, dynamic> progressData,
    required String selectedLanguageId,
  }) {
    final name = _readString(
      userData['name'],
      fallback: user.displayName ?? 'Bubi',
    );

    final email = user.email ?? _readString(userData['email'], fallback: '-');

    final completedLevels = _readIntList(
      progressData['completedLevels'],
    );

    final maxHearts = _readInt(userData['maxHearts'], 5);
    final rawHearts = _readInt(userData['hearts'], maxHearts);
    final hearts = rawHearts.clamp(0, maxHearts).toInt();

    final generatedBadgeIds = _generateEarnedBadges(
      languageId: selectedLanguageId,
      completedLevels: completedLevels,
    );

    final storedBadgeIds = _readStringList(userData['earnedBadgeIds']);

    final earnedBadgeIds = {
      ...storedBadgeIds,
      ...generatedBadgeIds,
    }.where((badgeId) => _badgeById(badgeId) != null).toList();

    final rawDisplayBadgeId = _readString(
      userData['displayBadgeId'],
      fallback: '',
    );

    final displayBadgeId = earnedBadgeIds.contains(rawDisplayBadgeId)
        ? rawDisplayBadgeId
        : earnedBadgeIds.isNotEmpty
            ? earnedBadgeIds.first
            : '';

    return _ProfileData(
      name: name.trim().isEmpty ? 'Bubi' : name,
      email: email,
      birthDate: _readString(userData['birthDate'], fallback: ''),
      languageName: _languageNameFromId(selectedLanguageId),
      selectedLanguageId: selectedLanguageId,
      totalXp: _readInt(userData['totalXp'], 0),
      streakDays: _readInt(userData['streakDays'], 0),
      hearts: hearts,
      maxHearts: maxHearts,
      maxUnlockedLevel: _readInt(progressData['maxUnlockedLevel'], 1),
      completedLevelCount: completedLevels.length,
      completedLevels: completedLevels,
      earnedBadgeIds: earnedBadgeIds,
      displayBadgeId: displayBadgeId,
      notificationSettings: _readNotificationSettings(
        userData['notificationSettings'],
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption({
    required this.id,
    required this.name,
    required this.nativeName,
    required this.region,
    required this.isAvailable,
  });

  final String id;
  final String name;
  final String nativeName;
  final String region;
  final bool isAvailable;
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
                  page = const ProfilePage();
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
  const _NavItemData(
    this.label,
    this.icon,
  );

  final String label;
  final IconData icon;
}

class _BadgeInfo {
  const _BadgeInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

_BadgeInfo? _badgeById(String id) {
  final badgeId = id.trim();

  if (badgeId.isEmpty) return null;

  final parts = badgeId.split('_level_');

  if (parts.length != 2) return null;

  final languageId = parts[0];
  final levelNo = int.tryParse(parts[1]);

  if (levelNo == null) return null;

  final languageName = _languageNameFromId(languageId);
  final shortLanguageName = _languageShortNameFromId(languageId);

  if (levelNo == 5) {
    return _BadgeInfo(
      id: badgeId,
      title: 'Awal $shortLanguageName',
      description: 'Menyelesaikan 5 level pertama $languageName.',
      icon: Icons.flag_rounded,
      color: _green,
    );
  }

  if (levelNo == 15) {
    return _BadgeInfo(
      id: badgeId,
      title: 'Penjelajah $shortLanguageName',
      description: 'Menyelesaikan 15 level $languageName.',
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFFF4B11A),
    );
  }

  if (levelNo == 30) {
    return _BadgeInfo(
      id: badgeId,
      title: 'Master $shortLanguageName',
      description: 'Menyelesaikan seluruh 30 level $languageName.',
      icon: Icons.workspace_premium_rounded,
      color: const Color(0xFF8E6BE8),
    );
  }

  return null;
}

List<String> _generateEarnedBadges({
  required String languageId,
  required List<int> completedLevels,
}) {
  final completedSet = completedLevels.toSet();
  final completedCount = completedSet.length;

  final badges = <String>[];

  final hasCompletedLevel5 = completedSet.contains(5) || completedCount >= 5;
  final hasCompletedLevel15 = completedSet.contains(15) || completedCount >= 15;
  final hasCompletedLevel30 = completedSet.contains(30) || completedCount >= 30;

  if (hasCompletedLevel5) {
    badges.add('${languageId}_level_5');
  }

  if (hasCompletedLevel15) {
    badges.add('${languageId}_level_15');
  }

  if (hasCompletedLevel30) {
    badges.add('${languageId}_level_30');
  }

  return badges;
}

Map<String, bool> _readNotificationSettings(dynamic value) {
  final defaultSettings = {
    'studyReminder': true,
    'streakReminder': true,
    'heartReminder': true,
    'badgeNotification': true,
  };

  if (value is! Map) {
    return defaultSettings;
  }

  return {
    'studyReminder': value['studyReminder'] == true,
    'streakReminder': value['streakReminder'] == true,
    'heartReminder': value['heartReminder'] == true,
    'badgeNotification': value['badgeNotification'] == true,
  };
}

List<String> _readStringList(dynamic value) {
  if (value is! List) return [];

  return value
      .map((item) => item.toString())
      .where((item) => item.trim().isNotEmpty)
      .toSet()
      .toList();
}

String _normalizeLanguageId(String? value) {
  final raw = (value ?? '').trim().toLowerCase();

  if (raw.contains('jawa')) return 'jawa';
  if (raw.contains('batak') || raw.contains('toba')) return 'batak_toba';
  if (raw.contains('sunda')) return 'sunda';

  return 'sunda';
}

String _languageNameFromId(String languageId) {
  if (languageId == 'jawa') return 'Bahasa Jawa';
  if (languageId == 'bali') return 'Bahasa Bali';
  if (languageId == 'batak_toba') return 'Bahasa Batak Toba';

  return 'Bahasa Sunda';
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

List<int> _readIntList(dynamic value) {
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
String _languageShortNameFromId(String languageId) {
  if (languageId == 'jawa') return 'Jawa';
  if (languageId == 'bali') return 'Bali';
  if (languageId == 'madura') return 'Madura';

  return 'Sunda';
}