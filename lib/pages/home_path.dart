import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum PathNodeType { star, level, test }

enum PathNodeStatus { completed, current, locked }

class HomePathPage extends StatefulWidget {
  const HomePathPage({super.key});

  @override
  State<HomePathPage> createState() => _HomePathPageState();
}

class _HomePathPageState extends State<HomePathPage>
    with SingleTickerProviderStateMixin {
  String userName = 'User';
  bool isLoadingUser = true;

  late final AnimationController _bubbleController;

  final List<_PathNodeData> nodes = const [
    _PathNodeData(
      type: PathNodeType.star,
      label: 'START',
      status: PathNodeStatus.completed,
    ),
    _PathNodeData(
      type: PathNodeType.level,
      label: '1',
      status: PathNodeStatus.completed,
    ),
    _PathNodeData(
      type: PathNodeType.level,
      label: '2',
      status: PathNodeStatus.completed,
    ),
    _PathNodeData(
      type: PathNodeType.level,
      label: '3',
      status: PathNodeStatus.current,
    ),
    _PathNodeData(
      type: PathNodeType.level,
      label: '4',
      status: PathNodeStatus.locked,
    ),
    _PathNodeData(
      type: PathNodeType.test,
      label: '5',
      status: PathNodeStatus.locked,
    ),
    _PathNodeData(
      type: PathNodeType.level,
      label: '6',
      status: PathNodeStatus.locked,
    ),
    _PathNodeData(
      type: PathNodeType.level,
      label: '7',
      status: PathNodeStatus.locked,
    ),
    _PathNodeData(
      type: PathNodeType.level,
      label: '8',
      status: PathNodeStatus.locked,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    loadUserName();
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    super.dispose();
  }

  Future<void> loadUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          userName = 'Guest';
          isLoadingUser = false;
        });
        return;
      }

      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        setState(() {
          userName = user.displayName!;
          isLoadingUser = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      setState(() {
        userName = data?['name']?.toString().trim().isNotEmpty == true
            ? data!['name']
            : 'User';
        isLoadingUser = false;
      });
    } catch (_) {
      setState(() {
        userName = 'User';
        isLoadingUser = false;
      });
    }
  }

  void openComingSoon(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnderConstructionPage(title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF4F4F4);

    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) openComingSoon('Streak');
          if (index == 2) openComingSoon('Peta');
          if (index == 3) openComingSoon('Profil');
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFFD9D9D9),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: isLoadingUser
                            ? const Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
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
                              color: Color(0xFFD8372A),
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.favorite_border_rounded,
                            color: Color(0xFFD8372A),
                            size: 30,
                          ),
                        ],
                      ),
                      SizedBox(width: 22),
                      Row(
                        children: const [
                          Text(
                            '4',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF1A61D),
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFFF9F1C),
                            size: 30,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _TopCard(
                    onTap: () => openComingSoon('Lanjut Belajar'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
                    child: Column(
                      children: [
                        for (int i = 0; i < nodes.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              top: i == 0 ? 8 : 24,
                              left: i.isEven ? 0 : 90,
                              right: i.isEven ? 90 : 0,
                            ),
                            child: Align(
                              alignment: i.isEven
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: _AnimatedNodeWrapper(
                                showBubble: i == 0,
                                controller: _bubbleController,
                                child: _PathNodeButton(
                                  data: nodes[i],
                                  onTap: () {
                                    final title = nodes[i].type == PathNodeType.level
                                        ? 'Level ${nodes[i].label}'
                                        : nodes[i].type == PathNodeType.test
                                            ? 'Test ${nodes[i].label}'
                                            : 'Start';
                                    openComingSoon(title);
                                  },
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 140,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.fromRGBO(217, 240, 234, 0.0),
                              Color.fromRGBO(217, 240, 234, 0.75),
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
    );
  }
}

class _TopCard extends StatelessWidget {
  const _TopCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE2775B),
            Color(0xFFE38A75),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coming Soon',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Bahasa Sunda:\nPerkenalan',
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 68,
                      height: 68,
                      child: CircularProgressIndicator(
                        value: 0.65,
                        strokeWidth: 8,
                        backgroundColor: Color(0xFFF0A997),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Text(
                      '65%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF2DDD8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFFE2775B),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Buka Nanti',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE2775B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedNodeWrapper extends StatelessWidget {
  const _AnimatedNodeWrapper({
    required this.showBubble,
    required this.controller,
    required this.child,
  });

  final bool showBubble;
  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!showBubble) {
      return child;
    }

    return SizedBox(
      width: 110,
      height: 130,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, bubble) {
              final offsetY = -2 + (controller.value * 10);
              return Positioned(
                top: 0 + offsetY,
                child: bubble!,
              );
            },
            child: const _FloatingBubble(text: 'START'),
          ),
          Positioned(
            top: 38,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _PathNodeButton extends StatefulWidget {
  const _PathNodeButton({
    required this.data,
    required this.onTap,
  });

  final _PathNodeData data;
  final VoidCallback onTap;

  @override
  State<_PathNodeButton> createState() => _PathNodeButtonState();
}

class _PathNodeButtonState extends State<_PathNodeButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors();
    final isCurrent = widget.data.status == PathNodeStatus.current;
    final isSpecial =
        widget.data.type == PathNodeType.star ||
        widget.data.type == PathNodeType.test;

    final double size = isCurrent
        ? 94
        : (isSpecial ? 84 : 80);

    final double outerSize = isCurrent
        ? 108
        : (isSpecial ? 92 : 88);

    final double faceTop = isPressed ? 9 : 0;
    const double shadowTop = 10;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          isPressed = false;
        });
        widget.onTap();
      },
      onTapCancel: () {
        setState(() {
          isPressed = false;
        });
      },
      child: SizedBox(
        width: outerSize,
        height: outerSize + 12,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: shadowTop,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.shadow,
                  border: Border.all(
                    color: Colors.white,
                    width: 3.5,
                  ),
                ),
              ),
            ),

            if (isCurrent)
              Positioned(
                top: faceTop,
                child: Container(
                  width: outerSize,
                  height: outerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD8D8D8),
                      width: 8,
                    ),
                  ),
                ),
              ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOut,
              top: faceTop,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.main,
                  border: Border.all(
                    color: Colors.white,
                    width: 3.5,
                  ),
                ),
                alignment: Alignment.center,
                child: _buildChild(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChild() {
    if (widget.data.type == PathNodeType.star) {
      return Transform.translate(
        offset: const Offset(0, -1),
        child: Icon(
          Icons.star_rounded,
          size: widget.data.status == PathNodeStatus.current ? 38 : 34,
          color: widget.data.status == PathNodeStatus.locked
              ? const Color(0xFFB9B9B9)
              : Colors.white,
        ),
      );
    }

    if (widget.data.type == PathNodeType.test) {
      return Transform.translate(
        offset: const Offset(0, -1),
        child: Icon(
          Icons.workspace_premium_rounded,
          size: widget.data.status == PathNodeStatus.current ? 36 : 32,
          color: widget.data.status == PathNodeStatus.locked
              ? const Color(0xFFB9B9B9)
              : Colors.white,
        ),
      );
    }

    return Text(
      widget.data.label,
      style: TextStyle(
        fontSize: widget.data.status == PathNodeStatus.current ? 30 : 27,
        fontWeight: FontWeight.w900,
        color: widget.data.status == PathNodeStatus.locked
            ? const Color(0xFFB9B9B9)
            : Colors.white,
      ),
    );
  }

  _NodeColors _resolveColors() {
    if (widget.data.status == PathNodeStatus.completed) {
      if (widget.data.type == PathNodeType.test) {
        return const _NodeColors(
          main: Color(0xFFF4B11A),
          shadow: Color(0xFFE09E00),
        );
      }

      if (widget.data.type == PathNodeType.star) {
        return const _NodeColors(
          main: Color(0xFFF4B11A),
          shadow: Color(0xFFE09E00),
        );
      }

      return const _NodeColors(
        main: Color(0xFF69C3A8),
        shadow: Color(0xFF0F9D6C),
      );
    }

    if (widget.data.status == PathNodeStatus.current) {
      return const _NodeColors(
        main: Color(0xFFF1B6AA),
        shadow: Color(0xFFFF7154),
      );
    }

    return const _NodeColors(
      main: Color(0xFFE1E1E1),
      shadow: Color(0xFFBEBEBE),
    );
  }
}

class _FloatingBubble extends StatelessWidget {
  const _FloatingBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1D3D25),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF62D77E),
              width: 1.3,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8DFF8D),
            ),
          ),
        ),
        Positioned(
          bottom: -4,
          left: 18,
          child: Transform.rotate(
            angle: 0.8,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF1D3D25),
                border: Border(
                  right: BorderSide(
                    color: Color(0xFF62D77E),
                    width: 1.2,
                  ),
                  bottom: BorderSide(
                    color: Color(0xFF62D77E),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E5E5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BottomItem(
              icon: Icons.home_outlined,
              label: 'Home',
              active: currentIndex == 0,
              onTap: () => onTap(0),
            ),
          ),
          Expanded(
            child: _BottomItem(
              icon: Icons.local_fire_department_outlined,
              label: 'Streak',
              active: currentIndex == 1,
              onTap: () => onTap(1),
            ),
          ),
          Expanded(
            child: _BottomItem(
              icon: Icons.map_outlined,
              label: 'Peta',
              active: currentIndex == 2,
              onTap: () => onTap(2),
            ),
          ),
          Expanded(
            child: _BottomItem(
              icon: Icons.person_outline_rounded,
              label: 'Profil',
              active: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? const Color(0xFF69C3A8)
        : const Color(0xFF95A3B8);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UnderConstructionPage extends StatelessWidget {
  const UnderConstructionPage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
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
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 54,
                color: Color(0xFFE2775B),
              ),
              SizedBox(height: 14),
              Text(
                'Dalam pengerjaan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4E4E4E),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Fitur ini sedang dibuat dulu ya.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7E7E99),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PathNodeData {
  const _PathNodeData({
    required this.type,
    required this.label,
    required this.status,
  });

  final PathNodeType type;
  final String label;
  final PathNodeStatus status;
}

class _NodeColors {
  const _NodeColors({
    required this.main,
    required this.shadow,
  });

  final Color main;
  final Color shadow;
}