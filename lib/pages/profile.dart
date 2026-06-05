import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'streak.dart';
import 'peta.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController nameController;
  late TextEditingController birthController;
  late TextEditingController emailController;
  late TextEditingController passwordController;

  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    nameController = TextEditingController(
      text: (user?.displayName != null && user!.displayName!.isNotEmpty)
          ? user.displayName!
          : 'Bubi',
    );
    birthController = TextEditingController(text: '00/00/0000');
    emailController =
        TextEditingController(text: user?.email ?? 'dummy@gmail.com');
    passwordController = TextEditingController(text: '••••••••••••');
  }

  @override
  void dispose() {
    nameController.dispose();
    birthController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _openDrawerSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return const _ProfileDrawerSheet();
    },
  );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : 'Bubi';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      bottomNavigationBar: const _LokaBottomNav(currentIndex: 3),
      body: SafeArea(
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomePage(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFFAAA6AD),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _openDrawerSheet,
                      icon: const Icon(
                        Icons.menu_rounded,
                        size: 28,
                        color: Color(0xFF4E4E4E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Color(0xFFD9D9D9),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Profil',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 6,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4E1F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 26),

                _FieldLabel(label: 'Nama'),
                _ProfileField(controller: nameController),

                const SizedBox(height: 16),
                _FieldLabel(label: 'Tanggal Lahir'),
                _ProfileField(controller: birthController),

                const SizedBox(height: 16),
                _FieldLabel(label: 'Email'),
                _ProfileField(controller: emailController),

                const SizedBox(height: 16),
                _FieldLabel(label: 'Sandi'),
                _ProfileField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF2E2B4A),
                    ),
                  ),
                ),

                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTapDown: (_) {},
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Hapus akun'),
                            content: const Text(
                              'Untuk sekarang tombol ini masih dummy dulu ya.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7154),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        shadowColor: const Color(0xFFF5A18E),
                      ),
                      child: const Text(
                        'HAPUS AKUN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
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

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 14, bottom: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8787A0),
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffix;

  const _ProfileField({
    required this.controller,
    this.obscureText = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Color(0xFF2E2B4A),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFD8D8E5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFD8D8E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color(0xFFBFCBE5),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ProfileDrawerSheet extends StatelessWidget {
  const _ProfileDrawerSheet();

  @override
  Widget build(BuildContext context) {
    final menus = [
      'Profil',
      'Notifikasi',
      'Bahasa',
      'Pengaturan Privasi',
      'Pusat Bantuan',
      'Saran',
      'Badge',
    ];

    final double sheetHeight = MediaQuery.of(context).size.height * 0.84;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F4F4),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(34),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(34),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      const Text(
                        'Lainnya',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFD7E3F8),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.black,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ...menus.map(
                    (menu) => InkWell(
                      onTap: () {
                        Navigator.pop(context);

                        if (menu == 'Bahasa') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const _SimpleMenuPage(
                                title: 'Bahasa',
                                items: [
                                  'Bahasa Sunda',
                                  'Bahasa Batak',
                                  'Bahasa Jawa',
                                  'Bahasa Bali',
                                ],
                              ),
                            ),
                          );
                        } else if (menu == 'Pengaturan Privasi') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const _SimpleMenuPage(
                                title: 'Pengaturan Privasi',
                                items: [
                                  'Privasi Akun',
                                  'Keamanan',
                                  'Izin Aplikasi',
                                  'Data & Aktivitas',
                                ],
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _PlaceholderPage(title: menu),
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              menu,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4E1F5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFD6DEE8),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Badge',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF999999),
                          ),
                        ),
                        SizedBox(height: 18),
                        Wrap(
                          spacing: 22,
                          runSpacing: 22,
                          children: [
                            Icon(Icons.emoji_events_rounded,
                                size: 52, color: Color(0xFFF0A615)),
                            Icon(Icons.emoji_events_rounded,
                                size: 52, color: Color(0xFFF0A615)),
                            Icon(Icons.emoji_events_rounded,
                                size: 52, color: Color(0xFFF0A615)),
                            Icon(Icons.gps_fixed_rounded,
                                size: 52, color: Color(0xFFE9B347)),
                            Icon(Icons.bolt_rounded,
                                size: 52, color: Color(0xFFF5D000)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: 90,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromRGBO(244, 244, 244, 0),
                        Color.fromRGBO(244, 244, 244, 0.92),
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
    );
  }
}

class _SimpleMenuPage extends StatelessWidget {
  final String title;
  final List<String> items;

  const _SimpleMenuPage({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      bottomNavigationBar: const _LokaBottomNav(currentIndex: 3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFFAAA6AD),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                height: 6,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4E1F5),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 24),
              ...items.map(
                (item) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 22,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFD8D8E5)),
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2E2B4A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7154),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text(
                    'HAPUS PROGRESS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      bottomNavigationBar: const _LokaBottomNav(currentIndex: 3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4E4E4E)),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF4E4E4E),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFD9D4D6),
              width: 2,
            ),
          ),
          child: Text(
            '$title\nmasih dalam pengerjaan',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4E4E4E),
            ),
          ),
        ),
      ),
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
                  page = const ProfilePage();
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