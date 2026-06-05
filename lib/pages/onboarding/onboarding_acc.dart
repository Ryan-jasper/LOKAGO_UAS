import 'package:flutter/material.dart';
import '../home.dart';

class OnboardingDonePage extends StatelessWidget {
  final String name;
  final String selectedLanguage;
  final String selectedLevel;

  const OnboardingDonePage({
    super.key,
    required this.name,
    required this.selectedLanguage,
    required this.selectedLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 160,
              right: -80,
              child: Image.asset(
                'assets/images/batik.png',
                width: 160,
              ),
            ),
            Positioned(
              top: 40,
              left: -80,
              child: Image.asset(
                'assets/images/batik.png',
                width: 160,
              ),
            ),
            Positioned(
              bottom: 220,
              left: -80,
              child: Image.asset(
                'assets/images/batik.png',
                width: 160,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFFB5B5B5),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: const LinearProgressIndicator(
                            value: 1.0,
                            minHeight: 18,
                            backgroundColor: Color(0xFFD9D7DB),
                            valueColor: AlwaysStoppedAnimation(
                              Color(0xFF70C4AD),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 160),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 260,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFD9D4D6),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFD9D4D6),
                                offset: Offset(0, 6),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            'Yey, $name!\nKamu sudah siap\nmulai petualangan\nbahasa daerah!',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4E4E4E),
                              height: 1.35,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -10,
                          right: 16,
                          child: Transform.rotate(
                            angle: 0.8,
                            child: Container(
                              width: 22,
                              height: 22,
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
                    ),
                  ),

                  const SizedBox(height: 24),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Image.asset(
                        'assets/images/onboarding/level.png',
                        width: 150,
                      ),
                    ),
                  ),

                  const Spacer(),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFD9D4D6),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan pilihanmu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color:const Color(0xFF4E4E4E).withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Bahasa: $selectedLanguage',
                          style: TextStyle(
                            fontSize: 14,
                            color:const Color(0xFF6B6B6B).withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Level: $selectedLevel',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF6B6B6B).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomePage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F9D6C),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(60),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'MULAI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}