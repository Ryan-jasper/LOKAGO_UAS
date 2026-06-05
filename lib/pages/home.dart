import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'streak.dart';
import 'peta.dart';
import 'profile.dart';

enum PathNodeType { star, level, test }
enum PathNodeStatus { completed, current, locked }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    super.dispose();
  }

  void _openComingSoon(String title) {
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
    const gold = Color(0xFFF4B11A);

    final user = FirebaseAuth.instance.currentUser;
    final userName = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : 'Bubi';

    final int hearts = 15;
    final int streak = 4;

    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: const _LokaBottomNav(currentIndex: 0),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFFD9D9D9),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '$hearts',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD6372A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.favorite_border_rounded,
                            color: Color(0xFFD6372A),
                            size: 34,
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          Text(
                            '$streak',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: gold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.local_fire_department_outlined,
                            color: gold,
                            size: 34,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _TopContinueCard(
                    onTap: () => _openComingSoon('Lanjut Belajar'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;

                  const startY = 70.0;
                  const gapY = 108.0;

                  final xPattern = <double>[
                    0.50,
                    0.54,
                    0.49,
                    0.53,
                    0.48,
                    0.52,
                    0.49,
                    0.53,
                    0.50,
                  ];

                  final points = List.generate(nodes.length, (i) {
                    return Offset(
                      w * xPattern[i],
                      startY + (i * gapY),
                    );
                  });

                  final canvasHeight =
                      startY + ((nodes.length - 1) * gapY) + 170;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: SizedBox(
                      height: canvasHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _LearningPathPainter(points: points),
                            ),
                          ),
                          Positioned(
                            left: math.max(8, points[2].dx - 118),
                            top: points[2].dy + 18,
                            child: Column(
                              children: [
                                const _SpeechBubble(
                                  text: 'Semangat!',
                                  width: 120,
                                ),
                                const SizedBox(height: 12),
                                Image.asset(
                                  'assets/images/signup/loka.png',
                                  width: 88,
                                  errorBuilder: (_, __, ___) {
                                    return const Icon(
                                      Icons.smart_toy_rounded,
                                      size: 82,
                                      color: Color(0xFFE2775B),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          ...List.generate(nodes.length, (index) {
                            final point = points[index];
                            final node = nodes[index];

                            final bool isCurrent =
                                node.status == PathNodeStatus.current;
                            final bool isSpecial =
                                node.type == PathNodeType.star ||
                                    node.type == PathNodeType.test;

                            final double outerSize =
                                isCurrent ? 100 : (isSpecial ? 88 : 84);

                            final double wrapperWidth =
                                index == 0 ? 112 : outerSize;
                            final double wrapperHeight =
                                index == 0 ? 132 : outerSize + 12;

                            return Positioned(
                              left: point.dx - (wrapperWidth / 2),
                              top: point.dy - (wrapperHeight / 2),
                              child: _AnimatedNodeWrapper(
                                showBubble: index == 0,
                                controller: _bubbleController,
                                child: _PathNodeButton(
                                  data: node,
                                  onTap: () {
                                    final title = node.type == PathNodeType.level
                                        ? 'Level ${node.label}'
                                        : node.type == PathNodeType.test
                                            ? 'Test ${node.label}'
                                            : 'Start';
                                    _openComingSoon(title);
                                  },
                                ),
                              ),
                            );
                          }),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              child: Container(
                                height: 160,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color.fromRGBO(217, 240, 234, 0),
                                      Color.fromRGBO(217, 240, 234, 0.80),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopContinueCard extends StatelessWidget {
  const _TopContinueCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
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
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coming Soon',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Bahasa Sunda:\nPerkenalan',
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: 0.65,
                        strokeWidth: 7,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    const Text(
                      '65%',
                      style: TextStyle(
                        fontSize: 14,
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
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF2DFD8),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFFE2775B),
                    size: 28,
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
    if (!showBubble) return child;

    return SizedBox(
      width: 112,
      height: 132,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, bubble) {
              final offsetY = -2 + (controller.value * 10);
              return Positioned(
                top: offsetY,
                child: bubble!,
              );
            },
            child: const _FloatingBubble(text: 'START'),
          ),
          Positioned(
            top: 40,
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

    final double size = isCurrent ? 88 : (isSpecial ? 80 : 76);
    final double outerSize = isCurrent ? 100 : (isSpecial ? 88 : 84);
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
                    width: 3.4,
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
                    width: 3.4,
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
      return Icon(
        Icons.star_rounded,
        size: 30,
        color: widget.data.status == PathNodeStatus.locked
            ? const Color(0xFFB9B9B9)
            : Colors.white,
      );
    }

    if (widget.data.type == PathNodeType.test) {
      return Icon(
        Icons.workspace_premium_rounded,
        size: 28,
        color: widget.data.status == PathNodeStatus.locked
            ? const Color(0xFFB9B9B9)
            : Colors.white,
      );
    }

    return Text(
      widget.data.label,
      style: TextStyle(
        fontSize: widget.data.status == PathNodeStatus.current ? 28 : 25,
        fontWeight: FontWeight.w900,
        color: widget.data.status == PathNodeStatus.locked
            ? const Color(0xFFB9B9B9)
            : Colors.white,
      ),
    );
  }

  _NodeColors _resolveColors() {
    if (widget.data.status == PathNodeStatus.completed) {
      if (widget.data.type == PathNodeType.test ||
          widget.data.type == PathNodeType.star) {
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD9D4D6),
              width: 2,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4E4E4E),
            ),
          ),
        ),
        Positioned(
          left: 16,
          bottom: -10,
          child: Transform.rotate(
            angle: 0.78,
            child: Container(
              width: 18,
              height: 18,
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
    );
  }
}

class _LearningPathPainter extends CustomPainter {
  final List<Offset> points;

  const _LearningPathPainter({
    required this.points,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFFD9D9D9)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlY = (previous.dy + current.dy) / 2;

      path.cubicTo(
        previous.dx,
        controlY,
        current.dx,
        controlY,
        current.dx,
        current.dy,
      );
    }

    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant _LearningPathPainter oldDelegate) => false;
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
        border: Border(
          top: BorderSide(color: Color(0xFFE3E3E3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final active = index == currentIndex;
          final color = active
              ? const Color(0xFF69C3A8)
              : const Color(0xFF93A2B8);

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
                  page = const HomePage();
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