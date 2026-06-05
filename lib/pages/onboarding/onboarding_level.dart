import 'package:flutter/material.dart';
import '../../widgets/option.dart';
import '../../widgets/progressbar.dart';
import 'onboarding_profile.dart';

class OnboardingLevelPage extends StatefulWidget {
  final String selectedLanguage;

  const OnboardingLevelPage({
    super.key,
    required this.selectedLanguage,
  });

  @override
  State<OnboardingLevelPage> createState() => _OnboardingLevelPageState();
}

class _OnboardingLevelPageState extends State<OnboardingLevelPage> {
  String? selectedLevel;

  final List<String> levels = [
    'Baru mulai belajar',
    'Tahu beberapa kata',
    'Bisa percakapan sederhana',
    'Sudah cukup lancar',
  ];

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedLevel != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 160,
              left: -80,
              child: Image.asset(
                'assets/images/batik.png',
                width: 160,
              ),
            ),
            Positioned(
              top: 40,
              right: -80,
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

                  Progressbar(
                    progress: 0.50,
                    onBack: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 26),

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
                            'Seberapa kamu\nmenguasai ${widget.selectedLanguage}?',
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

                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Image.asset(
                        'assets/images/onboarding/level.png',
                        width: 140,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: Stack(
                      children: [
                        ListView.builder(
                          padding: const EdgeInsets.only(
                            top: 20,
                            bottom: 24,
                          ),
                          itemCount: levels.length,
                          itemBuilder: (context, index) {
                            final level = levels[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Option(
                                title: level,
                                isSelected: selectedLevel == level,
                                onTap: () {
                                  setState(() {
                                    selectedLevel = level;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: IgnorePointer(
                            child: Container(
                              height: 36,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFF4F4F4),
                                    Color.fromRGBO(244, 244, 244, 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            child: Container(
                              height: 40,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color.fromRGBO(244, 244, 244, 0),
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

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSelected
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OnboardingProfilePage(
                                    selectedLanguage: widget.selectedLanguage,
                                    selectedLevel: selectedLevel!,
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? const Color(0xFF0F9D6C)
                            : const Color(0xFFD9D9D9),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD9D9D9),
                        disabledForegroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(60),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'LANJUT',
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