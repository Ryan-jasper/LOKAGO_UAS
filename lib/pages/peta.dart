import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'streak.dart';
import 'profile.dart';

class PetaPage extends StatefulWidget {
  const PetaPage({super.key});

  @override
  State<PetaPage> createState() => _PetaPageState();
}

class _PetaPageState extends State<PetaPage> {
  _MapPinData? selectedPin;

  final List<_MapPinData> pins = const [
    _MapPinData(
      title: 'Bahasa Batak',
      subtitle: 'Sumatera Utara',
      left: 260,
      top: 300,
    ),
    _MapPinData(
      title: 'Bahasa Sunda',
      subtitle: 'Jawa Barat',
      left: 640,
      top: 540,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : 'Bubi';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      bottomNavigationBar: const _LokaBottomNav(currentIndex: 2),
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
                  const SizedBox(width: 20),
                  Row(
                    children: const [
                      Text(
                        '4',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF0A615),
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFF0A615),
                        size: 34,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Peta Indonesia',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFF7154),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jelajahi Indonesia dan Belajar Bahasanya!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF25324B),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF4F4F4),
                      Color(0xFFF4F4F4),
                      Color(0xFFE6F5EF),
                    ],
                  ),
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: 1100,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            height: 900,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.asset(
                                    'assets/images/map.png',
                                    fit: BoxFit.contain,
                                    alignment: Alignment.topCenter,
                                    errorBuilder: (_, __, ___) {
                                      return Container(
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'Tambahkan asset:\nassets/images/map.png',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Color(0xFF7E7E99),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // mascot + bubble
                                Positioned(
                                  left: 18,
                                  bottom: 90,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const _SpeechBubble(
                                        text: 'Kamu mau belajar\nbahasa apa?',
                                        width: 180,
                                      ),
                                      const SizedBox(height: 10),
                                      Image.asset(
                                        'assets/images/signup/loka.png',
                                        width: 110,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.smart_toy_rounded,
                                          size: 100,
                                          color: Color(0xFFE2775B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Pins
                                ...pins.map((pin) {
                                  return Positioned(
                                    left: pin.left,
                                    top: pin.top,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedPin =
                                              selectedPin == pin ? null : pin;
                                        });
                                      },
                                      child: const _MapPin(),
                                    ),
                                  );
                                }),

                                // Popup
                                if (selectedPin != null)
                                  Positioned(
                                    left: math.min(selectedPin!.left + 66, 870),
                                    top: selectedPin!.top + 8,
                                    child: _PinPopup(
                                      title: selectedPin!.title,
                                      subtitle: selectedPin!.subtitle,
                                      onClose: () {
                                        setState(() {
                                          selectedPin = null;
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _MapPinData {
  final String title;
  final String subtitle;
  final double left;
  final double top;

  const _MapPinData({
    required this.title,
    required this.subtitle,
    required this.left,
    required this.top,
  });
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: const [
        Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(
            Icons.location_on_rounded,
            color: Color(0xFF0F9D6C),
            size: 58,
          ),
        ),
        Icon(
          Icons.location_on_rounded,
          color: Color(0xFF67C2A7),
          size: 58,
        ),
        Positioned(
          top: 16,
          child: CircleAvatar(
            radius: 10,
            backgroundColor: Color(0xFFF4F4F4),
          ),
        ),
      ],
    );
  }
}

class _PinPopup extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _PinPopup({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD9D4D6), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF7154),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4E4E4E),
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onClose,
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Color(0xFF7E7E99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  final double width;

  const _SpeechBubble({
    required this.text,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFD9D4D6),
              width: 2,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4E4E4E),
            ),
          ),
        ),
        Positioned(
          left: 20,
          bottom: -10,
          child: Transform.rotate(
            angle: 0.78,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFF4F4F4),
                border: Border(
                  right: BorderSide(color: Color(0xFFD9D4D6), width: 2),
                  bottom: BorderSide(color: Color(0xFFD9D4D6), width: 2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
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
                  page = const PetaPage();
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