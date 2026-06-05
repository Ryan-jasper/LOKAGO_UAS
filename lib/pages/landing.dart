import 'package:flutter/material.dart';
import '../widgets/button.dart';
import 'login.dart';
import 'signup.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const Color bgColor = Color(0xFFF4F4F4);
  static const Color darkText = Color(0xFF232248);
  static const Color bodyText = Color(0xFF9A9A9A);
  static const Color greenMain = Color(0xFF0F9D6C);
  static const Color greenShadow = Color(0xFF6CC1A8);
  static const Color coralText = Color(0xFFE2775B);
  static const Color lineColor = Color(0xFFF1CFC7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: -100,
              child: Image.asset(
                'assets/images/batik.png',
                width: 180,
              ),
            ),
            Positioned(
              top: 0,
              right: -100,
              child: Image.asset(
                'assets/images/batik.png',
                width: 180,
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final horizontalPadding = screenWidth * 0.08;

                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      children: [
                        const SizedBox(height: 70),
                        Center(
                          child: Image.asset(
                            'assets/images/landing/landing.png',
                            width: 250,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 36),
                        const Text(
                          'Selamat Datang!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Apakah kamu sudah punya akun Loka?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: bodyText,
                          ),
                        ),
                        const SizedBox(height: 26),
                        Button(
                          text: 'MASUK',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          buttonColor: greenMain,
                          shadowColor: greenShadow,
                          textColor: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 3,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 244, 214, 207),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        const SizedBox(height: 26),
                        const Text(
                          'Baru bergabung dengan LokaGo?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: bodyText,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Button(
                          text: 'Daftar Sekarang',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupPage(),
                              ),
                            );
                          },
                          outlined: true,
                          buttonColor: const Color(0xFFF4EFEF),
                          shadowColor: const Color(0xFFD9D4D6),
                          textColor: coralText,
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}