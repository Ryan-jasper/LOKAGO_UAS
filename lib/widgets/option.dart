import 'package:flutter/material.dart';

class Option extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const Option({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color selectedBg = Color(0xFFAED8CB);
    const Color selectedBorder = Color(0xFF64BFA4);
    const Color selectedText = Color(0xFF089169);

    const Color unselectedBg = Color(0xFFF7F3F4);
    const Color unselectedBorder = Color(0xFFD9D4D6);
    const Color unselectedText = Color(0xFFE2775B);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 86,
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedBorder : unselectedBorder,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? selectedBorder : unselectedBorder,
              offset: const Offset(0, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isSelected ? selectedText : unselectedText,
            ),
          ),
        ),
      ),
    );
  }
}