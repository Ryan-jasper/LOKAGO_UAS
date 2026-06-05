import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../widgets/progressbar.dart';
import 'onboarding_acc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';

class OnboardingProfilePage extends StatefulWidget {
  final String selectedLanguage;
  final String selectedLevel;

  const OnboardingProfilePage({
    super.key,
    required this.selectedLanguage,
    required this.selectedLevel,
  });

  @override
  State<OnboardingProfilePage> createState() => _OnboardingProfilePageState();
}

class _OnboardingProfilePageState extends State<OnboardingProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController birthController = TextEditingController();
  final uid = FirebaseAuth.instance.currentUser!.uid;

  DateTime? selectedBirthDate;

  @override
  void dispose() {
    nameController.dispose();
    birthController.dispose();
    super.dispose();
  }

  bool get isFilled =>
      nameController.text.trim().isNotEmpty &&
      birthController.text.trim().isNotEmpty;

  void openBirthDatePicker() {
    DateTime tempDate = selectedBirthDate ?? DateTime(2005, 1, 1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                          selectedBirthDate = tempDate;
                          birthController.text =
                              '${tempDate.day.toString().padLeft(2, '0')}/'
                              '${tempDate.month.toString().padLeft(2, '0')}/'
                              '${tempDate.year}';
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Pilih',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F9D6C),
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

  Widget buildInputField({
    required String hintText,
    required TextEditingController controller,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFD9D4D6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFD9D4D6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF0F9D6C),
            width: 2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
            Positioned(
              bottom: 160,
              right: -80,
              child: Image.asset(
                'assets/images/batik.png',
                width: 160,
              ),
            ),
            Positioned(
              bottom: 80,
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

                  /// HEADER TETAP
                  Progressbar(
                    progress: 0.75,
                    onBack: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 26),

                  /// BUBBLE CHAT
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
                            'Oh iya, kami belum\nberkenalan.\nSiapa nama kamu?',
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

                  /// MASKOT TETAP
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Image.asset(
                        'assets/images/onboarding/akun.png',
                        width: 140,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// FORM YANG BISA SCROLL
                  Expanded(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 100,
                          ),
                          child: Column(
                            children: [
                              buildInputField(
                                hintText: 'Nama',
                                controller: nameController,
                              ),
                              const SizedBox(height: 18),
                              buildInputField(
                                hintText: 'Tanggal lahir',
                                controller: birthController,
                                readOnly: true,
                                onTap: openBirthDatePicker,
                                suffixIcon: const Icon(
                                  Icons.calendar_today_rounded,
                                  color: Color(0xFF7E7E99),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),

                        /// FADE ATAS
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: IgnorePointer(
                            child: Container(
                              height: 28,
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

                        /// FADE BAWAH
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            child: Container(
                              height: 36,
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
                ],
              ),
            ),

            /// TOMBOL TETAP DI BAWAH
            Positioned(
              left: 28,
              right: 28,
              bottom: 18,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isFilled
                    ? () async {
                        try {
                          final uid = FirebaseAuth.instance.currentUser!.uid;

                          await UserService().saveOnboarding(
                            uid: uid,
                            name: nameController.text.trim(),
                            birthDate: birthController.text.trim(),
                            selectedLanguage: widget.selectedLanguage,
                            selectedLevel: widget.selectedLevel,
                          );

                          if (!context.mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OnboardingDonePage(
                                name: nameController.text.trim(),
                                selectedLanguage: widget.selectedLanguage,
                                selectedLevel: widget.selectedLevel,
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal simpan data: $e')),
                          );
                        }
                      }
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFilled
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
            ),
          ],
        ),
      ),
    );
  }
}