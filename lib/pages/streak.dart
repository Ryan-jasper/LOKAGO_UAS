import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'peta.dart';
import 'profile.dart';

class StreakPage extends StatelessWidget {
  const StreakPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : 'Bubi';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      bottomNavigationBar: const _LokaBottomNav(currentIndex: 1),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFD9D9D9),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Row(
                    children: const [
                      Text(
                        '15',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD6372A),
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.favorite_border_rounded,
                        color: Color(0xFFD6372A),
                        size: 34,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF4F4F4),
                      Color(0xFFFCE9E3),
                      Color(0xFFE6F5EF),
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Column(
                    children: [
                      const Text(
                        'Ayo Bantu Loka Netas !',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFF7154),
                        ),
                      ),
                      const SizedBox(height: 34),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            '0 Hari',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF0A615),
                            ),
                          ),
                          SizedBox(width: 14),
                          Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFF0A615),
                            size: 56,
                          ),
                        ],
                      ),
                      const SizedBox(height: 34),
                      const _EggWidget(),
                      const SizedBox(height: 38),
                      const _WeekRow(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EggWidget extends StatelessWidget {
  const _EggWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      height: 390,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            child: Image.asset(
              'assets/images/batik.png',
              width: 70,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
          Positioned(
            top: 36,
            child: ClipPath(
              clipper: _EggClipper(),
              child: Container(
                width: 290,
                height: 345,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.16,
                        child: Image.asset(
                          'assets/images/batik.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                    ),
                    ...List.generate(10, (i) {
                      final positions = <Offset>[
                        const Offset(18, 210),
                        const Offset(80, 230),
                        const Offset(140, 210),
                        const Offset(200, 230),
                        const Offset(50, 280),
                        const Offset(120, 280),
                        const Offset(190, 280),
                        const Offset(95, 325),
                        const Offset(160, 325),
                        const Offset(235, 210),
                      ];
                      final p = positions[i];
                      return Positioned(
                        left: p.dx,
                        top: p.dy,
                        child: Image.asset(
                          'assets/images/batik.png',
                          width: 52,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow();

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

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map(
                (e) => SizedBox(
                  width: 42,
                  child: Text(
                    e,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: e == 'Senin' || e == 'Selasa' || e == 'Rabu'
                          ? const Color(0xFFFF7154)
                          : const Color(0xFF93A2B8),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _DayDot(
              color: Color(0xFFFF7154),
              icon: Icons.check_rounded,
            ),
            _DayDot(
              color: Color(0xFFFF7154),
              icon: Icons.check_rounded,
            ),
            _DayDot(
              color: Color(0xFFFF7154),
              icon: Icons.check_rounded,
            ),
            _CurrentDayDot(),
            _DayDot(color: Color(0xFF95A4B8)),
            _DayDot(color: Color(0xFF95A4B8)),
            _DayDot(color: Color(0xFF95A4B8)),
          ],
        ),
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  final Color color;
  final IconData? icon;

  const _DayDot({
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 23,
      backgroundColor: color,
      child: icon != null
          ? Icon(icon, color: Colors.white, size: 24)
          : null,
    );
  }
}

class _CurrentDayDot extends StatelessWidget {
  const _CurrentDayDot();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: CircleAvatar(
            radius: 23,
            backgroundColor: Color(0xFF2FA6F2),
            child: Icon(
              Icons.check_rounded,
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
            decoration: const BoxDecoration(
              color: Color(0xFF2FA6F2),
              borderRadius: BorderRadius.only(
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

class _EggClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.cubicTo(
      size.width * 0.13,
      size.height * 0.10,
      size.width * 0.02,
      size.height * 0.60,
      size.width * 0.15,
      size.height * 0.92,
    );
    path.cubicTo(
      size.width * 0.22,
      size.height * 1.03,
      size.width * 0.78,
      size.height * 1.03,
      size.width * 0.85,
      size.height * 0.92,
    );
    path.cubicTo(
      size.width * 0.98,
      size.height * 0.60,
      size.width * 0.87,
      size.height * 0.10,
      size.width / 2,
      0,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _LokaBottomNav extends StatelessWidget {
  final int currentIndex;
  const _LokaBottomNav({required this.currentIndex});

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
        border: Border(top: BorderSide(color: Color(0xFFE3E3E3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final active = index == currentIndex;
          final color =
              active ? const Color(0xFF69C3A8) : const Color(0xFF93A2B8);

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
  final String label;
  final IconData icon;

  _NavItemData(this.label, this.icon);
}