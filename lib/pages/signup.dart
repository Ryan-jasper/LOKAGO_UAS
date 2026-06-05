import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'onboarding/onboarding_language.dart';
import '../widgets/button.dart';
import '../services/auth_service.dart';
import 'forget_pass.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;

  static const Color bgColor = Color(0xFFF4F4F4);
  static const Color labelColor = Color(0xFF7E7E99);
  static const Color darkText = Color(0xFF232248);
  static const Color greenMain = Color(0xFF0F9D6C);
  static const Color greenShadow = Color(0xFF6CC1A8);
  static const Color borderColor = Color(0xFFBFC2E2);
  static const Color inputTextColor = Color(0xFF232248);
  static const Color mutedText = Color(0xFF9A9A9A);
  static const Color coralText = Color(0xFFE2775B);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleSignUp() async {
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email dan sandi wajib diisi')),
        );
        return;
      }

      await AuthService().signUpWithEmail(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingLanguagePage(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        try {
          await AuthService().signInWithEmail(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const OnboardingLanguagePage(),
            ),
          );
          return;
        } catch (_) {}
      }

      String message = 'Gagal mendaftar';

      if (e.code == 'email-already-in-use') {
        message = 'Email sudah terdaftar';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid';
      } else if (e.code == 'weak-password') {
        message = 'Password terlalu lemah';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi error: $e')),
      );
    }
  }
  Future<void> handleGoogleSignUp() async {
    try {
      await AuthService().signInWithGoogle();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingLanguagePage(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google login gagal: $e')),
      );
    }
  }

  Widget buildTextField({
    required String labelText,
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: inputTextColor,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
          floatingLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: greenMain,
          ),
          filled: true,
          fillColor: const Color(0xFFF8F8F8),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 22,
          ),
          suffixIcon: suffixIcon,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: greenMain,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

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
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 250,
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
                          child: const Text(
                            'Ayuk daftarkan email\nmu, agar progress mu\ntersimpan!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4E4E4E),
                              height: 1.35,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -10,
                          right: 18,
                          child: Transform.rotate(
                            angle: 0.8,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  right: BorderSide(
                                    color: Color(0xFFD9D4D6),
                                    width: 2,
                                  ),
                                  bottom: BorderSide(
                                    color: Color(0xFFD9D4D6),
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Image.asset(
                        'assets/images/signup/loka.png',
                        width: 140,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  buildTextField(
                    labelText: 'Email',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 18),
                  buildTextField(
                    labelText: 'Sandi',
                    controller: passwordController,
                    obscure: obscurePassword,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: darkText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgetPasswordPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Lupa Kata Sandi?',
                        style: TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                          color: Color(0xFF9A9A9A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Button(
                    text: 'DAFTAR',
                    onTap: handleSignUp,
                    buttonColor: greenMain,
                    shadowColor: greenShadow,
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'Atau',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: mutedText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: SizedBox(
                      width: 220,
                      child: Button(
                        text: 'Google',
                        onTap: handleGoogleSignUp,
                        outlined: true,
                        buttonColor: const Color(0xFFF4EFEF),
                        shadowColor: const Color(0xFFD9D4D6),
                        textColor: coralText,
                        leading: Image.asset(
                          'assets/images/login/google.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}