import 'package:flutter/material.dart';

class Progressbar extends StatelessWidget {
  final double progress;
  final VoidCallback onBack;

  const Progressbar({
    super.key,
    required this.progress,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFFB5B5B5),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 18,
              backgroundColor: const Color(0xFFD9D7DB),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF70C4AD)),
            ),
          ),
        ),
      ],
    );
  }
}