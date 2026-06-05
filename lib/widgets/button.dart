import 'package:flutter/material.dart';

class Button extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final Color buttonColor;
  final Color shadowColor;
  final Color textColor;
  final bool outlined;
  final double height;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;
  final double shadowOffset;
  final Widget? leading;

  const Button({
    super.key,
    required this.text,
    required this.onTap,
    this.buttonColor = const Color(0xFF0F9D6C),
    this.shadowColor = const Color(0xFF6CC1A8),
    this.textColor = Colors.white,
    this.outlined = false,
    this.height = 58,
    this.borderRadius = 20,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w700,
    this.shadowOffset = 8,
    this.leading,
  });

  @override
  State<Button> createState() => _LokagoButtonState();
}

class _LokagoButtonState extends State<Button> {
  bool _isPressed = false;
  bool _isHovered = false;

  Color _lighten(Color color, [double amount = 0.08]) {
    final hsl = HSLColor.fromColor(color);
    final lighter = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return lighter.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final bool isInteractiveHighlight = _isHovered && !_isPressed;

    final Color topColor = widget.outlined
        ? (isInteractiveHighlight
            ? _lighten(const Color(0xFFF4EFEF), 0.02)
            : const Color(0xFFF4EFEF))
        : (isInteractiveHighlight
            ? _lighten(widget.buttonColor, 0.06)
            : widget.buttonColor);

    final double topOffset = _isPressed ? widget.shadowOffset : 0;
    final double visibleShadowHeight = _isPressed ? 0 : widget.shadowOffset;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _isPressed = true;
          });
        },
        onTapUp: (_) {
          setState(() {
            _isPressed = false;
          });
        },
        onTapCancel: () {
          setState(() {
            _isPressed = false;
          });
        },
        onTap: widget.onTap,
        child: SizedBox(
          height: widget.height + widget.shadowOffset,
          width: double.infinity,
          child: Stack(
            children: [
              if (!widget.outlined)
                Positioned(
                  left: 0,
                  right: 0,
                  top: widget.shadowOffset,
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: widget.shadowColor,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                    ),
                  ),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                top: topOffset,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: topColor,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: widget.outlined
                        ? Border.all(
                            color: const Color(0xFFD9D4D6),
                            width: 2,
                          )
                        : null,
                    boxShadow: widget.outlined
                        ? [
                            if (!_isPressed)
                              BoxShadow(
                                color: const Color(0xFFD9D4D6),
                                offset: Offset(0, visibleShadowHeight),
                                blurRadius: 0,
                              ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.leading != null) ...[
                          widget.leading!,
                          const SizedBox(width: 10),
                        ],
                        Text(
                          widget.text,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: widget.textColor,
                          ),
                        ),
                      ],
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