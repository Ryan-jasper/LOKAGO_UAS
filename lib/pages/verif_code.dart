import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'new_pass.dart';

class VerificationCodePage extends StatefulWidget {
  final String email;

  const VerificationCodePage({
    super.key,
    required this.email,
  });

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  final TextEditingController codeController = TextEditingController();

  static const Color bgColor = Color(0xFFF4F4F4);
  static const Color labelColor = Color(0xFF7E7E99);
  static const Color darkText = Color(0xFF232248);
  static const Color greenMain = Color(0xFF0F9D6C);
  static const Color borderColor = Color(0xFFBFC2E2);
  static const Color inputTextColor = Color(0xFF232248);

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> handleVerifyCode() async {
    try {
      final code = codeController.text.trim();

      if (code.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode verifikasi wajib diisi')),
        );
        return;
      }

      await AuthService().verifyResetCode(code: code);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewPasswordPage(resetCode: code),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kode verifikasi tidak valid: $e')),
      );
    }
  }

  Widget buildTextField({
    required String labelText,
    required TextEditingController controller,
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
                            'Masukkan kode dari link\nreset yang dikirim ke\n${widget.email}',
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
                        'assets/images/onboarding/bahasa.png',
                        width: 140,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  buildTextField(
                    labelText: 'Verification Code',
                    controller: codeController,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: handleVerifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: greenMain,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(56),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'VERIFIKASI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}